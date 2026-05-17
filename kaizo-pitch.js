const pptxgen = require("pptxgenjs");
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const {
  FaRocket, FaBrain, FaUsers, FaShieldAlt, FaChartLine, FaCogs,
  FaSearch, FaHandshake, FaGlobe, FaLayerGroup, FaLightbulb,
  FaExclamationTriangle, FaCheckCircle, FaArrowRight, FaStar,
  FaDatabase, FaCloud, FaCoins, FaUserTie, FaCode, FaRobot,
  FaProjectDiagram, FaBullseye, FaClock, FaLock, FaInfinity,
  FaChartBar, FaRegHandshake, FaTrophy, FaFlagCheckered
} = require("react-icons/fa");

// ─── Color Palette ───
const C = {
  bgDark:    "0B1426",
  bgMedium:  "132040",
  bgCard:    "1A2B4A",
  accent:    "00C9A7",  // teal/mint
  accentDim: "0A7A66",
  orange:    "FF6B35",
  white:     "FFFFFF",
  muted:     "7B8CA8",
  divider:   "2A3F66",
  lightBg:   "F0F4F8",
  darkText:  "1A2B4A",
  cardLight: "E8EDF4",
};

// ─── Icon Helper ───
function renderIconSvg(IconComponent, color, size = 256) {
  return ReactDOMServer.renderToStaticMarkup(
    React.createElement(IconComponent, { color, size: String(size) })
  );
}

async function iconToBase64Png(IconComponent, color, size = 256) {
  const svg = renderIconSvg(IconComponent, color, size);
  const pngBuffer = await sharp(Buffer.from(svg)).png().toBuffer();
  return "image/png;base64," + pngBuffer.toString("base64");
}

// ─── Reusable Helpers ───
const makeCardShadow = () => ({ type: "outer", blur: 6, offset: 2, angle: 135, color: "000000", opacity: 0.2 });

function addFooter(slide, pageNum, totalPages) {
  slide.addText(`${pageNum} / ${totalPages}`, {
    x: 4.2, y: 5.25, w: 1.6, h: 0.3,
    fontSize: 9, color: C.muted, align: "center", fontFace: "Calibri"
  });
}

function addDarkSlideBase(slide) {
  slide.background = { color: C.bgDark };
  slide.addShape("line", { x: 0, y: 0, w: 10, h: 0, line: { color: C.accent, width: 2 } });
}

async function main() {
  const pres = new pptxgen();
  pres.layout = "LAYOUT_16x9";
  pres.author = "开造 KAIZO";
  pres.title = "开造 KAIZO — 智能化服务的前夜";

  const TOTAL = 18;

  // ─── Pre-render all icons ───
  const icons = {};
  const iconDefs = [
    ["rocket", FaRocket, C.accent],
    ["brain", FaBrain, C.accent],
    ["users", FaUsers, C.accent],
    ["shield", FaShieldAlt, C.accent],
    ["chart", FaChartLine, C.accent],
    ["cogs", FaCogs, C.accent],
    ["search", FaSearch, C.accent],
    ["handshake", FaHandshake, C.accent],
    ["globe", FaGlobe, C.accent],
    ["layer", FaLayerGroup, C.accent],
    ["bulb", FaLightbulb, C.orange],
    ["warn", FaExclamationTriangle, C.orange],
    ["check", FaCheckCircle, C.accent],
    ["arrow", FaArrowRight, C.accent],
    ["star", FaStar, C.orange],
    ["database", FaDatabase, C.accent],
    ["cloud", FaCloud, C.accent],
    ["coins", FaCoins, C.orange],
    ["userTie", FaUserTie, C.accent],
    ["code", FaCode, C.accent],
    ["robot", FaRobot, C.accent],
    ["project", FaProjectDiagram, C.accent],
    ["bullseye", FaBullseye, C.orange],
    ["clock", FaClock, C.accent],
    ["lock", FaLock, C.accent],
    ["infinity", FaInfinity, C.accent],
    ["chartBar", FaChartBar, C.accent],
    ["regHandshake", FaRegHandshake, C.accent],
    ["trophy", FaTrophy, C.orange],
    ["flag", FaFlagCheckered, C.accent],
    ["rocketW", FaRocket, C.white],
    ["brainW", FaBrain, C.white],
    ["globeW", FaGlobe, C.white],
    ["usersW", FaUsers, C.white],
    ["cogsW", FaCogs, C.white],
    ["shieldW", FaShieldAlt, C.white],
    ["chartW", FaChartLine, C.white],
    ["robotW", FaRobot, C.white],
    ["codeW", FaCode, C.white],
    ["coinsW", FaCoins, C.white],
    ["lockW", FaLock, C.white],
    ["searchW", FaSearch, C.white],
    ["bulbW", FaLightbulb, C.white],
    ["arrowW", FaArrowRight, C.white],
  ];

  for (const [name, comp, color] of iconDefs) {
    icons[name] = await iconToBase64Png(comp, color);
  }

  // ════════════════════════════════════════════════════════════
  // SLIDE 1: 封面 Title
  // ════════════════════════════════════════════════════════════
  let slide = pres.addSlide();
  slide.background = { color: C.bgDark };

  // Decorative circles
  slide.addShape("oval", {
    x: 7.5, y: -1.5, w: 4, h: 4,
    fill: { color: C.accent, transparency: 90 }
  });
  slide.addShape("oval", {
    x: 8.2, y: -0.8, w: 2.5, h: 2.5,
    fill: { color: C.accent, transparency: 85 }
  });
  slide.addShape("oval", { x: 0.8, y: 4.2, w: 0.15, h: 0.15, fill: { color: C.accent, transparency: 40 } });
  slide.addShape("oval", { x: 1.2, y: 4.5, w: 0.1, h: 0.1, fill: { color: C.accent, transparency: 60 } });
  slide.addShape("oval", { x: 1.5, y: 4.1, w: 0.08, h: 0.08, fill: { color: C.orange, transparency: 50 } });

  slide.addText("开造 KAIZO", {
    x: 0.8, y: 1.2, w: 8, h: 1.0,
    fontSize: 48, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText("智能化服务的前夜", {
    x: 0.8, y: 2.2, w: 8, h: 0.7,
    fontSize: 28, fontFace: "Georgia", color: C.accent, margin: 0
  });
  slide.addText("AI 时代的服务交易基础设施", {
    x: 0.8, y: 3.0, w: 8, h: 0.5,
    fontSize: 16, fontFace: "Calibri", color: C.muted, margin: 0
  });
  slide.addShape("rectangle", {
    x: 0.8, y: 3.7, w: 1.2, h: 0.04, fill: { color: C.accent }
  });
  slide.addText("中关村创坛 · 2026", {
    x: 0.8, y: 3.9, w: 5, h: 0.4,
    fontSize: 13, fontFace: "Calibri", color: C.muted, margin: 0
  });

  // ════════════════════════════════════════════════════════════
  // SLIDE 2: 核心观点
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  slide.background = { color: C.bgDark };

  slide.addText("\u201C", {
    x: 0.3, y: 0.2, w: 2, h: 2,
    fontSize: 120, fontFace: "Georgia", color: C.accent, bold: true,
    transparency: 70, margin: 0
  });

  slide.addText("\u6211\u4EEC\u7AD9\u5728\u667A\u80FD\u5316\u670D\u52A1\u7684\u524D\u591C", {
    x: 0.8, y: 1.0, w: 8.4, h: 0.9,
    fontSize: 32, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  slide.addText([
    { text: "\u5728\u8FD9\u4E2A\u4F9B\u7ED9\u8FDC\u5927\u4E8E\u9700\u6C42\u7684\u65F6\u4EE3\uFF0C", options: { fontSize: 18, color: C.muted, breakLine: true } },
    { text: "\u6BCF\u4E00\u4E2A\u9700\u6C42\u90FD\u5E94\u8BE5\u88AB\u73CD\u60DC\uFF0C\u88AB\u4E13\u4E1A\u6240\u670D\u52A1\u3002", options: { fontSize: 18, color: C.accent, breakLine: true } },
    { text: "", options: { fontSize: 10, breakLine: true } },
    { text: "\u771F\u6B63\u7684\u53D8\u9769\u4E0D\u5728\u4E8E\u751F\u4EA7\u529B\u7684\u63D0\u5347\uFF0C", options: { fontSize: 18, color: C.muted, breakLine: true } },
    { text: "\u800C\u5728\u4E8E\u8BA9\u9700\u6C42\u7684\u4EF7\u503C\u88AB\u91CD\u65B0\u53D1\u73B0\uFF0C", options: { fontSize: 18, color: C.muted, breakLine: true } },
    { text: "\u8BA9\u884C\u4E1A\u4F9B\u7ED9\u4FA7\u8FCE\u6765\u771F\u6B63\u7684\u7ED3\u6784\u6027\u6539\u9769\u3002", options: { fontSize: 18, color: C.white, bold: true } },
  ], { x: 0.8, y: 2.2, w: 8.4, h: 2.5, fontFace: "Calibri", margin: 0 });

  slide.addShape("rectangle", {
    x: 0.8, y: 5.0, w: 2.0, h: 0.04, fill: { color: C.accent }
  });
  addFooter(slide, 1, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 3: AI编程工具赛道爆发
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addImage({ data: icons.rocketW, x: 0.8, y: 0.35, w: 0.35, h: 0.35 });
  slide.addText("\u4E00\u573A\u6B63\u5728\u53D1\u751F\u7684\u751F\u4EA7\u529B\u9769\u547D", {
    x: 1.25, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText("AI Coding \u8D5B\u9053\u5DF2\u8FDB\u5165\u5343\u4EBF\u7F8E\u5143\u7EA7\u522B", {
    x: 0.8, y: 0.85, w: 8, h: 0.35,
    fontSize: 13, fontFace: "Calibri", color: C.muted, margin: 0
  });

  const dataCards = [
    { num: "$293\u4EBF", label: "Cursor \u4F30\u503C", sub: "\u53F2\u4E0A\u6700\u5FEB\u8FBE $10\u4EBF ARR \u7684 SaaS" },
    { num: "2,000\u4E07", label: "GitHub Copilot \u7528\u6237", sub: "AI \u7F16\u7A0B\u5DF2\u6210\u5F00\u53D1\u8005\u6807\u914D" },
    { num: "$66\u4EBF", label: "Lovable \u4F30\u503C", sub: "\u975E\u6280\u672F\u4EBA\u5458\u4E5F\u80FD\u9020\u8F6F\u4EF6" },
    { num: "6,700%", label: "Vibe Coding \u641C\u7D22\u589E\u957F", sub: "\u5165\u9009 Collins \u5E74\u5EA6\u8BCD\u6C47" },
    { num: "$301\u4EBF", label: "2032 \u5E74\u5E02\u573A\u89C4\u6A21", sub: "CAGR 27.1% \u9AD8\u901F\u589E\u957F" },
    { num: "$30\u4EBF", label: "OpenAI \u62A2\u8D2D Windsurf", sub: "\u5DE8\u5934\u771F\u91D1\u767D\u94F6\u62A2 AI \u7F16\u7A0B\u8D44\u4EA7" },
  ];

  for (let i = 0; i < 6; i++) {
    const col = i % 3;
    const row = Math.floor(i / 3);
    const x = 0.5 + col * 3.1;
    const y = 1.4 + row * 2.0;

    slide.addShape("rectangle", {
      x, y, w: 2.85, h: 1.75,
      fill: { color: C.bgCard },
      shadow: makeCardShadow()
    });
    slide.addShape("rectangle", {
      x, y, w: 0.06, h: 1.75,
      fill: { color: i < 3 ? C.accent : C.orange }
    });
    slide.addText(dataCards[i].num, {
      x: x + 0.2, y: y + 0.15, w: 2.5, h: 0.6,
      fontSize: 28, fontFace: "Georgia", color: i < 3 ? C.accent : C.orange,
      bold: true, margin: 0
    });
    slide.addText(dataCards[i].label, {
      x: x + 0.2, y: y + 0.75, w: 2.5, h: 0.35,
      fontSize: 13, fontFace: "Calibri", color: C.white, bold: true, margin: 0
    });
    slide.addText(dataCards[i].sub, {
      x: x + 0.2, y: y + 1.1, w: 2.5, h: 0.45,
      fontSize: 10, fontFace: "Calibri", color: C.muted, margin: 0
    });
  }
  addFooter(slide, 2, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 4: AI Agent 生态爆发
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addImage({ data: icons.robotW, x: 0.8, y: 0.35, w: 0.35, h: 0.35 });
  slide.addText("AI Agent \u751F\u6001\u6B63\u5728\u6307\u6570\u7EA7\u6269\u5F20", {
    x: 1.25, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  const agentData = [
    { num: "35.1\u4E07", label: "GitHub Star", desc: "\u6BD4 React \u5341\u5E74\u79EF\u7D2F\u8FD8\u591A" },
    { num: "$25\u4EBF", label: "Claude Code ARR", desc: "6\u4E2A\u6708\u4ECE0\u5230$10\u4EBF" },
    { num: "4.4\u4E07+", label: "Agent Skill", desc: "4\u4E2A\u6708\u4ECE0\u52304.4\u4E07" },
    { num: "$2,019\u4EBF", label: "2026 Agent AI \u652F\u51FA", desc: "Agent \u662F\u771F\u91D1\u767D\u94F6\u7684\u5E02\u573A" },
  ];

  for (let i = 0; i < 4; i++) {
    const y = 1.2 + i * 1.05;
    slide.addShape("rectangle", {
      x: 0.5, y, w: 4.3, h: 0.85,
      fill: { color: C.bgCard }
    });
    slide.addShape("rectangle", {
      x: 0.5, y, w: 0.06, h: 0.85,
      fill: { color: C.accent }
    });
    slide.addText(agentData[i].num, {
      x: 0.7, y: y + 0.05, w: 2.0, h: 0.45,
      fontSize: 24, fontFace: "Georgia", color: C.accent, bold: true, margin: 0
    });
    slide.addText(agentData[i].label, {
      x: 2.7, y: y + 0.08, w: 2, h: 0.35,
      fontSize: 12, fontFace: "Calibri", color: C.white, bold: true, margin: 0, valign: "middle"
    });
    slide.addText(agentData[i].desc, {
      x: 0.7, y: y + 0.5, w: 3.8, h: 0.3,
      fontSize: 10, fontFace: "Calibri", color: C.muted, margin: 0
    });
  }

  // Right insight box
  slide.addShape("rectangle", {
    x: 5.2, y: 1.2, w: 4.3, h: 4.0,
    fill: { color: C.bgCard },
    shadow: makeCardShadow()
  });
  slide.addImage({ data: icons.bulb, x: 5.5, y: 1.5, w: 0.4, h: 0.4 });
  slide.addText("\u6838\u5FC3\u5224\u65AD", {
    x: 6.0, y: 1.5, w: 3, h: 0.4,
    fontSize: 16, fontFace: "Georgia", color: C.orange, bold: true, margin: 0
  });

  slide.addText([
    { text: "AI Coding \u5B9E\u73B0\u4E86", options: { fontSize: 14, color: C.muted, breakLine: true } },
    { text: "\u6280\u672F\u5E73\u6743", options: { fontSize: 22, color: C.white, bold: true, breakLine: true } },
    { text: "", options: { fontSize: 8, breakLine: true } },
    { text: "\u4E00\u4E2A 3 \u4EBA\u56E2\u961F + AI \u7684\u4EA7\u51FA", options: { fontSize: 13, color: C.muted, breakLine: true } },
    { text: "= \u4F20\u7EDF 15 \u4EBA\u56E2\u961F", options: { fontSize: 18, color: C.accent, bold: true, breakLine: true } },
    { text: "", options: { fontSize: 8, breakLine: true } },
    { text: "\u5F53\u751F\u4EA7\u529B\u53D1\u751F\u6307\u6570\u7EA7\u53D8\u5316\u65F6", options: { fontSize: 13, color: C.muted, breakLine: true } },
    { text: "\u4EA7\u4E1A\u7ED3\u6784\u5FC5\u7136\u91CD\u7EC4", options: { fontSize: 18, color: C.orange, bold: true } },
  ], { x: 5.5, y: 2.2, w: 3.8, h: 2.8, fontFace: "Calibri", margin: 0 });

  addFooter(slide, 3, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 5: 算力普惠化
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addImage({ data: icons.chartW, x: 0.8, y: 0.35, w: 0.35, h: 0.35 });
  slide.addText("\u7B97\u529B\u666E\u60E0\u5316\uFF1AAI \u80FD\u529B\u50CF\u6C34\u7535\u4E00\u6837\u6309\u9700\u4F9B\u7ED9", {
    x: 1.25, y: 0.3, w: 8, h: 0.5,
    fontSize: 20, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  const stats = [
    { num: "1,400x", label: "\u4E2D\u56FD Token \u8C03\u7528\u589E\u957F", sub: "1,000\u4EBF \u2192 140\u4E07\u4EBF/\u65E5" },
    { num: "50-200x", label: "LLM \u4EF7\u683C\u6BCF\u5E74\u66B4\u8DCC", sub: "DeepSeek \u6210\u672C\u4EC5 GPT-5 \u7684 1/140" },
    { num: "$7,000\u4EBF", label: "\u5168\u7403 AI \u57FA\u7840\u8BBE\u65BD\u6295\u5165", sub: "AWS+Google+Meta+Microsoft 2026" },
  ];

  for (let i = 0; i < 3; i++) {
    const x = 0.5 + i * 3.15;
    slide.addShape("rectangle", {
      x, y: 1.1, w: 2.9, h: 1.6,
      fill: { color: C.bgCard },
      shadow: makeCardShadow()
    });
    slide.addText(stats[i].num, {
      x: x + 0.15, y: 1.2, w: 2.6, h: 0.65,
      fontSize: 32, fontFace: "Georgia", color: C.accent, bold: true, align: "center", margin: 0
    });
    slide.addText(stats[i].label, {
      x: x + 0.15, y: 1.85, w: 2.6, h: 0.35,
      fontSize: 12, fontFace: "Calibri", color: C.white, bold: true, align: "center", margin: 0
    });
    slide.addText(stats[i].sub, {
      x: x + 0.15, y: 2.2, w: 2.6, h: 0.4,
      fontSize: 10, fontFace: "Calibri", color: C.muted, align: "center", margin: 0
    });
  }

  // Bottom implication
  slide.addShape("rectangle", {
    x: 0.5, y: 3.1, w: 9.0, h: 2.2,
    fill: { color: C.bgCard }
  });
  slide.addShape("rectangle", {
    x: 0.5, y: 3.1, w: 9.0, h: 0.05,
    fill: { color: C.accent }
  });
  slide.addText("\u8FD9\u610F\u5473\u7740\u4EC0\u4E48\uFF1F", {
    x: 0.8, y: 3.3, w: 8, h: 0.4,
    fontSize: 16, fontFace: "Georgia", color: C.accent, bold: true, margin: 0
  });
  slide.addText([
    { text: "\u8FC7\u53BB\u53EA\u6709\u5927\u4F01\u4E1A\u7528\u5F97\u8D77\u7684 AI \u80FD\u529B\uFF0C\u73B0\u5728\u4E00\u4EBA\u516C\u53F8\u4E5F\u80FD\u6309 Token \u8C03\u7528", options: { bullet: true, breakLine: true, fontSize: 13, color: C.white } },
    { text: "AI Agent Skill \u7684\u8FD0\u884C\u6210\u672C\u5DF2\u4F4E\u5230\u53EF\u4EE5\u4F5C\u4E3A\u300C\u670D\u52A1\u300D\u5BF9\u5916\u9500\u552E\u5E76\u76C8\u5229", options: { bullet: true, breakLine: true, fontSize: 13, color: C.white } },
    { text: "\u5168\u7403\u7B97\u529B\u8FC7\u5269 + Token \u6210\u672C\u66B4\u8DCC = AI \u80FD\u529B\u53EF\u4EE5\u50CF\u6C34\u7535\u4E00\u6837\u6309\u9700\u4F9B\u7ED9", options: { bullet: true, breakLine: true, fontSize: 13, color: C.accent } },
    { text: "\u5E73\u53F0\u505A\u7684\u662F\u4E2D\u95F4\u7684\u8C03\u5EA6\u548C\u4FE1\u4EFB\u5C42", options: { bullet: true, fontSize: 13, color: C.muted } },
  ], { x: 0.8, y: 3.8, w: 8.5, h: 1.4, fontFace: "Calibri", margin: 0 });
  addFooter(slide, 4, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 6: 生产关系重组
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addImage({ data: icons.usersW, x: 0.8, y: 0.35, w: 0.35, h: 0.35 });
  slide.addText("\u751F\u4EA7\u529B\u9769\u547D\u5E26\u6765\u751F\u4EA7\u5173\u7CFB\u91CD\u7EC4", {
    x: 1.25, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  const changes = [
    {
      icon: "usersW", title: "\u96C7\u4F63\u53BB\u4E2D\u5FC3\u5316",
      subtitle: "\u8D85\u7EA7\u4E2A\u4F53\u5D1B\u8D77",
      points: ["\u72EC\u7ACB\u521B\u4E1A\u8005\u5360\u6BD4 36.3%", "\u4E00\u4EBA\u516C\u53F8 Base44 \u88AB $8,000\u4E07\u6536\u8D2D", "\u7075\u6D3B\u5C31\u4E1A\u4EBA\u53E3\u8D85 2 \u4EBF", "\u5DE5\u5177\u6808\u5E74\u8D39\u4EC5 $3K-12K"]
    },
    {
      icon: "cogsW", title: "\u4F01\u4E1A\u670D\u52A1\u53BB\u4E2D\u5FC3\u5316",
      subtitle: "\u80FD\u529B\u6309\u9700\u8C03\u7528",
      points: ["\u5927\u4F01\u4E1AAI\u91C7\u7528\u7387 78%", "\u4E2D\u5C0F\u4F01\u4E1A\u4EC5 17%", "\u80FD\u529B\u4E0D\u5E94\u88AB\u9501\u5728\u516C\u53F8\u5185\u90E8", "\u901A\u8FC7\u5E73\u53F0\u6D41\u8F6C\u3001\u786E\u6743\u3001\u6309\u9700\u4ED8\u8D39"]
    },
    {
      icon: "robotW", title: "Agent \u6210\u4E3A\u670D\u52A1\u4E3B\u4F53",
      subtitle: "\u4EBA\u4E0E AI \u5E73\u7B49\u4F9B\u7ED9",
      points: ["4.4\u4E07+ AI Skill \u8986\u76D6\u6570\u767E\u9886\u57DF", "\u4F46\u5546\u4E1A\u5316\u901A\u9053\u7A7A\u767D", "12% Skill \u542B\u6076\u610F\u4EE3\u7801", "\u9700\u8981\u4FE1\u4EFB\u8BA4\u8BC1\u57FA\u7840\u8BBE\u65BD"]
    },
  ];

  for (let i = 0; i < 3; i++) {
    const x = 0.35 + i * 3.2;
    const cardW = 2.95;

    slide.addShape("rectangle", {
      x, y: 1.1, w: cardW, h: 4.2,
      fill: { color: C.bgCard },
      shadow: makeCardShadow()
    });
    slide.addShape("rectangle", {
      x, y: 1.1, w: cardW, h: 0.06,
      fill: { color: i === 0 ? C.accent : (i === 1 ? C.orange : C.accent) }
    });
    slide.addImage({ data: icons[changes[i].icon], x: x + 0.25, y: 1.35, w: 0.35, h: 0.35 });
    slide.addText(changes[i].title, {
      x: x + 0.15, y: 1.8, w: cardW - 0.3, h: 0.4,
      fontSize: 16, fontFace: "Georgia", color: C.white, bold: true, margin: 0
    });
    slide.addText(changes[i].subtitle, {
      x: x + 0.15, y: 2.2, w: cardW - 0.3, h: 0.3,
      fontSize: 12, fontFace: "Calibri", color: C.accent, margin: 0
    });

    const bullets = changes[i].points.map((p, idx) => ({
      text: p,
      options: {
        bullet: true, fontSize: 11, color: C.muted,
        breakLine: idx < changes[i].points.length - 1
      }
    }));
    slide.addText(bullets, {
      x: x + 0.15, y: 2.7, w: cardW - 0.3, h: 2.3,
      fontFace: "Calibri", margin: 0, paraSpaceAfter: 6
    });
  }
  addFooter(slide, 5, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 7: 供给侧改革观点页
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  slide.background = { color: C.bgMedium };
  slide.addShape("rectangle", {
    x: 0, y: 0, w: 0.12, h: 5.625,
    fill: { color: C.accent }
  });

  slide.addText("\u4F9B\u7ED9\u4FA7\u6539\u9769", {
    x: 0.8, y: 0.5, w: 8, h: 0.5,
    fontSize: 14, fontFace: "Calibri", color: C.accent, charSpacing: 6, margin: 0
  });
  slide.addText("\u5728\u4F9B\u7ED9\u8FDC\u5927\u4E8E\u9700\u6C42\u7684\u65F6\u4EE3", {
    x: 0.8, y: 1.2, w: 8.4, h: 0.7,
    fontSize: 30, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText([
    { text: "\u5168\u7403 Vibe Coder \u6570\u4EE5\u767E\u4E07\u8BA1\uFF0CAI Agent Skill 4.4\u4E07+\uFF0C", options: { fontSize: 16, color: C.muted, breakLine: true } },
    { text: "\u6280\u672F\u80FD\u529B\u4ECE\u672A\u5982\u6B64\u5145\u6C9B\u3002", options: { fontSize: 16, color: C.muted, breakLine: true } },
    { text: "", options: { fontSize: 10, breakLine: true } },
    { text: "\u4F46\u9700\u6C42\u65B9\u627E\u4E0D\u5230\u9760\u8C31\u670D\u52A1\uFF0C", options: { fontSize: 16, color: C.white, breakLine: true } },
    { text: "\u4F9B\u7ED9\u65B9\u627E\u4E0D\u5230\u4ED8\u8D39\u5BA2\u6237\u3002", options: { fontSize: 16, color: C.white, breakLine: true } },
    { text: "", options: { fontSize: 10, breakLine: true } },
    { text: "\u6BCF\u4E00\u4E2A\u9700\u6C42\u90FD\u503C\u5F97\u88AB\u4E13\u4E1A\u670D\u52A1", options: { fontSize: 22, color: C.accent, bold: true, breakLine: true } },
    { text: "\u8FD9\u624D\u662F\u4F9B\u7ED9\u4FA7\u6539\u9769\u7684\u771F\u6B63\u542B\u4E49\u3002", options: { fontSize: 22, color: C.orange, bold: true } },
  ], { x: 0.8, y: 2.1, w: 8.4, h: 3.0, fontFace: "Calibri", margin: 0 });
  addFooter(slide, 6, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 8: 需求侧痛点
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addImage({ data: icons.searchW, x: 0.8, y: 0.35, w: 0.35, h: 0.35 });
  slide.addText("\u9700\u6C42\u4FA7\u7684\u75DB\uFF1A\u6280\u672F\u7126\u8651", {
    x: 1.25, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText("\u6838\u5FC3\u95EE\u9898\u4E0D\u662F\u201C\u6CA1\u6709\u6280\u672F\u4EBA\u624D\u201D\uFF0C\u800C\u662F\u7F3A\u5C11\u4E00\u4E2A\u53EF\u4FE1\u8D56\u7684\u8FDE\u63A5\u57FA\u7840\u8BBE\u65BD", {
    x: 0.8, y: 0.85, w: 8.5, h: 0.35,
    fontSize: 12, fontFace: "Calibri", color: C.accent, italic: true, margin: 0
  });

  const painPoints = [
    { icon: "searchW", title: "\u627E\u4EBA\u96BE", desc: "\u6709\u9700\u6C42\u4F46\u4E0D\u77E5\u9053\u627E\u8C01\uFF0C\u6015\u88AB\u5751", data: "\u4E2D\u56FD\u8F6F\u4EF6\u5916\u5305 \u00A53,000\u4EBF" },
    { icon: "bulbW", title: "\u8BF4\u4E0D\u6E05", desc: "\u9700\u6C42\u65B9\u4E0D\u61C2\u6280\u672F\uFF0C\u63CF\u8FF0\u6A21\u7CCA\uFF0C\u53CD\u590D\u8FD4\u5DE5", data: "\u732A\u516B\u6212\u5DEE\u8BC4\u9AD8\u9891\u8BCD\uFF1A\u201C\u8D27\u4E0D\u5BF9\u677F\u201D" },
    { icon: "shieldW", title: "\u7BA1\u4E0D\u4E86", desc: "\u8FC7\u7A0B\u4E0D\u900F\u660E\uFF0C\u4EA4\u4ED8\u8D28\u91CF\u65E0\u4FDD\u969C", data: "\u4F20\u7EDF\u5916\u5305\u4E89\u8BAE\u7387 15-20%" },
    { icon: "coinsW", title: "\u7528\u4E0D\u8D77", desc: "\u4F20\u7EDF\u5916\u5305\u4E07\u5143\u8D77\u6B65\u3001\u6570\u6708\u5468\u671F", data: "\u4E2D\u5C0F\u4F01\u4E1A\u627F\u53D7\u4E0D\u8D77" },
    { icon: "brainW", title: "AI\u8F6C\u578B\u65E0\u95E8", desc: "\u60F3\u7528 AI \u4F46\u4E0D\u4F1A\u9009\u578B\u3001\u90E8\u7F72\u3001\u96C6\u6210", data: "\u4E2D\u5C0F\u4F01\u4E1AAI\u91C7\u7528\u7387\u8FDC\u4F4E\u4E8E\u5927\u4F01\u4E1A" },
  ];

  for (let i = 0; i < 5; i++) {
    const y = 1.35 + i * 0.82;
    slide.addShape("rectangle", {
      x: 0.5, y, w: 9.0, h: 0.7,
      fill: { color: i % 2 === 0 ? C.bgCard : C.bgMedium }
    });
    slide.addShape("rectangle", {
      x: 0.5, y, w: 0.06, h: 0.7,
      fill: { color: C.orange }
    });
    slide.addImage({ data: icons[painPoints[i].icon], x: 0.75, y: y + 0.15, w: 0.35, h: 0.35 });
    slide.addText(painPoints[i].title, {
      x: 1.25, y: y + 0.05, w: 1.2, h: 0.3,
      fontSize: 14, fontFace: "Georgia", color: C.orange, bold: true, margin: 0
    });
    slide.addText(painPoints[i].desc, {
      x: 1.25, y: y + 0.35, w: 3.5, h: 0.3,
      fontSize: 11, fontFace: "Calibri", color: C.muted, margin: 0
    });
    slide.addText(painPoints[i].data, {
      x: 5.5, y: y + 0.1, w: 3.8, h: 0.45,
      fontSize: 11, fontFace: "Calibri", color: C.white, align: "right", margin: 0, valign: "middle"
    });
  }
  addFooter(slide, 7, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 9: 供给侧 + 平台痛点
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addText("\u4F9B\u7ED9\u4FA7\u4E0E\u5E73\u53F0\u4FA7\u7684\u75DB", {
    x: 0.8, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  // Left
  slide.addShape("rectangle", {
    x: 0.5, y: 1.0, w: 4.3, h: 3.8,
    fill: { color: C.bgCard }, shadow: makeCardShadow()
  });
  slide.addShape("rectangle", {
    x: 0.5, y: 1.0, w: 4.3, h: 0.06, fill: { color: C.accent }
  });
  slide.addText("\u6709\u80FD\u529B\u7684\u4EBA\u627E\u4E0D\u5230\u5BA2\u6237", {
    x: 0.7, y: 1.2, w: 4, h: 0.4,
    fontSize: 16, fontFace: "Georgia", color: C.accent, bold: true, margin: 0
  });
  const supplyPains = [
    "\u5B66\u4F1A\u4E86 Cursor/Lovable\uFF0C\u4E0D\u77E5\u9053\u53BB\u54EA\u63A5\u5355",
    "\u5BA2\u6237\u201C\u4E0D\u77E5\u9053\u81EA\u5DF1\u8981\u4EC0\u4E48\u201D",
    "\u6CA1\u6709\u62C5\u4FDD\u673A\u5236\uFF0C\u5E72\u5B8C\u6D3B\u62FF\u4E0D\u5230\u94B1",
    "\u6CA1\u6709\u5E73\u53F0\u79EF\u7D2F\u4FE1\u7528\u8D44\u4EA7",
    "OpenClaw Skill \u5F00\u53D1\u8005\u6CA1\u6709\u5546\u4E1A\u5316\u6E20\u9053",
  ];
  slide.addText(supplyPains.map((p, i) => ({
    text: p,
    options: { bullet: true, fontSize: 12, color: C.muted, breakLine: i < supplyPains.length - 1 }
  })), {
    x: 0.7, y: 1.8, w: 3.9, h: 2.8, fontFace: "Calibri", margin: 0, paraSpaceAfter: 8
  });

  // Right
  slide.addShape("rectangle", {
    x: 5.2, y: 1.0, w: 4.3, h: 3.8,
    fill: { color: C.bgCard }, shadow: makeCardShadow()
  });
  slide.addShape("rectangle", {
    x: 5.2, y: 1.0, w: 4.3, h: 0.06, fill: { color: C.orange }
  });
  slide.addText("\u4F20\u7EDF\u5E73\u53F0\u6A21\u5F0F\u5931\u6548", {
    x: 5.4, y: 1.2, w: 4, h: 0.4,
    fontSize: 16, fontFace: "Georgia", color: C.orange, bold: true, margin: 0
  });
  const platformPains = [
    "\u8DF3\u5355\u7387\u6781\u9AD8 \u2014 \u4ECB\u7ECD\u5B8C\u5E73\u53F0\u5C31\u6CA1\u7528\u4E86",
    "\u65E0 AI \u80FD\u529B \u2014 \u4F20\u7EDF\u4FE1\u606F\u53D1\u5E03\u6A21\u5F0F",
    "\u54C1\u7C7B\u8001\u65E7 \u2014 \u672A\u8DDF\u8FDB Vibe Coding",
    "\u8D28\u91CF\u4E0D\u53EF\u63A7 \u2014 \u65E0\u6807\u51C6\u5316\u9A8C\u6536\u4F53\u7CFB",
  ];
  slide.addText(platformPains.map((p, i) => ({
    text: p,
    options: { bullet: true, fontSize: 12, color: C.muted, breakLine: i < platformPains.length - 1 }
  })), {
    x: 5.4, y: 1.8, w: 3.9, h: 2.2, fontFace: "Calibri", margin: 0, paraSpaceAfter: 8
  });

  slide.addShape("rectangle", {
    x: 5.2, y: 3.7, w: 4.3, h: 0.9, fill: { color: C.bgMedium }
  });
  slide.addText([
    { text: "Upwork + Fiverr + Toptal \u5408\u8BA1\u5E02\u5360\u7387\u4EC5 ", options: { fontSize: 11, color: C.muted } },
    { text: "22.7%", options: { fontSize: 16, color: C.orange, bold: true } },
  ], {
    x: 5.4, y: 3.8, w: 3.9, h: 0.7, fontFace: "Calibri", margin: 0, valign: "middle"
  });
  addFooter(slide, 8, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 10: 开造的解法
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  slide.background = { color: C.bgMedium };
  slide.addShape("rectangle", { x: 0, y: 0, w: 0.12, h: 5.625, fill: { color: C.accent } });

  slide.addText("\u6211\u4EEC\u7684\u89E3\u6CD5", {
    x: 0.8, y: 0.6, w: 8, h: 0.4,
    fontSize: 14, fontFace: "Calibri", color: C.accent, charSpacing: 6, margin: 0
  });
  slide.addText("\u4E0D\u662F\u64AE\u5408\u5E73\u53F0", {
    x: 0.8, y: 1.2, w: 8, h: 0.7,
    fontSize: 32, fontFace: "Georgia", color: C.muted, margin: 0
  });
  slide.addText("\u662F AI \u65F6\u4EE3\u7684\u670D\u52A1\u4EA4\u6613\u57FA\u7840\u8BBE\u65BD", {
    x: 0.8, y: 1.9, w: 8.5, h: 0.8,
    fontSize: 32, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  slide.addShape("rectangle", {
    x: 0.8, y: 3.0, w: 8.4, h: 1.5,
    fill: { color: C.bgCard }, shadow: makeCardShadow()
  });
  slide.addShape("rectangle", {
    x: 0.8, y: 3.0, w: 0.06, h: 1.5, fill: { color: C.accent }
  });
  slide.addText([
    { text: "AI Agent \u6D88\u9664\u4FE1\u606F\u5DEE\u548C\u4FE1\u4EFB\u5DEE", options: { fontSize: 18, color: C.white, bold: true, breakLine: true } },
    { text: "", options: { fontSize: 6, breakLine: true } },
    { text: "AI \u62C6\u9700\u6C42 \u2192 \u667A\u80FD\u5339\u914D \u2192 \u8FC7\u7A0B\u7BA1\u63A7 \u2192 \u62C5\u4FDD\u4EA4\u4ED8", options: { fontSize: 16, color: C.accent } },
  ], {
    x: 1.1, y: 3.15, w: 7.8, h: 1.2, fontFace: "Calibri", margin: 0, valign: "middle"
  });
  addFooter(slide, 9, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 11: 全流程价值嵌入
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addText("\u5168\u6D41\u7A0B\u4EF7\u503C\u5D4C\u5165", {
    x: 0.8, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText("\u6BCF\u4E00\u4E2A\u73AF\u8282\u90FD\u4F9D\u8D56\u5E73\u53F0\u5DE5\u5177\uFF0C\u8DF3\u5355\u7684\u4EE3\u4EF7\u8FDC\u9AD8\u4E8E 5-7% \u7BA1\u7406\u8D39", {
    x: 0.8, y: 0.8, w: 8.5, h: 0.35,
    fontSize: 12, fontFace: "Calibri", color: C.accent, italic: true, margin: 0
  });

  const flowSteps = [
    { step: "01", title: "AI \u9700\u6C42\u5206\u6790", desc: "\u5927\u767D\u8BDD \u2192 \u7ED3\u6784\u5316 PRD + EARS \u5361\u7247", solve: "\u89E3\u51B3\u201C\u8BF4\u4E0D\u6E05\u201D", color: C.accent },
    { step: "02", title: "AI \u667A\u80FD\u64AE\u5408", desc: "\u4E94\u7EF4\u52A0\u6743\u5339\u914D \u2192 \u63A8\u8350\u6700\u5408\u9002\u56E2\u961F", solve: "\u89E3\u51B3\u201C\u627E\u4EBA\u96BE\u201D", color: C.accent },
    { step: "03", title: "AI \u9879\u76EE\u7BA1\u7406", desc: "\u91CC\u7A0B\u7891\u62C6\u89E3 + \u5EF6\u671F\u9884\u8B66 + \u6BCF\u65E5\u7B80\u62A5", solve: "\u89E3\u51B3\u201C\u7BA1\u4E0D\u4E86\u201D", color: C.orange },
    { step: "04", title: "\u62C5\u4FDD\u4EA4\u6613", desc: "3:3:4 \u5206\u9636\u6BB5\u4ED8\u6B3E + \u8D44\u91D1\u62C5\u4FDD", solve: "\u89E3\u51B3\u201C\u6015\u88AB\u5751\u201D", color: C.orange },
    { step: "05", title: "AI \u8D28\u91CF\u9A8C\u6536", desc: "\u6C99\u7BB1\u9A8C\u8BC1 + AI \u9884\u68C0 + EARS \u5BF9\u7167\u9A8C\u6536", solve: "\u89E3\u51B3\u201C\u9A8C\u6536\u96BE\u201D", color: C.accent },
    { step: "06", title: "\u4FE1\u7528\u6C89\u6DC0", desc: "\u53CC\u5411\u8BC4\u4EF7 \u2192 vc-T \u7B49\u7EA7\u4F53\u7CFB \u2192 \u4FE1\u7528\u8D44\u4EA7", solve: "\u89E3\u51B3\u201C\u65E0\u4FE1\u7528\u201D", color: C.accent },
  ];

  for (let i = 0; i < 6; i++) {
    const y = 1.3 + i * 0.68;
    slide.addShape("oval", {
      x: 0.5, y: y + 0.05, w: 0.45, h: 0.45,
      fill: { color: flowSteps[i].color }
    });
    slide.addText(flowSteps[i].step, {
      x: 0.5, y: y + 0.05, w: 0.45, h: 0.45,
      fontSize: 12, fontFace: "Calibri", color: C.bgDark, bold: true,
      align: "center", valign: "middle", margin: 0
    });
    if (i < 5) {
      slide.addShape("line", {
        x: 0.725, y: y + 0.5, w: 0, h: 0.23,
        line: { color: C.divider, width: 1.5 }
      });
    }
    slide.addText(flowSteps[i].title, {
      x: 1.15, y: y, w: 2.0, h: 0.35,
      fontSize: 14, fontFace: "Georgia", color: C.white, bold: true, margin: 0
    });
    slide.addText(flowSteps[i].desc, {
      x: 3.2, y: y, w: 4.2, h: 0.35,
      fontSize: 12, fontFace: "Calibri", color: C.muted, margin: 0, valign: "middle"
    });
    slide.addText(flowSteps[i].solve, {
      x: 7.8, y: y, w: 1.7, h: 0.35,
      fontSize: 11, fontFace: "Calibri", color: flowSteps[i].color, margin: 0, valign: "middle", align: "right"
    });
  }
  addFooter(slide, 10, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 12: 竞争对比
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addText("\u4E3A\u4EC0\u4E48\u9009\u5F00\u9020\uFF1F", {
    x: 0.8, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  const tableX = 0.5, tableY = 1.0;
  const colW = [1.8, 2.2, 2.2, 2.8];
  const headers = ["\u7EF4\u5EA6", "\u732A\u516B\u6212/\u5BA2\u6808", "Upwork/Fiverr", "\u5F00\u9020 KAIZO"];

  for (let c = 0; c < 4; c++) {
    let xPos = tableX;
    for (let j = 0; j < c; j++) xPos += colW[j];
    slide.addShape("rectangle", {
      x: xPos, y: tableY, w: colW[c], h: 0.45,
      fill: { color: c === 3 ? C.accent : C.bgCard }
    });
    slide.addText(headers[c], {
      x: xPos, y: tableY, w: colW[c], h: 0.45,
      fontSize: 11, fontFace: "Calibri", color: c === 3 ? C.bgDark : C.white,
      bold: true, align: "center", valign: "middle", margin: 0
    });
  }

  const rows = [
    ["AI \u80FD\u529B", "\u65E0", "\u57FA\u7840\u5206\u7C7B", "\u4E09\u5927 Agent \u5168\u6D41\u7A0B"],
    ["\u9700\u6C42\u5BF9\u9F50", "\u7528\u6237\u81EA\u884C\u63CF\u8FF0", "\u7528\u6237\u81EA\u884C\u63CF\u8FF0", "AI \u751F\u6210 PRD + EARS"],
    ["\u5339\u914D\u65B9\u5F0F", "\u4EBA\u5DE5\u6D4F\u89C8", "\u57FA\u7840\u63A8\u8350", "\u4E94\u7EF4 AI \u667A\u80FD\u5339\u914D"],
    ["\u9632\u8DF3\u5355", "\u5F31", "\u4E2D\u7B49", "\u5F3A\uFF08\u5168\u6D41\u7A0B\u5DE5\u5177\u5D4C\u5165\uFF09"],
    ["\u8D28\u91CF\u4FDD\u969C", "\u57FA\u7840\u62C5\u4FDD", "\u8BA2\u5355\u4FDD\u62A4", "AI \u8D28\u68C0+\u6C99\u7BB1+EARS"],
    ["\u670D\u52A1\u54C1\u7C7B", "\u4F20\u7EDF\u5916\u5305", "\u5168\u7403\u81EA\u7531\u804C\u4E1A", "Vibe Coding+AI Skill"],
    ["\u7BA1\u7406\u8D39", "15-20%", "10-25%", "5-7%"],
  ];

  for (let r = 0; r < rows.length; r++) {
    const rowY = tableY + 0.45 + r * 0.5;
    for (let c = 0; c < 4; c++) {
      let xPos = tableX;
      for (let j = 0; j < c; j++) xPos += colW[j];
      slide.addShape("rectangle", {
        x: xPos, y: rowY, w: colW[c], h: 0.5,
        fill: { color: r % 2 === 0 ? C.bgCard : C.bgMedium }
      });
      slide.addText(rows[r][c], {
        x: xPos + 0.1, y: rowY, w: colW[c] - 0.2, h: 0.5,
        fontSize: 10, fontFace: "Calibri",
        color: c === 3 ? C.accent : (c === 0 ? C.white : C.muted),
        bold: c === 0 || c === 3, align: "center", valign: "middle", margin: 0
      });
    }
  }

  slide.addText([
    { text: "\u5173\u952E\u5DEE\u5F02\uFF1A", options: { fontSize: 12, color: C.white, bold: true } },
    { text: "\u732A\u516B\u6212\u53EA\u505A\u4E86\u4EA4\u6613\u94FE\u6761\u4E0A\u7684\u4E00\u4E2A\u70B9\uFF08\u4ECB\u7ECD\uFF09\uFF0C\u5F00\u9020\u505A\u7684\u662F\u6574\u6761\u94FE\u3002", options: { fontSize: 12, color: C.accent } },
  ], { x: 0.8, y: 4.8, w: 8.5, h: 0.4, fontFace: "Calibri", margin: 0 });
  addFooter(slide, 11, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 13: 双曲线战略
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addText("\u53CC\u66F2\u7EBF\u6218\u7565", {
    x: 0.8, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText("\u64AE\u5408\u662F\u4ECA\u5929\uFF0C\u53BB\u4E2D\u5FC3\u5316\u670D\u52A1\u662F\u660E\u5929", {
    x: 0.8, y: 0.8, w: 8, h: 0.35,
    fontSize: 13, fontFace: "Calibri", color: C.muted, margin: 0
  });

  // Left: First curve
  slide.addShape("rectangle", {
    x: 0.5, y: 1.3, w: 4.3, h: 3.8,
    fill: { color: C.bgCard }, shadow: makeCardShadow()
  });
  slide.addShape("rectangle", {
    x: 0.5, y: 1.3, w: 4.3, h: 0.06, fill: { color: C.accent }
  });
  slide.addText("\u7B2C\u4E00\u66F2\u7EBF", {
    x: 0.7, y: 1.5, w: 3.8, h: 0.35,
    fontSize: 11, fontFace: "Calibri", color: C.accent, charSpacing: 4, margin: 0
  });
  slide.addText("AI \u9A71\u52A8\u7684\u670D\u52A1\u64AE\u5408", {
    x: 0.7, y: 1.85, w: 3.8, h: 0.45,
    fontSize: 18, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText([
    { text: "\u9700\u6C42\u65B9\uFF1A", options: { bold: true, color: C.white, fontSize: 12, breakLine: true } },
    { text: "\u5C0F\u5FAE\u521B\u4E1A\u8005\u3001\u4E00\u4EBA\u516C\u53F8\u3001\u5C0F\u4F01\u4E1A\u4E3B", options: { color: C.muted, fontSize: 11, breakLine: true } },
    { text: "\u5BA2\u5355\u4EF7 \u00A5500 - 20,000", options: { color: C.muted, fontSize: 11, breakLine: true } },
    { text: "", options: { fontSize: 6, breakLine: true } },
    { text: "\u4F9B\u7ED9\u65B9\uFF1A", options: { bold: true, color: C.white, fontSize: 12, breakLine: true } },
    { text: "Vibe Coder\u3001\u4F20\u7EDF\u7A0B\u5E8F\u5458+AI\u3001\u8BBE\u8BA1\u5E08\u8F6C\u578B", options: { color: C.muted, fontSize: 11, breakLine: true } },
    { text: "", options: { fontSize: 6, breakLine: true } },
    { text: "\u6838\u5FC3\u6A21\u5F0F\uFF1A", options: { bold: true, color: C.white, fontSize: 12, breakLine: true } },
    { text: "\u53D1\u9700\u6C42 \u2192 AI\u62C6\u89E3 \u2192 \u667A\u80FD\u5339\u914D \u2192 \u62C5\u4FDD\u4EA4\u4ED8", options: { color: C.accent, fontSize: 12 } },
  ], { x: 0.7, y: 2.5, w: 3.8, h: 2.4, fontFace: "Calibri", margin: 0 });

  // Right: Second curve
  slide.addShape("rectangle", {
    x: 5.2, y: 1.3, w: 4.3, h: 3.8,
    fill: { color: C.bgCard }, shadow: makeCardShadow()
  });
  slide.addShape("rectangle", {
    x: 5.2, y: 1.3, w: 4.3, h: 0.06, fill: { color: C.orange }
  });
  slide.addText("\u7B2C\u4E8C\u66F2\u7EBF", {
    x: 5.4, y: 1.5, w: 3.8, h: 0.35,
    fontSize: 11, fontFace: "Calibri", color: C.orange, charSpacing: 4, margin: 0
  });
  slide.addText("\u53BB\u4E2D\u5FC3\u5316\u4F01\u4E1A\u670D\u52A1", {
    x: 5.4, y: 1.85, w: 3.8, h: 0.45,
    fontSize: 18, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText([
    { text: "\u4F01\u4E1A\u80FD\u529B API \u5316", options: { bold: true, color: C.white, fontSize: 12, breakLine: true } },
    { text: "\u6570\u636E\u6E05\u6D17\u3001\u5B89\u5168\u5BA1\u8BA1\u7B49\u80FD\u529B\u6309\u9700\u8C03\u7528", options: { color: C.muted, fontSize: 11, breakLine: true } },
    { text: "", options: { fontSize: 6, breakLine: true } },
    { text: "AI Agent Skill \u5546\u4E1A\u5316", options: { bold: true, color: C.white, fontSize: 12, breakLine: true } },
    { text: "\u5B9A\u5236\u64AE\u5408 + \u96C6\u6210\u90E8\u7F72 + \u8D28\u91CF\u8BA4\u8BC1", options: { color: C.muted, fontSize: 11, breakLine: true } },
    { text: "", options: { fontSize: 6, breakLine: true } },
    { text: "\u4E91\u5E73\u53F0 & \u5927\u6A21\u578B\u5206\u53D1", options: { bold: true, color: C.white, fontSize: 12, breakLine: true } },
    { text: "\u6C99\u7BB1\u73AF\u5883 + \u4E00\u952E\u5207\u6362\u5927\u6A21\u578B + \u6E20\u9053\u8FD4\u4F63", options: { color: C.muted, fontSize: 11, breakLine: true } },
    { text: "", options: { fontSize: 6, breakLine: true } },
    { text: "TAM \u4ECE \u00A53,000\u4EBF \u2192 \u6574\u4E2A API \u7ECF\u6D4E", options: { color: C.orange, fontSize: 12, bold: true } },
  ], { x: 5.4, y: 2.5, w: 3.8, h: 2.4, fontFace: "Calibri", margin: 0 });
  addFooter(slide, 12, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 14: 生态愿景
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addImage({ data: icons.globeW, x: 0.8, y: 0.35, w: 0.35, h: 0.35 });
  slide.addText("\u7EC8\u6781\u613F\u666F\uFF1A\u5168\u7403\u8D85\u7EA7\u4E2A\u4F53\u521B\u4E1A\u8005\u751F\u6001", {
    x: 1.25, y: 0.3, w: 8, h: 0.5,
    fontSize: 20, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  const nodeTypes = [
    { icon: "usersW", label: "\u4EBA", sub: "Vibe Coder\n\u8BBE\u8BA1\u5E08\n\u4EA7\u54C1\u7ECF\u7406", x: 0.7, color: C.accent },
    { icon: "robotW", label: "AI Agent", sub: "OpenClaw Skill\n\u81EA\u52A8\u5316\u5DE5\u4F5C\u6D41", x: 3.7, color: C.accent },
    { icon: "cogsW", label: "\u4F01\u4E1A\u80FD\u529B", sub: "\u6570\u636E\u6E05\u6D17\n\u5B89\u5168\u5BA1\u8BA1\nAPI\u670D\u52A1", x: 6.7, color: C.orange },
  ];

  for (const nt of nodeTypes) {
    slide.addShape("rectangle", {
      x: nt.x, y: 1.05, w: 2.6, h: 1.75,
      fill: { color: C.bgCard }, shadow: makeCardShadow()
    });
    slide.addShape("rectangle", {
      x: nt.x, y: 1.05, w: 2.6, h: 0.05, fill: { color: nt.color }
    });
    slide.addImage({ data: icons[nt.icon], x: nt.x + 1.05, y: 1.2, w: 0.4, h: 0.4 });
    slide.addText(nt.label, {
      x: nt.x, y: 1.65, w: 2.6, h: 0.35,
      fontSize: 14, fontFace: "Georgia", color: C.white, bold: true, align: "center", margin: 0
    });
    slide.addText(nt.sub, {
      x: nt.x + 0.2, y: 2.05, w: 2.2, h: 0.65,
      fontSize: 10, fontFace: "Calibri", color: C.muted, align: "center", margin: 0
    });
  }

  // Arrows & Token layer
  slide.addShape("line", { x: 2.0, y: 2.8, w: 3, h: 0.5, line: { color: C.accent, width: 1.5 } });
  slide.addShape("line", { x: 8.0, y: 2.8, w: -3, h: 0.5, line: { color: C.accent, width: 1.5 } });
  slide.addShape("line", { x: 5.0, y: 2.8, w: 0, h: 0.5, line: { color: C.accent, width: 1.5 } });

  slide.addShape("rectangle", {
    x: 1.5, y: 3.3, w: 7.0, h: 0.7, fill: { color: C.accentDim }
  });
  slide.addText("Token \u4EF7\u503C\u6D41\u8F6C\u5C42  \u00B7  \u8D21\u732E \u2192 Token \u2192 \u6D88\u8D39", {
    x: 1.5, y: 3.3, w: 7.0, h: 0.7,
    fontSize: 14, fontFace: "Calibri", color: C.white, bold: true,
    align: "center", valign: "middle", margin: 0
  });

  slide.addShape("line", { x: 5.0, y: 4.0, w: 0, h: 0.4, line: { color: C.accent, width: 1.5 } });
  slide.addShape("rectangle", {
    x: 2.0, y: 4.4, w: 6.0, h: 0.65, fill: { color: C.bgCard }
  });
  slide.addText("\u9700\u6C42\u65B9  \u00B7  \u9879\u76EE\u65B9 / \u4F01\u4E1A / \u4E00\u4EBA\u516C\u53F8", {
    x: 2.0, y: 4.4, w: 6.0, h: 0.65,
    fontSize: 13, fontFace: "Calibri", color: C.muted, align: "center", valign: "middle", margin: 0
  });

  slide.addText("\u4EBA\u548C AI Agent \u662F\u5E73\u7B49\u7684\u670D\u52A1\u63D0\u4F9B\u8005 \u2014 \u9700\u6C42\u65B9\u53EA\u5173\u5FC3\u7ED3\u679C\u8FBE\u6807", {
    x: 0.5, y: 5.15, w: 9, h: 0.3,
    fontSize: 11, fontFace: "Calibri", color: C.accent, italic: true, align: "center", margin: 0
  });
  addFooter(slide, 13, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 15: 核心壁垒
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addImage({ data: icons.lockW, x: 0.8, y: 0.35, w: 0.35, h: 0.35 });
  slide.addText("\u4E94\u5C42\u58C1\u5792 \u00B7 \u4E0D\u53EF\u590D\u5236", {
    x: 1.25, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText("\u5355\u62FF\u4E00\u4E2A\u51FA\u6765\u90FD\u80FD\u88AB\u6284\uFF0C\u4F46\u540C\u65F6\u590D\u5236\u4E94\u4E2A\u4E14\u90FD\u9700\u8981\u65F6\u95F4\u6C89\u6DC0 \u2014 \u8FD9\u5C31\u662F\u4E0D\u53EF\u590D\u5236\u6027", {
    x: 0.8, y: 0.85, w: 8.5, h: 0.35,
    fontSize: 12, fontFace: "Calibri", color: C.muted, italic: true, margin: 0
  });

  const barriers = [
    { title: "AI \u64AE\u5408\u5F15\u64CE", desc: "\u6BCF\u6B21\u5339\u914D\u8BAD\u7EC3\u6A21\u578B\uFF0C\u8D8A\u7528\u8D8A\u51C6", time: "6-12\u6708", icon: "brainW" },
    { title: "\u4EA4\u6613\u6570\u636E\u98DE\u8F6E", desc: "\u6570\u636E\u8D8A\u591A\u2192\u5339\u914D\u8D8A\u51C6\u2192\u6210\u4EA4\u8D8A\u591A", time: "12-18\u6708", icon: "chartW" },
    { title: "\u4FE1\u7528\u8D44\u4EA7\u9501\u5B9A", desc: "vc-T \u4F53\u7CFB\uFF0C\u8FC1\u79FB\u6210\u672C\u6781\u9AD8", time: "12+\u6708", icon: "lockW" },
    { title: "\u5168\u6D41\u7A0B\u5DE5\u5177\u94FE", desc: "\u9879\u76EE\u8D44\u4EA7\u3001\u5386\u53F2\u6570\u636E\u5168\u5728\u5E73\u53F0", time: "6-12\u6708", icon: "cogsW" },
    { title: "\u751F\u6001\u7ED1\u5B9A", desc: "OpenClaw \u5B98\u65B9\u5546\u4E1A\u5316\u5408\u4F5C", time: "6-12\u6708", icon: "globeW" },
  ];

  for (let i = 0; i < 5; i++) {
    const y = 1.35 + i * 0.82;
    slide.addShape("rectangle", {
      x: 0.5, y, w: 9.0, h: 0.7,
      fill: { color: i % 2 === 0 ? C.bgCard : C.bgMedium }
    });
    slide.addShape("oval", {
      x: 0.7, y: y + 0.12, w: 0.4, h: 0.4, fill: { color: C.accent }
    });
    slide.addText(`${i + 1}`, {
      x: 0.7, y: y + 0.12, w: 0.4, h: 0.4,
      fontSize: 14, fontFace: "Georgia", color: C.bgDark, bold: true,
      align: "center", valign: "middle", margin: 0
    });
    slide.addImage({ data: icons[barriers[i].icon], x: 1.3, y: y + 0.15, w: 0.35, h: 0.35 });
    slide.addText(barriers[i].title, {
      x: 1.8, y: y + 0.05, w: 2.5, h: 0.3,
      fontSize: 14, fontFace: "Georgia", color: C.white, bold: true, margin: 0
    });
    slide.addText(barriers[i].desc, {
      x: 1.8, y: y + 0.35, w: 4, h: 0.3,
      fontSize: 11, fontFace: "Calibri", color: C.muted, margin: 0
    });
    slide.addText(barriers[i].time, {
      x: 7.5, y: y, w: 1.8, h: 0.65,
      fontSize: 12, fontFace: "Calibri", color: C.accent, align: "right", valign: "middle", margin: 0
    });
  }
  addFooter(slide, 14, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 16: 市场规模
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addText("\u5E02\u573A\u89C4\u6A21", {
    x: 0.8, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  const markets = [
    { label: "TAM", value: "\u00A5600\u4EBF+", desc: "\u5168\u7403 AI \u7F16\u7A0B +\n\u4F01\u4E1A\u670D\u52A1 API \u7ECF\u6D4E", color: C.accent },
    { label: "SAM", value: "\u00A5120-150\u4EBF", desc: "\u4E2D\u56FD AI \u8F85\u52A9\u8F6F\u4EF6\u5F00\u53D1\n+ \u6570\u636E\u670D\u52A1", color: C.accent },
    { label: "SOM", value: "\u00A53-5\u4EBF", desc: "\u5F00\u9020 3 \u5E74\u53EF\u89E6\u8FBE", color: C.orange },
  ];

  for (let i = 0; i < 3; i++) {
    const x = 0.5 + i * 3.15;
    slide.addShape("rectangle", {
      x, y: 1.0, w: 2.9, h: 2.3,
      fill: { color: C.bgCard }, shadow: makeCardShadow()
    });
    slide.addShape("rectangle", {
      x, y: 1.0, w: 2.9, h: 0.06, fill: { color: markets[i].color }
    });
    slide.addText(markets[i].label, {
      x, y: 1.2, w: 2.9, h: 0.35,
      fontSize: 13, fontFace: "Calibri", color: markets[i].color, charSpacing: 4,
      align: "center", margin: 0
    });
    slide.addText(markets[i].value, {
      x, y: 1.6, w: 2.9, h: 0.65,
      fontSize: 30, fontFace: "Georgia", color: C.white, bold: true, align: "center", margin: 0
    });
    slide.addText(markets[i].desc, {
      x: x + 0.2, y: 2.3, w: 2.5, h: 0.8,
      fontSize: 11, fontFace: "Calibri", color: C.muted, align: "center", margin: 0
    });
  }

  slide.addText("\u4E2D\u56FD\u5E02\u573A\u4E09\u5927\u7A7A\u767D", {
    x: 0.8, y: 3.6, w: 8, h: 0.4,
    fontSize: 16, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  const gaps = [
    { gap: "Vibe Coder \u63A5\u5355\u5E73\u53F0", status: "\u732A\u516B\u6212/\u5BA2\u6808\u5C1A\u672A\u8DDF\u8FDB" },
    { gap: "AI Agent Skill \u5546\u4E1A\u5316", status: "\u5B8C\u5168\u7A7A\u767D" },
    { gap: "\u4F01\u4E1A\u80FD\u529B API \u5316\u5E73\u53F0", status: "\u5B8C\u5168\u7A7A\u767D" },
  ];

  for (let i = 0; i < 3; i++) {
    const x = 0.5 + i * 3.15;
    slide.addShape("rectangle", {
      x, y: 4.15, w: 2.9, h: 0.9, fill: { color: C.bgCard }
    });
    slide.addText(gaps[i].gap, {
      x: x + 0.15, y: 4.2, w: 2.6, h: 0.35,
      fontSize: 12, fontFace: "Calibri", color: C.white, bold: true, margin: 0
    });
    slide.addText(gaps[i].status, {
      x: x + 0.15, y: 4.55, w: 2.6, h: 0.35,
      fontSize: 11, fontFace: "Calibri", color: C.orange, margin: 0
    });
  }
  addFooter(slide, 15, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 17: 财务预测
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addText("\u8D22\u52A1\u9884\u6D4B\u4E0E\u878D\u8D44", {
    x: 0.8, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  // Left: projections
  slide.addShape("rectangle", {
    x: 0.5, y: 1.0, w: 5.5, h: 4.0,
    fill: { color: C.bgCard }, shadow: makeCardShadow()
  });
  slide.addText("\u4E09\u5E74\u6536\u5165\u9884\u6D4B", {
    x: 0.7, y: 1.15, w: 5, h: 0.35,
    fontSize: 14, fontFace: "Georgia", color: C.accent, bold: true, margin: 0
  });

  const finHeaders = ["", "Y1", "Y2", "Y3"];
  const finRows = [
    ["\u6CE8\u518C\u7528\u6237", "10\u4E07", "40\u4E07", "100\u4E07"],
    ["\u5E74 GMV", "\u00A51,500\u4E07", "\u00A59,000\u4E07", "\u00A53.6\u4EBF"],
    ["\u5E73\u53F0\u603B\u6536\u5165", "\u00A5238\u4E07", "\u00A52,050\u4E07", "\u00A58,700\u4E07"],
    ["\u589E\u957F\u7387", "\u2014", "761%", "324%"],
  ];

  for (let c = 0; c < 4; c++) {
    const hx = 0.7 + c * 1.25;
    slide.addShape("rectangle", {
      x: hx, y: 1.65, w: 1.25, h: 0.35,
      fill: { color: c === 0 ? C.bgCard : C.bgMedium }
    });
    slide.addText(finHeaders[c], {
      x: hx, y: 1.65, w: 1.25, h: 0.35,
      fontSize: 11, fontFace: "Calibri", color: c > 0 ? C.accent : C.white,
      bold: true, align: "center", valign: "middle", margin: 0
    });
  }
  for (let r = 0; r < finRows.length; r++) {
    for (let c = 0; c < 4; c++) {
      const cx = 0.7 + c * 1.25;
      const ry = 2.0 + r * 0.45;
      slide.addText(finRows[r][c], {
        x: cx, y: ry, w: 1.25, h: 0.4,
        fontSize: c === 0 ? 10 : 11, fontFace: "Calibri",
        color: r === 2 ? C.white : (r === 3 ? C.accent : C.muted),
        bold: r === 2 || r === 3,
        align: c === 0 ? "left" : "center", valign: "middle", margin: 0
      });
    }
  }

  slide.addText("\u5355\u4F4D\u7ECF\u6D4E", {
    x: 0.7, y: 3.7, w: 5, h: 0.35,
    fontSize: 13, fontFace: "Georgia", color: C.accent, bold: true, margin: 0
  });
  const unitEcon = [
    ["\u5BA2\u5355\u4EF7 \u00A51,500", "\u7BA1\u7406\u8D39 5-7%", "\u6BDB\u5229\u7387 70-80%"],
    ["LTV:CAC 12-20:1", "CAC \u00A530-50", "\u76C8\u4E8F\u5E73\u8861 M9-M10"],
  ];
  for (let r = 0; r < 2; r++) {
    for (let c = 0; c < 3; c++) {
      slide.addText(unitEcon[r][c], {
        x: 0.7 + c * 1.7, y: 4.1 + r * 0.35, w: 1.6, h: 0.3,
        fontSize: 10, fontFace: "Calibri", color: C.muted, margin: 0
      });
    }
  }

  // Right: funding
  slide.addShape("rectangle", {
    x: 6.3, y: 1.0, w: 3.2, h: 4.0,
    fill: { color: C.bgCard }, shadow: makeCardShadow()
  });
  slide.addShape("rectangle", {
    x: 6.3, y: 1.0, w: 3.2, h: 0.06, fill: { color: C.orange }
  });
  slide.addText("\u878D\u8D44\u9700\u6C42", {
    x: 6.5, y: 1.2, w: 2.8, h: 0.35,
    fontSize: 14, fontFace: "Georgia", color: C.orange, bold: true, margin: 0
  });
  slide.addText("\u00A5500-800\u4E07", {
    x: 6.3, y: 1.65, w: 3.2, h: 0.6,
    fontSize: 28, fontFace: "Georgia", color: C.white, bold: true, align: "center", margin: 0
  });
  slide.addText("\u5929\u4F7F\u8F6E / Pre-A", {
    x: 6.3, y: 2.25, w: 3.2, h: 0.35,
    fontSize: 12, fontFace: "Calibri", color: C.muted, align: "center", margin: 0
  });
  slide.addShape("rectangle", {
    x: 6.5, y: 2.7, w: 2.8, h: 0.04, fill: { color: C.divider }
  });

  const fundDetails = [
    { label: "\u51FA\u8BA9\u80A1\u4EFD", value: "10-15%" },
    { label: "\u4F30\u503C", value: "\u00A54,000-6,000\u4E07" },
    { label: "\u4EA7\u54C1\u7814\u53D1", value: "45%" },
    { label: "\u5E02\u573A\u63A8\u5E7F", value: "25%" },
    { label: "\u56E2\u961F\u5EFA\u8BBE", value: "20%" },
    { label: "\u8FD0\u8425\u50A8\u5907", value: "10%" },
  ];
  for (let i = 0; i < fundDetails.length; i++) {
    const fy = 2.85 + i * 0.3;
    slide.addText(fundDetails[i].label, {
      x: 6.5, y: fy, w: 1.5, h: 0.25,
      fontSize: 10, fontFace: "Calibri", color: C.muted, margin: 0
    });
    slide.addText(fundDetails[i].value, {
      x: 8.0, y: fy, w: 1.3, h: 0.25,
      fontSize: 10, fontFace: "Calibri", color: C.white, bold: true, align: "right", margin: 0
    });
  }
  slide.addShape("rectangle", {
    x: 6.5, y: 4.3, w: 2.8, h: 0.5, fill: { color: C.bgMedium }
  });
  slide.addText([
    { text: "12\u4E2A\u6708\u76EE\u6807\uFF1A", options: { fontSize: 10, color: C.accent, bold: true, breakLine: true } },
    { text: "10\u4E07\u7528\u6237 \u00B7 \u6708GMV \u00A5300\u4E07", options: { fontSize: 10, color: C.muted } },
  ], { x: 6.6, y: 4.35, w: 2.6, h: 0.4, fontFace: "Calibri", margin: 0 });
  addFooter(slide, 16, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 17: 为什么是现在
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  addDarkSlideBase(slide);

  slide.addImage({ data: icons.flag, x: 0.8, y: 0.35, w: 0.35, h: 0.35 });
  slide.addText("\u4E3A\u4EC0\u4E48\u662F\u73B0\u5728\uFF1F", {
    x: 1.25, y: 0.3, w: 7, h: 0.5,
    fontSize: 22, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  slide.addText("\u7A97\u53E3\u671F\u6709\u9650\uFF1A12-18 \u4E2A\u6708", {
    x: 0.8, y: 0.85, w: 8, h: 0.35,
    fontSize: 13, fontFace: "Calibri", color: C.orange, italic: true, margin: 0
  });

  const reasons = [
    { num: "01", title: "\u6280\u672F\u62D0\u70B9\u5DF2\u5230", desc: "AI Coding \u5DE5\u5177\u6210\u719F\u5EA6\u8FC7\u4E34\u754C\u70B9\uFF0C\u4E0D\u662F\u80FD\u4E0D\u80FD\u7528\uFF0C\u800C\u662F\u8C01\u5148\u5EFA\u751F\u6001" },
    { num: "02", title: "\u4F9B\u7ED9\u7AEF\u5C31\u7EEA", desc: "\u5927\u91CF AI \u539F\u751F\u5F00\u53D1\u8005\u5DF2\u51FA\u73B0\uFF0C\u4F46\u7F3A\u83B7\u5BA2\u6E20\u9053" },
    { num: "03", title: "\u9700\u6C42\u7AEF\u89C9\u9192", desc: "\u5C0F\u7EA2\u4E66\u5927\u91CF\u201CAI \u7F16\u7A0B\u63A5\u5355\u201D\u5185\u5BB9\uFF0C\u53CC\u7AEF\u540C\u65F6\u7206\u53D1" },
    { num: "04", title: "\u7ADE\u54C1\u672A\u52A8", desc: "\u732A\u516B\u6212/\u5BA2\u6808\u8FD8\u5728\u4F20\u7EDF\u6A21\u5F0F\uFF0C\u56FD\u9645\u5E73\u53F0\u4E0D\u652F\u6301\u4E2D\u56FD\u5408\u89C4" },
    { num: "05", title: "\u751F\u6001\u7A97\u53E3", desc: "OpenClaw \u751F\u6001\u5FEB\u901F\u6210\u578B\u4F46\u5546\u4E1A\u5316\u7A7A\u767D\uFF0C\u5148\u53D1\u5408\u4F5C\u8005\u6709\u72EC\u5360\u4F18\u52BF" },
  ];

  for (let i = 0; i < 5; i++) {
    const y = 1.35 + i * 0.82;
    slide.addShape("rectangle", {
      x: 0.5, y, w: 9.0, h: 0.7,
      fill: { color: i % 2 === 0 ? C.bgCard : C.bgMedium }
    });
    slide.addShape("oval", {
      x: 0.7, y: y + 0.12, w: 0.42, h: 0.42, fill: { color: C.accent }
    });
    slide.addText(reasons[i].num, {
      x: 0.7, y: y + 0.12, w: 0.42, h: 0.42,
      fontSize: 12, fontFace: "Georgia", color: C.bgDark, bold: true,
      align: "center", valign: "middle", margin: 0
    });
    slide.addText(reasons[i].title, {
      x: 1.3, y: y + 0.05, w: 2.5, h: 0.3,
      fontSize: 14, fontFace: "Georgia", color: C.white, bold: true, margin: 0
    });
    slide.addText(reasons[i].desc, {
      x: 1.3, y: y + 0.35, w: 7.8, h: 0.3,
      fontSize: 12, fontFace: "Calibri", color: C.muted, margin: 0
    });
  }
  addFooter(slide, 17, TOTAL);

  // ════════════════════════════════════════════════════════════
  // SLIDE 18: 结束页
  // ════════════════════════════════════════════════════════════
  slide = pres.addSlide();
  slide.background = { color: C.bgDark };

  slide.addShape("oval", {
    x: -1, y: -1, w: 3, h: 3,
    fill: { color: C.accent, transparency: 92 }
  });
  slide.addShape("oval", {
    x: 8, y: 3.5, w: 3, h: 3,
    fill: { color: C.accent, transparency: 92 }
  });

  slide.addText("\u5F00\u9020 KAIZO", {
    x: 0.5, y: 0.8, w: 9, h: 0.9,
    fontSize: 42, fontFace: "Georgia", color: C.white, bold: true, align: "center", margin: 0
  });
  slide.addShape("rectangle", {
    x: 4.3, y: 1.8, w: 1.4, h: 0.04, fill: { color: C.accent }
  });
  slide.addText("AI \u65F6\u4EE3\u7684\u670D\u52A1\u4EA4\u6613\u57FA\u7840\u8BBE\u65BD", {
    x: 1, y: 2.0, w: 8, h: 0.6,
    fontSize: 18, fontFace: "Calibri", color: C.accent, align: "center", margin: 0
  });

  slide.addShape("rectangle", {
    x: 1.2, y: 2.8, w: 7.6, h: 1.6,
    fill: { color: C.bgCard }, shadow: makeCardShadow()
  });
  slide.addText([
    { text: "\u7528 AI Agent \u6D88\u9664\u4FE1\u606F\u5DEE", options: { fontSize: 16, color: C.white, breakLine: true } },
    { text: "\u7528 Token \u79EF\u5206\u9A71\u52A8\u4EF7\u503C\u5FAA\u73AF", options: { fontSize: 16, color: C.white, breakLine: true } },
    { text: "\u8BA9\u4EBA\u3001Agent\u3001\u4F01\u4E1A\u80FD\u529B", options: { fontSize: 16, color: C.muted, breakLine: true } },
    { text: "\u5728\u540C\u4E00\u4E2A\u751F\u6001\u91CC\u81EA\u7531\u6D41\u8F6C\u3001\u6309\u9700\u8C03\u7528", options: { fontSize: 16, color: C.accent, bold: true } },
  ], {
    x: 1.5, y: 2.95, w: 7, h: 1.3, fontFace: "Calibri", align: "center", margin: 0
  });

  slide.addText("\u611F\u8C22\u804A\u542C \u00B7 \u671F\u5F85\u4EA4\u6D41", {
    x: 1, y: 4.7, w: 8, h: 0.5,
    fontSize: 16, fontFace: "Calibri", color: C.muted, align: "center", margin: 0
  });
  addFooter(slide, 18, TOTAL);

  // ─── Save ───
  const outputPath = process.cwd() + "/开造KAIZO路演-中关村创坛.pptx";
  await pres.writeFile({ fileName: outputPath });
  console.log("Saved to:", outputPath);
}

main().catch(err => { console.error(err); process.exit(1); });
