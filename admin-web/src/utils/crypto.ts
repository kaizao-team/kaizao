/**
 * RSA-OAEP-SHA256 encryption.
 * Uses Web Crypto API in secure contexts (HTTPS/localhost),
 * falls back to JSEncrypt (PKCS1v1.5) on plain HTTP.
 */

import JSEncrypt from 'jsencrypt'

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const lines = pem
    .replace(/-----BEGIN (?:RSA )?PUBLIC KEY-----/, '')
    .replace(/-----END (?:RSA )?PUBLIC KEY-----/, '')
    .replace(/\s+/g, '')
  const binary = atob(lines)
  const buf = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    buf[i] = binary.charCodeAt(i)
  }
  return buf.buffer as ArrayBuffer
}


export async function encryptPassword(
  publicKeyPEM: string,
  plaintext: string,
  publicKeySPKIPEM?: string,
): Promise<string> {
  // Prefer Web Crypto API in secure contexts (HTTPS / localhost)
  if (typeof crypto !== 'undefined' && crypto.subtle) {
    return encryptWithWebCrypto(publicKeyPEM, plaintext)
  }
  // Fallback: JSEncrypt (works on plain HTTP), prefer SPKI PEM
  return encryptWithJSEncrypt(publicKeySPKIPEM || publicKeyPEM, plaintext)
}

function encryptWithJSEncrypt(publicKeyPEM: string, plaintext: string): string {
  const encrypt = new JSEncrypt()
  encrypt.setPublicKey(publicKeyPEM)
  const result = encrypt.encrypt(plaintext)
  if (!result) {
    throw new Error('RSA encryption failed')
  }
  return result
}

async function encryptWithWebCrypto(
  publicKeyPEM: string,
  plaintext: string,
): Promise<string> {
  const keyData = pemToArrayBuffer(publicKeyPEM)

  let cryptoKey: CryptoKey
  try {
    cryptoKey = await crypto.subtle.importKey(
      'spki',
      keyData,
      { name: 'RSA-OAEP', hash: 'SHA-256' },
      false,
      ['encrypt'],
    )
  } catch {
    const spkiData = wrapPkcs1InSpki(new Uint8Array(keyData))
    cryptoKey = await crypto.subtle.importKey(
      'spki',
      spkiData,
      { name: 'RSA-OAEP', hash: 'SHA-256' },
      false,
      ['encrypt'],
    )
  }

  const encoded = new TextEncoder().encode(plaintext)
  const encrypted = await crypto.subtle.encrypt(
    { name: 'RSA-OAEP' },
    cryptoKey,
    encoded,
  )
  return arrayBufferToBase64(encrypted)
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  let binary = ''
  for (const byte of bytes) {
    binary += String.fromCharCode(byte)
  }
  return btoa(binary)
}

function wrapPkcs1InSpki(pkcs1: Uint8Array): ArrayBuffer {
  const algorithmId = new Uint8Array([
    0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
    0x01, 0x05, 0x00,
  ])

  const bitStringPayload = new Uint8Array(1 + pkcs1.length)
  bitStringPayload[0] = 0x00
  bitStringPayload.set(pkcs1, 1)

  const bitString = encodeDerTLV(0x03, bitStringPayload)

  const spkiPayload = new Uint8Array(algorithmId.length + bitString.length)
  spkiPayload.set(algorithmId)
  spkiPayload.set(bitString, algorithmId.length)

  return encodeDerTLV(0x30, spkiPayload).buffer as ArrayBuffer
}

function encodeDerTLV(tag: number, value: Uint8Array): Uint8Array {
  const len = value.length
  let header: Uint8Array
  if (len < 0x80) {
    header = new Uint8Array([tag, len])
  } else if (len < 0x100) {
    header = new Uint8Array([tag, 0x81, len])
  } else if (len < 0x10000) {
    header = new Uint8Array([tag, 0x82, len >> 8, len & 0xff])
  } else {
    header = new Uint8Array([
      tag,
      0x83,
      (len >> 16) & 0xff,
      (len >> 8) & 0xff,
      len & 0xff,
    ])
  }
  const result = new Uint8Array(header.length + value.length)
  result.set(header)
  result.set(value, header.length)
  return result
}
