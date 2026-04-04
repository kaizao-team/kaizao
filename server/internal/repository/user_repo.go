package repository

import (
	"errors"
	"strings"

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
	err := r.db.Where("phone_hash = ? AND status != 3", phoneHash).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) FindByUsername(username string) (*model.User, error) {
	var user model.User
	err := r.db.Where("username = ? AND status != 3", username).First(&user).Error
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
	query := r.db.Model(&model.User{}).Where("role IN (2,3) AND status = 1 AND available_status = 1 AND onboarding_status = ?", model.OnboardingApproved)
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	if err := query.Order("avg_rating DESC, completed_orders DESC").
		Offset(offset).Limit(limit).Find(&users).Error; err != nil {
		return nil, 0, err
	}
	return users, total, nil
}

func (r *userRepository) ListUserSkills(userID int64) ([]*model.UserSkill, error) {
	var skills []*model.UserSkill
	err := r.db.Preload("Skill").Where("user_id = ?", userID).Find(&skills).Error
	return skills, err
}

func (r *userRepository) ListUserSkillsForUsers(userIDs []int64) ([]*model.UserSkill, error) {
	if len(userIDs) == 0 {
		return nil, nil
	}
	var skills []*model.UserSkill
	err := r.db.Preload("Skill").
		Where("user_id IN ?", userIDs).
		Order("user_id ASC, is_primary DESC, id ASC").
		Find(&skills).Error
	return skills, err
}

func (r *userRepository) FindSkillNamesByIDs(skillIDs []int64) (map[int64]string, error) {
	if len(skillIDs) == 0 {
		return map[int64]string{}, nil
	}
	var rows []model.Skill
	if err := r.db.Model(&model.Skill{}).Select("id", "name").
		Where("id IN ? AND status = 1", skillIDs).
		Find(&rows).Error; err != nil {
		return nil, err
	}
	out := make(map[int64]string, len(rows))
	for i := range rows {
		out[rows[i].ID] = strings.TrimSpace(rows[i].Name)
	}
	return out, nil
}

func (r *userRepository) ReplaceUserSkills(userID int64, skills []*model.UserSkill) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("user_id = ?", userID).Delete(&model.UserSkill{}).Error; err != nil {
			return err
		}
		if len(skills) > 0 {
			return tx.Create(&skills).Error
		}
		return nil
	})
}

func (r *userRepository) FindSkillByID(id int64) (*model.Skill, error) {
	var s model.Skill
	err := r.db.Where("id = ? AND status = 1", id).First(&s).Error
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *userRepository) EnsureSkill(name, category string) (*model.Skill, error) {
	name = strings.TrimSpace(name)
	if name == "" {
		return nil, errors.New("empty skill name")
	}
	var s model.Skill
	err := r.db.Where("name = ?", name).First(&s).Error
	if err == nil {
		return &s, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}
	cat := strings.TrimSpace(category)
	if cat == "" {
		cat = "other"
	}
	s = model.Skill{
		Name:     name,
		Category: cat,
		Status:   1,
	}
	if err := r.db.Create(&s).Error; err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *userRepository) ListUserPortfolios(userID int64) ([]*model.Portfolio, error) {
	var portfolios []*model.Portfolio
	err := r.db.Where("user_id = ? AND status = 1", userID).Order("sort_order ASC, created_at DESC").Find(&portfolios).Error
	return portfolios, err
}

func (r *userRepository) CreatePortfolio(p *model.Portfolio) error {
	return r.db.Create(p).Error
}

func (r *userRepository) FindPortfolioByUUID(uuid string) (*model.Portfolio, error) {
	var p model.Portfolio
	err := r.db.Where("uuid = ? AND status = 1", uuid).First(&p).Error
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *userRepository) UpdatePortfolioFields(id int64, fields map[string]interface{}) error {
	return r.db.Model(&model.Portfolio{}).Where("id = ?", id).Updates(fields).Error
}

func (r *userRepository) CountPortfoliosByUserAndUUIDs(userID int64, uuids []string) (int64, error) {
	if len(uuids) == 0 {
		return 0, nil
	}
	var n int64
	err := r.db.Model(&model.Portfolio{}).
		Where("user_id = ? AND status = 1 AND uuid IN ?", userID, uuids).
		Count(&n).Error
	return n, err
}
