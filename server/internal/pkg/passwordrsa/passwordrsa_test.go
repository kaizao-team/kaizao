package passwordrsa

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"testing"
)

func TestDecryptPasswordCipher_roundTrip(t *testing.T) {
	priv, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	plain := "ab12CD56"
	cipher, err := rsa.EncryptOAEP(sha256.New(), rand.Reader, &priv.PublicKey, []byte(plain), nil)
	if err != nil {
		t.Fatal(err)
	}
	b64 := base64.StdEncoding.EncodeToString(cipher)
	out, err := DecryptPasswordCipher(priv, b64)
	if err != nil {
		t.Fatal(err)
	}
	if out != plain {
		t.Fatalf("got %q want %q", out, plain)
	}
}
