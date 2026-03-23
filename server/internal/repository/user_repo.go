package repository

import (
	"github.com/vibebuild/server/internal/model"
	"gorm.io/gorm"
)

type userRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(user *model.User) error {
	return r.db.Create(user).Error
}

func (r *userRepository) FindByID(id int64) (*model.User, error) {
	var user model.User
	err := r.db.Where("id = ? AND status != 3", id).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) FindByUUID(uuid string) (*model.User, error) {
	var user model.User
	err := r.db.Where("uuid = ? AND status != 3", uuid).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) FindByPhoneHash(phoneHash string) (*model.User, error) {
	var user model.User
	err := r.db.Where("phone_hash = ?", phoneHash).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) FindByWechatOpenID(openID string) (*model.User, error) {
	var user model.User
	err := r.db.Where("wechat_openid = ?", openID).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) Update(user *model.User) error {
	return r.db.Save(user).Error
}

func (r *userRepository) UpdateFields(id int64, fields map[string]interface{}) error {
	return r.db.Model(&model.User{}).Where("id = ?", id).Updates(fields).Error
}

func (r *userRepository) ListExperts(offset, limit int) ([]*model.User, int64, error) {
	var users []*model.User
	var total int64
	query := r.db.Model(&model.User{}).Where("role IN (2,3) AND status = 1 AND available_status = 1")
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("avg_rating DESC, completed_orders DESC").
		Offset(offset).Limit(limit).Find(&users).Error; err != nil {
		return nil, 0, err
	}
	return users, total, nil
}
