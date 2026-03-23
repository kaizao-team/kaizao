package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

// HomeHandler 首页处理器
type HomeHandler struct {
	homeService *service.HomeService
	log         *zap.Logger
}

// NewHomeHandler 创建首页处理器
func NewHomeHandler(homeService *service.HomeService, log *zap.Logger) *HomeHandler {
	return &HomeHandler{homeService: homeService, log: log}
}

// DemanderHome 需求方首页数据
// GET /api/v1/home/demander
func (h *HomeHandler) DemanderHome(c *gin.Context) {
	userUUID := c.GetString("user_uuid")

	data, err := h.homeService.GetDemanderHome(userUUID)
	if err != nil {
		response.ErrorInternal(c, "获取首页数据失败")
		return
	}

	response.Success(c, data)
}

// ExpertHome 专家首页数据
// GET /api/v1/home/expert
func (h *HomeHandler) ExpertHome(c *gin.Context) {
	userUUID := c.GetString("user_uuid")

	data, err := h.homeService.GetExpertHome(userUUID)
	if err != nil {
		response.ErrorInternal(c, "获取首页数据失败")
		return
	}

	response.Success(c, data)
}
