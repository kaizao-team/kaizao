import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forge2d/forge2d.dart' as f2d;

import '../../app/theme/app_colors.dart';
import 'app_skill_registry.dart';

class SkillParticleItem {
  final String id;
  final String name;
  final String category;
  final bool isPrimary;

  const SkillParticleItem({
    required this.id,
    required this.name,
    this.category = '',
    this.isPrimary = false,
  });

  factory SkillParticleItem.resolve(
    String raw, {
    String? category,
    bool isPrimary = false,
  }) {
    final definition = AppSkillRegistry.resolve(raw, category: category);
    return SkillParticleItem(
      id: definition.id,
      name: definition.label,
      category: definition.category,
      isPrimary: isPrimary,
    );
  }
}

class SkillParticleField extends StatefulWidget {
  final List<SkillParticleItem> skills;

  const SkillParticleField({
    super.key,
    required this.skills,
  });

  @override
  State<SkillParticleField> createState() => _SkillParticleFieldState();
}

class _SkillParticleFieldState extends State<SkillParticleField>
    with SingleTickerProviderStateMixin {
  static const double _worldScale = 30;
  static const double _settleTimeLimit = 10.0;
  static const double _wallHalfWidthWorld = 0.04;
  static const double _floorHalfHeightWorld = 0.11;
  static const double _spawnClearanceWorld = 0.02;

  late final Ticker _ticker;
  f2d.World? _world;
  Size _fieldSize = Size.zero;
  Duration? _lastElapsed;
  double _elapsedSeconds = 0;
  double _restingSeconds = 0;
  bool _reduceMotion = false;

  List<_SkillBottleParticle> _particles = const [];
  Map<String, PictureInfo> _skillPictures = const {};
  int _pictureLoadVersion = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tickWorld);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextReduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion != nextReduceMotion) {
      _reduceMotion = nextReduceMotion;
      _scheduleWorldReset();
    }
    _primeSkillPictures();
  }

  @override
  void didUpdateWidget(covariant SkillParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_skillsSignature(oldWidget.skills) != _skillsSignature(widget.skills)) {
      _primeSkillPictures();
      _scheduleWorldReset();
    }
  }

  @override
  void dispose() {
    _pictureLoadVersion++;
    _disposeSkillPictures(_skillPictures.values);
    _ticker.dispose();
    super.dispose();
  }

  void _disposeSkillPictures(Iterable<PictureInfo> pictures) {
    for (final picture in pictures) {
      picture.picture.dispose();
    }
  }

  static AppSkillDefinition _definitionOf(SkillParticleItem skill) {
    return AppSkillRegistry.resolve(skill.name, category: skill.category);
  }

  static String _displayLabelOf(SkillParticleItem skill) {
    return _definitionOf(skill).shortLabel;
  }

  Future<void> _primeSkillPictures() async {
    final neededDefinitions = <String, AppSkillDefinition>{};
    for (final skill in widget.skills) {
      final definition = _definitionOf(skill);
      if (definition.assetPath != null) {
        neededDefinitions[definition.id] = definition;
      }
    }

    final nextPictures = <String, PictureInfo>{};
    for (final entry in _skillPictures.entries) {
      if (neededDefinitions.containsKey(entry.key)) {
        nextPictures[entry.key] = entry.value;
      } else {
        entry.value.picture.dispose();
      }
    }

    var changed = nextPictures.length != _skillPictures.length;
    final loadVersion = ++_pictureLoadVersion;

    for (final entry in neededDefinitions.entries) {
      if (nextPictures.containsKey(entry.key)) continue;
      final info = await vg.loadPicture(
        SvgAssetLoader(entry.value.assetPath!),
        context,
        clipViewbox: false,
      );
      if (!mounted || loadVersion != _pictureLoadVersion) {
        info.picture.dispose();
        return;
      }
      nextPictures[entry.key] = info;
      changed = true;
    }

    if (!mounted || loadVersion != _pictureLoadVersion || !changed) return;
    setState(() {
      _skillPictures = nextPictures;
    });
    _scheduleWorldReset();
  }

  void _scheduleWorldReset() {
    if (!mounted || _fieldSize.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _configureWorld(_fieldSize);
    });
  }

  void _configureWorld(Size size) {
    if (size.isEmpty) return;

    _ticker.stop();
    _lastElapsed = null;
    _elapsedSeconds = 0;
    _restingSeconds = 0;

    final world = f2d.World(f2d.Vector2(0, 24));
    world.setAllowSleep(false);
    final random = math.Random(_createLayoutSeed(size));

    final particles = _buildParticles(size, world, random);
    _buildBottleBounds(size, world);

    if (_reduceMotion) {
      for (final particle in particles) {
        _releaseParticle(particle, applyImpulse: false);
      }
      for (var i = 0; i < 210; i++) {
        world.stepDt(1 / 60);
      }
      for (final particle in particles) {
        particle.body.setAwake(false);
      }
    } else {
      _ticker.start();
    }

    setState(() {
      _world = world;
      _particles = particles;
    });
  }

  List<_SkillBottleParticle> _buildParticles(
    Size size,
    f2d.World world,
    math.Random random,
  ) {
    final widthInWorld = size.width / _worldScale;
    final heightInWorld = size.height / _worldScale;
    final particles = <_SkillBottleParticle>[];
    final reservedSpawns = <f2d.Vector2>[];
    final primarySkillId = widget.skills
        .cast<SkillParticleItem?>()
        .firstWhere(
          (skill) => skill?.isPrimary == true,
          orElse: () => widget.skills.isEmpty ? null : widget.skills.first,
        )
        ?.id;
    final shuffledSkills = [...widget.skills]..shuffle(random);
    final skillCount = math.max(1, shuffledSkills.length);
    final chipScale = (1 - (math.max(0, skillCount - 8) * 0.018)).clamp(
      0.78,
      1.0,
    );
    const horizontalInset =
        (_wallHalfWidthWorld * 2) + _spawnClearanceWorld;

    for (final entry in shuffledSkills.asMap().entries) {
      final index = entry.key;
      final skill = entry.value;
      final label = _displayLabelOf(skill);
      final definition = _definitionOf(skill);
      final isHighlighted = skill.id == primarySkillId;
      final visual = _SkillBottleVisual.fromSkill(
        skill,
        highlighted: isHighlighted,
        pictureInfo: _skillPictures[definition.id],
      );
      final chipWidth =
          (40 + (label.length * (5.5 * chipScale)) + (random.nextDouble() * 16))
              .clamp(44.0 * chipScale, 82.0 * chipScale);
      final chipHeight =
          (20.5 + (random.nextDouble() * 6.2)) * (0.9 + (chipScale * 0.1));
      final chipWidthWorld = chipWidth / _worldScale;
      final chipHeightWorld = chipHeight / _worldScale;
      final minCenterX = horizontalInset + (chipWidthWorld / 2);
      final maxCenterX =
          widthInWorld - horizontalInset - (chipWidthWorld / 2);
      final startX = _findSpawnX(
        random: random,
        reservedSpawns: reservedSpawns,
        minCenterX: minCenterX,
        maxCenterX: maxCenterX,
        chipWidthWorld: chipWidthWorld,
      );
      final laneCount = math.min(4, math.max(2, skillCount));
      final laneIndex = index % laneCount;
      final laneTop = 0.04 + (laneIndex * 0.1);
      final startY = (heightInWorld * (laneTop + (random.nextDouble() * 0.05)))
          .clamp(heightInWorld * 0.04, heightInWorld * 0.48);
      reservedSpawns.add(f2d.Vector2(startX, startY));
      final launchDelay = (index * 0.16) + (random.nextDouble() * 0.22);
      final ballastDirection = random.nextBool() ? 1.0 : -1.0;
      final ballastOffsetX = ballastDirection *
          (chipWidthWorld * (0.05 + random.nextDouble() * 0.08));
      final ballastOffsetY =
          (chipHeightWorld * (0.04 + random.nextDouble() * 0.08));
      final launchPointLocal = f2d.Vector2(
        ballastDirection *
            (chipWidthWorld * (0.06 + random.nextDouble() * 0.08)),
        -(chipHeightWorld * (0.04 + random.nextDouble() * 0.06)),
      );
      final launchImpulse = f2d.Vector2(
        (random.nextDouble() - 0.5) * (0.18 + random.nextDouble() * 0.34),
        0.04 + (random.nextDouble() * 0.14),
      );
      final angularImpulse =
          (ballastDirection * (0.004 + random.nextDouble() * 0.012)) +
              ((random.nextDouble() - 0.5) * 0.008);
      final bodyDensity = 1.02 + (random.nextDouble() * 0.14);
      final bodyFriction = 0.28 + (random.nextDouble() * 0.1);
      final bodyRestitution = 0.02 + (random.nextDouble() * 0.025);
      final gravityScaleY = 0.98 + (random.nextDouble() * 0.18);
      final idleOpacity =
          0.04 + math.pow(random.nextDouble(), 1.35).toDouble() * 0.18;

      final body = world.createBody(
        f2d.BodyDef(
          type: f2d.BodyType.dynamic,
          active: true,
          isAwake: false,
          position: f2d.Vector2(
            startX.clamp(minCenterX, maxCenterX),
            startY,
          ),
          angle: (random.nextDouble() - 0.5) * 0.24,
          linearDamping: 0.9 + (random.nextDouble() * 0.45),
          angularDamping: 1.4 + (random.nextDouble() * 0.8),
          gravityScale: f2d.Vector2(1, gravityScaleY),
        ),
      );

      final cornerRadiusWorld = chipHeightWorld / 2;
      final centerHalfWidth = math.max(
        0.001,
        (chipWidthWorld / 2) - cornerRadiusWorld,
      );
      final centerBox = f2d.PolygonShape()
        ..setAsBoxXY(centerHalfWidth, chipHeightWorld / 2);
      final leftCap = f2d.CircleShape(
        radius: cornerRadiusWorld,
        position: f2d.Vector2(-centerHalfWidth, 0),
      );
      final rightCap = f2d.CircleShape(
        radius: cornerRadiusWorld,
        position: f2d.Vector2(centerHalfWidth, 0),
      );

      body.createFixtureFromShape(
        centerBox,
        density: bodyDensity,
        friction: bodyFriction,
        restitution: bodyRestitution,
      );
      body.createFixtureFromShape(
        leftCap,
        density: bodyDensity,
        friction: bodyFriction,
        restitution: bodyRestitution,
      );
      body.createFixtureFromShape(
        rightCap,
        density: bodyDensity,
        friction: bodyFriction,
        restitution: bodyRestitution,
      );
      body.createFixtureFromShape(
        f2d.CircleShape(
          radius: chipHeightWorld * 0.18,
          position: f2d.Vector2(ballastOffsetX, ballastOffsetY),
        ),
        density: bodyDensity * (0.9 + random.nextDouble() * 0.5),
        friction: bodyFriction,
        restitution: bodyRestitution * 0.6,
      );

      particles.add(
        _SkillBottleParticle(
          skill: skill,
          body: body,
          width: chipWidth,
          height: chipHeight,
          visual: visual,
          isHighlighted: isHighlighted,
          launchDelay: launchDelay,
          launchImpulse: launchImpulse,
          launchPointLocal: launchPointLocal,
          angularImpulse: angularImpulse,
          idleOpacity: idleOpacity,
          hasLaunched: _reduceMotion,
        ),
      );
    }

    return particles;
  }

  double _findSpawnX({
    required math.Random random,
    required List<f2d.Vector2> reservedSpawns,
    required double minCenterX,
    required double maxCenterX,
    required double chipWidthWorld,
  }) {
    final span = maxCenterX - minCenterX;
    final preferred = minCenterX + (span * random.nextDouble());
    var best = preferred;
    var bestPenalty = double.infinity;

    for (var attempt = 0; attempt < 10; attempt++) {
      final t = attempt == 0
          ? preferred
          : minCenterX + (span * ((attempt + random.nextDouble()) / 10));
      var penalty = 0.0;
      for (final spawn in reservedSpawns) {
        final dx = (spawn.x - t).abs();
        final minGap = chipWidthWorld * 0.9;
        if (dx < minGap) {
          penalty += (minGap - dx) * 4;
        }
      }
      if (penalty < bestPenalty) {
        bestPenalty = penalty;
        best = t;
      }
    }

    return best.clamp(minCenterX, maxCenterX);
  }

  void _buildBottleBounds(Size size, f2d.World world) {
    final widthInWorld = size.width / _worldScale;
    final heightInWorld = size.height / _worldScale;
    final bounds = world.createBody(f2d.BodyDef());

    final floor = f2d.PolygonShape()
      ..setAsBox(
        widthInWorld / 2,
        _floorHalfHeightWorld,
        f2d.Vector2(widthInWorld / 2, heightInWorld - _floorHalfHeightWorld),
        0,
      );
    final leftWall = f2d.PolygonShape()
      ..setAsBox(
        _wallHalfWidthWorld,
        heightInWorld / 2,
        f2d.Vector2(_wallHalfWidthWorld, heightInWorld / 2),
        0,
      );
    final rightWall = f2d.PolygonShape()
      ..setAsBox(
        _wallHalfWidthWorld,
        heightInWorld / 2,
        f2d.Vector2(widthInWorld - _wallHalfWidthWorld, heightInWorld / 2),
        0,
      );

    bounds.createFixtureFromShape(floor, friction: 0.14, restitution: 0.02);
    bounds.createFixtureFromShape(leftWall, friction: 0.04, restitution: 0.02);
    bounds.createFixtureFromShape(
      rightWall,
      friction: 0.04,
      restitution: 0.02,
    );
  }

  void _tickWorld(Duration elapsed) {
    final world = _world;
    if (world == null) return;

    final dt = _lastElapsed == null
        ? 1 / 60
        : ((elapsed - _lastElapsed!).inMicroseconds /
                Duration.microsecondsPerSecond)
            .clamp(1 / 240, 1 / 24);
    _lastElapsed = elapsed;
    _elapsedSeconds += dt;

    for (final particle in _particles) {
      if (!particle.hasLaunched && _elapsedSeconds >= particle.launchDelay) {
        _releaseParticle(particle);
      }
    }

    final subStep = dt / 2;
    world.stepDt(subStep);
    world.stepDt(subStep);

    final allLaunched = _particles.every((particle) => particle.hasLaunched);
    final allCloseToRest = _particles.every(_isParticleCloseToRest);
    if (allLaunched && allCloseToRest) {
      _restingSeconds += dt;
    } else {
      _restingSeconds = 0;
    }
    final shouldStop = allLaunched &&
        ((_restingSeconds >= 0.9 && _elapsedSeconds > 1.6) ||
            (_elapsedSeconds >= _settleTimeLimit && allCloseToRest));

    if (shouldStop) {
      _ticker.stop();
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool _isParticleCloseToRest(_SkillBottleParticle particle) {
    final body = particle.body;
    return body.position.y > (_fieldSize.height / _worldScale) * 0.58 &&
        body.linearVelocity.length2 < 0.006 &&
        body.angularVelocity.abs() < 0.035;
  }

  void _releaseParticle(
    _SkillBottleParticle particle, {
    bool applyImpulse = true,
  }) {
    particle.hasLaunched = true;
    particle.body.setAwake(true);
    if (applyImpulse) {
      particle.body.applyLinearImpulse(
        particle.launchImpulse,
        point: particle.body.worldPoint(particle.launchPointLocal),
      );
      particle.body.applyAngularImpulse(particle.angularImpulse);
    }
  }

  int _skillsSignature(List<SkillParticleItem> skills) {
    return Object.hashAll(
      skills.map(
        (skill) =>
            '${skill.id}|${skill.name}|${skill.category}|${skill.isPrimary}',
      ),
    );
  }

  int _createLayoutSeed(Size size) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return Object.hash(
      now,
      _skillsSignature(widget.skills),
      size.width.round(),
      size.height.round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nextSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (nextSize.width > 0 &&
            nextSize.height > 0 &&
            nextSize != _fieldSize) {
          _fieldSize = nextSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _configureWorld(nextSize);
          });
        }

        return RepaintBoundary(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white,
                ],
                stops: [0, 0.04, 1],
              ).createShader(rect);
            },
            child: CustomPaint(
              painter: _SkillBottlePainter(
                particles: _particles,
                worldScale: _worldScale,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class _SkillBottleParticle {
  final SkillParticleItem skill;
  final f2d.Body body;
  final double width;
  final double height;
  final _SkillBottleVisual visual;
  final bool isHighlighted;
  final double launchDelay;
  final f2d.Vector2 launchImpulse;
  final f2d.Vector2 launchPointLocal;
  final double angularImpulse;
  final double idleOpacity;
  bool hasLaunched;

  _SkillBottleParticle({
    required this.skill,
    required this.body,
    required this.width,
    required this.height,
    required this.visual,
    required this.isHighlighted,
    required this.launchDelay,
    required this.launchImpulse,
    required this.launchPointLocal,
    required this.angularImpulse,
    required this.idleOpacity,
    this.hasLaunched = false,
  });
}

class _SkillBottleVisual {
  final String label;
  final IconData fallbackIcon;
  final PictureInfo? pictureInfo;
  final Color topColor;
  final Color bottomColor;
  final Color rimColor;
  final Color glowColor;
  final Color iconColor;
  final Color labelColor;
  final Color sparkColor;

  const _SkillBottleVisual({
    required this.label,
    required this.fallbackIcon,
    required this.pictureInfo,
    required this.topColor,
    required this.bottomColor,
    required this.rimColor,
    required this.glowColor,
    required this.iconColor,
    required this.labelColor,
    required this.sparkColor,
  });

  factory _SkillBottleVisual.fromSkill(
    SkillParticleItem skill, {
    required bool highlighted,
    PictureInfo? pictureInfo,
  }) {
    final definition = _SkillParticleFieldState._definitionOf(skill);
    final icon = definition.fallbackIcon;
    final label = _SkillParticleFieldState._displayLabelOf(skill);
    final category = definition.category;

    if (highlighted) {
      return _SkillBottleVisual(
        label: label,
        fallbackIcon: icon,
        pictureInfo: pictureInfo,
        topColor: const Color(0xFF8B7CFF),
        bottomColor: const Color(0xFF5F4BD6),
        rimColor: Colors.white.withValues(alpha: 0.24),
        glowColor: AppColors.accent.withValues(alpha: 0.16),
        iconColor: Colors.white.withValues(alpha: 0.96),
        labelColor: Colors.white.withValues(alpha: 0.92),
        sparkColor: const Color(0xFFC7BCFF),
      );
    }

    if (definition.id == 'flutter' || category == 'mobile') {
      return _SkillBottleVisual(
        label: label,
        fallbackIcon: icon,
        pictureInfo: pictureInfo,
        topColor: const Color(0xFF7FA2C6),
        bottomColor: const Color(0xFF556E8B),
        rimColor: Colors.white.withValues(alpha: 0.16),
        glowColor: const Color(0xFF84C3FF).withValues(alpha: 0.08),
        iconColor: Colors.white.withValues(alpha: 0.84),
        labelColor: Colors.white.withValues(alpha: 0.76),
        sparkColor: const Color(0xFFB9E3FF),
      );
    }

    if (definition.id == 'react' || category == 'framework') {
      return _SkillBottleVisual(
        label: label,
        fallbackIcon: icon,
        pictureInfo: pictureInfo,
        topColor: const Color(0xFF6389BC),
        bottomColor: const Color(0xFF405F86),
        rimColor: Colors.white.withValues(alpha: 0.14),
        glowColor: AppColors.info.withValues(alpha: 0.08),
        iconColor: Colors.white.withValues(alpha: 0.82),
        labelColor: Colors.white.withValues(alpha: 0.74),
        sparkColor: const Color(0xFF95D6FF),
      );
    }

    if (category == 'design') {
      return _SkillBottleVisual(
        label: label,
        fallbackIcon: icon,
        pictureInfo: pictureInfo,
        topColor: const Color(0xFFAD8A63),
        bottomColor: const Color(0xFF70583C),
        rimColor: Colors.white.withValues(alpha: 0.14),
        glowColor: AppColors.accentGold.withValues(alpha: 0.08),
        iconColor: Colors.white.withValues(alpha: 0.84),
        labelColor: Colors.white.withValues(alpha: 0.76),
        sparkColor: const Color(0xFFF4D6A0),
      );
    }

    if (category == 'backend' ||
        category == 'database' ||
        category == 'devops') {
      return _SkillBottleVisual(
        label: label,
        fallbackIcon: icon,
        pictureInfo: pictureInfo,
        topColor: const Color(0xFF66889A),
        bottomColor: const Color(0xFF3E5968),
        rimColor: Colors.white.withValues(alpha: 0.14),
        glowColor: Colors.white.withValues(alpha: 0.05),
        iconColor: Colors.white.withValues(alpha: 0.84),
        labelColor: Colors.white.withValues(alpha: 0.76),
        sparkColor: const Color(0xFFB7D5E5),
      );
    }

    if (category == 'ai') {
      return _SkillBottleVisual(
        label: label,
        fallbackIcon: icon,
        pictureInfo: pictureInfo,
        topColor: const Color(0xFF8C7EAE),
        bottomColor: const Color(0xFF5D5578),
        rimColor: Colors.white.withValues(alpha: 0.14),
        glowColor: Colors.white.withValues(alpha: 0.06),
        iconColor: Colors.white.withValues(alpha: 0.84),
        labelColor: Colors.white.withValues(alpha: 0.76),
        sparkColor: const Color(0xFFE0D4FF),
      );
    }

    return _SkillBottleVisual(
      label: label,
      fallbackIcon: icon,
      pictureInfo: pictureInfo,
      topColor: const Color(0xFF6D6F78),
      bottomColor: const Color(0xFF44464E),
      rimColor: Colors.white.withValues(alpha: 0.12),
      glowColor: Colors.white.withValues(alpha: 0.05),
      iconColor: Colors.white.withValues(alpha: 0.8),
      labelColor: Colors.white.withValues(alpha: 0.72),
      sparkColor: Colors.white.withValues(alpha: 0.78),
    );
  }
}

class _SkillBottlePainter extends CustomPainter {
  final List<_SkillBottleParticle> particles;
  final double worldScale;

  const _SkillBottlePainter({
    required this.particles,
    required this.worldScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final floorGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.15),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.03),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 0.34, 1],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.16, size.width, size.height * 0.92),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      floorGlowPaint,
    );

    final floorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.28, size.height - 2.5),
      Offset(size.width * 0.72, size.height - 2.5),
      floorPaint,
    );

    final regularParticles = particles
        .where((particle) => !particle.isHighlighted)
        .toList(growable: false)
      ..sort((a, b) => a.body.position.y.compareTo(b.body.position.y));
    final highlightedParticles = particles
        .where((particle) => particle.isHighlighted)
        .toList(growable: false)
      ..sort((a, b) => a.body.position.y.compareTo(b.body.position.y));

    for (final particle in regularParticles) {
      _paintParticle(canvas, particle);
    }
    for (final particle in highlightedParticles) {
      _paintParticle(canvas, particle);
    }
  }

  void _paintParticle(Canvas canvas, _SkillBottleParticle particle) {
    final center = Offset(
      particle.body.position.x * worldScale,
      particle.body.position.y * worldScale,
    );
    final isPinnedHighlight = particle.isHighlighted;
    final opacity = isPinnedHighlight ? 0.96 : 0.68;
    final fillTopColor = particle.visual.topColor;
    final fillBottomColor = particle.visual.bottomColor;
    final rimColor = particle.visual.rimColor;
    final iconColor = particle.visual.iconColor;
    final labelColor = particle.visual.labelColor;
    final sparkColor = particle.visual.sparkColor;
    final shadowShift = isPinnedHighlight ? 3.2 : 2.4;
    final angle = particle.body.angle;
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: particle.width,
      height: particle.height,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(particle.height / 2),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final auraPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = (isPinnedHighlight
              ? particle.visual.glowColor.withValues(alpha: 0.24)
              : particle.visual.glowColor.withValues(alpha: 0.08))
          .withValues(alpha: isPinnedHighlight ? 0.22 : 0.08);
    canvas.drawRRect(rrect.inflate(3.2), auraPaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(
        alpha: (isPinnedHighlight ? 0.1 : 0.08) * opacity,
      );
    canvas.drawRRect(rrect.shift(Offset(0, shadowShift)), shadowPaint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          fillTopColor.withValues(alpha: opacity * 0.96),
          fillBottomColor.withValues(alpha: opacity * 0.9),
        ],
      ).createShader(rect);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = rimColor.withValues(
        alpha: isPinnedHighlight ? 0.94 : opacity + 0.04,
      );

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);

    final topHighlightPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: isPinnedHighlight ? 0.22 : 0.14,
      )
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-(particle.width / 2) + 8, -(particle.height * 0.18)),
      Offset((particle.width / 2) - 12, -(particle.height * 0.18)),
      topHighlightPaint,
    );

    final iconBubbleCenter = Offset(
      -(particle.width / 2) + (particle.height * 0.56),
      0,
    );
    final iconBubblePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(
            alpha: isPinnedHighlight ? 0.36 : 0.18,
          ),
          Colors.white.withValues(alpha: isPinnedHighlight ? 0.08 : 0.04),
        ],
      ).createShader(
        Rect.fromCircle(
          center: iconBubbleCenter,
          radius: particle.height * 0.34,
        ),
      );
    canvas.drawCircle(
      iconBubbleCenter,
      particle.height * 0.3,
      iconBubblePaint,
    );

    _paintVisualIcon(
      canvas,
      particle.visual,
      iconBubbleCenter,
      color: iconColor.withValues(
        alpha: isPinnedHighlight ? 0.98 : 0.86,
      ),
      size: (particle.height * 0.46).clamp(9.6, 12.8),
    );

    _paintLabel(
      canvas,
      particle.visual.label,
      Offset(iconBubbleCenter.dx + (particle.height * 0.46), 0),
      color: labelColor.withValues(alpha: isPinnedHighlight ? 0.96 : 0.84),
      fontSize: (particle.height * 0.4).clamp(8.6, 10.6),
    );

    final sparkPaint = Paint()
      ..color = sparkColor.withValues(
        alpha: isPinnedHighlight ? 0.48 : 0.22,
      );
    canvas.drawCircle(
      Offset((particle.width / 2) - 8, -(particle.height * 0.12)),
      1.8,
      sparkPaint,
    );

    canvas.restore();
  }

  void _paintVisualIcon(
    Canvas canvas,
    _SkillBottleVisual visual,
    Offset center, {
    required Color color,
    required double size,
  }) {
    if (visual.pictureInfo != null) {
      _paintPictureIcon(
        canvas,
        visual.pictureInfo!,
        center,
        color: color,
        size: size,
      );
      return;
    }
    _paintIcon(
      canvas,
      visual.fallbackIcon,
      center,
      color: color,
      size: size,
    );
  }

  void _paintPictureIcon(
    Canvas canvas,
    PictureInfo pictureInfo,
    Offset center, {
    required Color color,
    required double size,
  }) {
    final pictureSize = pictureInfo.size;
    if (pictureSize.isEmpty) return;

    final targetRect = Rect.fromCenter(
      center: center,
      width: size,
      height: size,
    );
    final sourceRect = Offset.zero & pictureSize;

    canvas.save();
    canvas.translate(targetRect.left, targetRect.top);
    canvas.scale(
      targetRect.width / pictureSize.width,
      targetRect.height / pictureSize.height,
    );
    canvas.saveLayer(
      sourceRect,
      Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
    );
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();
    canvas.restore();
  }

  void _paintIcon(
    Canvas canvas,
    IconData icon,
    Offset center, {
    required Color color,
    required double size,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - (painter.width / 2), center.dy - (painter.height / 2)),
    );
  }

  void _paintLabel(
    Canvas canvas,
    String label,
    Offset anchor, {
    required Color color,
    required double fontSize,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          inherit: false,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.24,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(anchor.dx, -painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SkillBottlePainter oldDelegate) {
    return true;
  }
}
