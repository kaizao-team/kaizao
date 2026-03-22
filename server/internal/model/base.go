package model

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
)

// JSONB 自定义 JSONB 类型，用于 PostgreSQL JSONB 字段
type JSONB json.RawMessage

func (j JSONB) Value() (driver.Value, error) {
	if len(j) == 0 {
		return "[]", nil
	}
	return string(j), nil
}

func (j *JSONB) Scan(value interface{}) error {
	if value == nil {
		*j = JSONB("[]")
		return nil
	}
	switch v := value.(type) {
	case []byte:
		*j = JSONB(v)
	case string:
		*j = JSONB(v)
	default:
		return errors.New("unsupported type for JSONB")
	}
	return nil
}

func (j JSONB) MarshalJSON() ([]byte, error) {
	if len(j) == 0 {
		return []byte("[]"), nil
	}
	return []byte(j), nil
}

func (j *JSONB) UnmarshalJSON(data []byte) error {
	*j = JSONB(data)
	return nil
}

// JSONBMap JSONB object 类型
type JSONBMap json.RawMessage

func (j JSONBMap) Value() (driver.Value, error) {
	if len(j) == 0 {
		return "{}", nil
	}
	return string(j), nil
}

func (j *JSONBMap) Scan(value interface{}) error {
	if value == nil {
		*j = JSONBMap("{}")
		return nil
	}
	switch v := value.(type) {
	case []byte:
		*j = JSONBMap(v)
	case string:
		*j = JSONBMap(v)
	default:
		return errors.New("unsupported type for JSONBMap")
	}
	return nil
}

func (j JSONBMap) MarshalJSON() ([]byte, error) {
	if len(j) == 0 {
		return []byte("{}"), nil
	}
	return []byte(j), nil
}

func (j *JSONBMap) UnmarshalJSON(data []byte) error {
	*j = JSONBMap(data)
	return nil
}

// GenerateUUID 生成 UUID
func GenerateUUID() string {
	return uuid.New().String()
}

// NowPtr 返回当前时间指针
func NowPtr() *time.Time {
	now := time.Now()
	return &now
}
