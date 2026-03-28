package objectstore

import "errors"

// ErrDisabled 未启用或配置不完整
var ErrDisabled = errors.New("object storage disabled")
