import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';

/// RSA-OAEP-SHA256 加密工具
///
/// 用于将用户密码通过服务端下发的 RSA 公钥加密后传输，
/// 避免明文密码在网络中传输。
class RsaCipher {
  RsaCipher._();

  /// 用 PEM 公钥对 [plaintext] 做 RSA-OAEP-SHA256 加密，返回 Base64 密文。
  ///
  /// [publicKeyPem] 为 PKCS#1 或 PKCS#8 格式 PEM 字符串。
  static String encrypt(String plaintext, String publicKeyPem) {
    final publicKey = _parsePublicKeyFromPem(publicKeyPem);
    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    final input = Uint8List.fromList(utf8.encode(plaintext));
    final output = cipher.process(input);
    return base64Encode(output);
  }

  static RSAPublicKey _parsePublicKeyFromPem(String pem) {
    final lines = pem
        .split('\n')
        .where((line) =>
            line.trim().isNotEmpty &&
            !line.startsWith('-----BEGIN') &&
            !line.startsWith('-----END'))
        .join();
    final bytes = base64Decode(lines);
    final parser = ASN1Parser(Uint8List.fromList(bytes));
    final topSequence = parser.nextObject() as ASN1Sequence;

    ASN1Integer modulus;
    ASN1Integer exponent;

    if (topSequence.elements!.length == 2 &&
        topSequence.elements![0] is ASN1Integer) {
      // PKCS#1 format: SEQUENCE { INTEGER modulus, INTEGER exponent }
      modulus = topSequence.elements![0] as ASN1Integer;
      exponent = topSequence.elements![1] as ASN1Integer;
    } else {
      // PKCS#8 / X.509 SubjectPublicKeyInfo format
      final bitString = topSequence.elements![1] as ASN1BitString;
      final innerBytes =
          Uint8List.fromList(bitString.stringValues ?? bitString.valueBytes!);
      final innerParser = ASN1Parser(innerBytes);
      final innerSequence = innerParser.nextObject() as ASN1Sequence;
      modulus = innerSequence.elements![0] as ASN1Integer;
      exponent = innerSequence.elements![1] as ASN1Integer;
    }

    return RSAPublicKey(modulus.integer!, exponent.integer!);
  }
}
