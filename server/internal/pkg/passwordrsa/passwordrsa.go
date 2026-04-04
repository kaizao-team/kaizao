// Package passwordrsa 解析 RSA 私钥并解密客户端以 RSA-OAEP-SHA256 加密的密码密文。
package passwordrsa

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"fmt"
	"os"
	"strings"

	"github.com/vibebuild/server/internal/pkg/errcode"
)

// ParsePrivateKeyFromPEM 从 PEM 字节解析 RSA 私钥。
func ParsePrivateKeyFromPEM(pemBytes []byte) (*rsa.PrivateKey, error) {
	block, _ := pem.Decode(pemBytes)
	if block == nil {
		return nil, fmt.Errorf("no pem block")
	}
	key, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err == nil {
		return key, nil
	}
	k2, err2 := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err2 != nil {
		return nil, fmt.Errorf("parse key: %w", err)
	}
	rk, ok := k2.(*rsa.PrivateKey)
	if !ok {
		return nil, fmt.Errorf("not rsa private key")
	}
	return rk, nil
}

// PublicKeyPEM 导出 PKCS#1 PEM 公钥（供客户端加密）。
func PublicKeyPEM(priv *rsa.PrivateKey) string {
	pubBytes := x509.MarshalPKCS1PublicKey(&priv.PublicKey)
	b := &pem.Block{Type: "RSA PUBLIC KEY", Bytes: pubBytes}
	return string(pem.EncodeToMemory(b))
}

// DecryptPasswordCipher Base64 解码后 RSA-OAEP-SHA256 解密，返回 UTF-8 密码明文。
func DecryptPasswordCipher(priv *rsa.PrivateKey, b64 string) (string, error) {
	b64 = strings.TrimSpace(b64)
	raw, err := base64.StdEncoding.DecodeString(b64)
	if err != nil {
		return "", fmt.Errorf("%d", errcode.ErrPasswordCipherInvalid)
	}
	out, err := rsa.DecryptOAEP(sha256.New(), rand.Reader, priv, raw, nil)
	if err != nil {
		return "", fmt.Errorf("%d", errcode.ErrPasswordCipherInvalid)
	}
	return string(out), nil
}

// LoadPEMBytes 从环境变量 VB_AUTH_PASSWORD_RSA_PRIVATE_KEY_PEM、yaml 字段、或文件路径读取 PEM。
func LoadPEMBytes(yamlPEM, yamlPath string) ([]byte, error) {
	if s := strings.TrimSpace(os.Getenv("VB_AUTH_PASSWORD_RSA_PRIVATE_KEY_PEM")); s != "" {
		return []byte(s), nil
	}
	if yamlPEM != "" {
		return []byte(yamlPEM), nil
	}
	path := strings.TrimSpace(yamlPath)
	if path == "" {
		path = "configs/auth_password_rsa.pem"
	}
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read rsa pem from %s: %w", path, err)
	}
	return b, nil
}

// LoadOrGeneratePrivateKey 优先从 PEM/文件加载；若失败且 VB_AUTH_PASSWORD_DEV_AUTO_KEY=1，则临时生成 2048 位密钥（生产请改为正式 PEM）。
func LoadOrGeneratePrivateKey(yamlPEM, yamlPath string) (*rsa.PrivateKey, error) {
	b, err := LoadPEMBytes(yamlPEM, yamlPath)
	if err == nil && len(strings.TrimSpace(string(b))) > 0 {
		k, perr := ParsePrivateKeyFromPEM(b)
		if perr != nil {
			return nil, perr
		}
		return k, nil
	}
	// 显式 VB_AUTH_PASSWORD_DEV_AUTO_KEY=1 时生成临时密钥（任意 mode）；生产务必改为 PEM/密钥管理。
	if os.Getenv("VB_AUTH_PASSWORD_DEV_AUTO_KEY") == "1" {
		return rsa.GenerateKey(rand.Reader, 2048)
	}
	if err != nil {
		return nil, err
	}
	return nil, fmt.Errorf("auth_password: 未配置 RSA 私钥（configs/auth_password_rsa.pem、yaml auth_password.rsa_private_key_pem 或环境变量 VB_AUTH_PASSWORD_RSA_PRIVATE_KEY_PEM）；开发可设 VB_AUTH_PASSWORD_DEV_AUTO_KEY=1")
}
