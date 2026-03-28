package invitehash

import (
	"crypto/rand"
	"crypto/sha256"
	"fmt"
	"io"
	"strings"
)

const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

// Normalize 统一邀请码格式（去空格、大写）
func Normalize(plain string) string {
	return strings.ToUpper(strings.TrimSpace(plain))
}

// Hash 邀请码明文 -> 入库 hash
func Hash(plain string) string {
	n := Normalize(plain)
	h := sha256.Sum256([]byte(n))
	return fmt.Sprintf("%x", h)
}

// GeneratePlain 生成邀请码明文（前缀 + 随机段）
func GeneratePlain(prefix string) string {
	if prefix == "" {
		prefix = "KZ-"
	}
	raw := make([]byte, 8)
	if _, err := io.ReadFull(rand.Reader, raw); err != nil {
		for i := range raw {
			raw[i] = alphabet[i%len(alphabet)]
		}
	} else {
		for i := range raw {
			raw[i] = alphabet[int(raw[i])%len(alphabet)]
		}
	}
	return prefix + string(raw)
}
