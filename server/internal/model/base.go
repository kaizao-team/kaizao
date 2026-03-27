package model

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
)

// JSON 自定义 JSON 类型，用于 MySQL JSON 字段（数组）
type JSON json.RawMessage

func (j JSON) Value() (driver.Value, error) {
	if len(j) == 0 {
		return "[]", nil
	}
	return string(j), nil
}

func (j *JSON) Scan(value interface{}) error {
	if value == nil {
		*j = JSON("[]")
		return nil
	}
	switch v := value.(type) {
	case []byte:
		*j = JSON(v)
	case string:
		*j = JSON(v)
	default:
		return errors.New("unsupported type for JSON")
	}
	return nil
}

func (j JSON) MarshalJSON() ([]byte, error) {
	if len(j) == 0 {
		return []byte("[]"), nil
	}
	return []byte(j), nil
}

func (j *JSON) UnmarshalJSON(data []byte) error {
	*j = JSON(data)
	return nil
}

// JSONMap 自定义 JSON 类型，用于 MySQL JSON 字段（对象）
type JSONMap json.RawMessage

func (j JSONMap) Value() (driver.Value, error) {
	if len(j) == 0 {
		return "{}", nil
	}
	return string(j), nil
}

func (j *JSONMap) Scan(value interface{}) error {
	if value == nil {
		*j = JSONMap("{}")
		return nil
	}
	switch v := value.(type) {
	case []byte:
		*j = JSONMap(v)
	case string:
		*j = JSONMap(v)
	default:
		return errors.New("unsupported type for JSONMap")
	}
	return nil
}

func (j JSONMap) MarshalJSON() ([]byte, error) {
	if len(j) == 0 {
		return []byte("{}"), nil
	}
	return []byte(j), nil
}

func (j *JSONMap) UnmarshalJSON(data []byte) error {
	*j = JSONMap(data)
	return nil
}

// JSONB PostgreSQL 兼容别名，实际使用 JSON
type JSONB = JSON

// JSONBMap PostgreSQL 兼容别名，实际使用 JSONMap
type JSONBMap = JSONMap

// GenerateUUID 生成 UUID
func GenerateUUID() string {
	return uuid.New().String()
}

// NowPtr 返回当前时间指针
func NowPtr() *time.Time {
	now := time.Now()
	return &now
}
