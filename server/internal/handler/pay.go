package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/vibebuild/server/internal/pkg/errcode"
	"github.com/vibebuild/server/internal/pkg/response"
	"github.com/vibebuild/server/internal/service"
	"go.uber.org/zap"
)

type OrderHandler struct {
	orderService  *service.OrderService
	walletService *service.WalletService
	log           *zap.Logger
}

func NewOrderHandler(orderService *service.OrderService, walletService *service.WalletService, log *zap.Logger) *OrderHandler {
	return &OrderHandler{orderService: orderService, walletService: walletService, log: log}
}

func (h *OrderHandler) GetDetail(c *gin.Context) {
	id := c.Param("id")
	detail, err := h.orderService.GetDetail(id)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrOrderNotFound, "订单不存在")
		return
	}
	response.Success(c, detail)
}

func (h *OrderHandler) Prepay(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		PaymentMethod string `json:"payment_method" binding:"required"`
		CouponID      string `json:"coupon_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	result, err := h.orderService.Prepay(id, req.PaymentMethod)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrOrderNotFound, "订单不存在")
		return
	}
	response.Success(c, result)
}

func (h *OrderHandler) GetStatus(c *gin.Context) {
	id := c.Param("id")
	result, err := h.orderService.GetStatus(id)
	if err != nil {
		response.ErrorNotFound(c, errcode.ErrOrderNotFound, "订单不存在")
		return
	}
	response.Success(c, result)
}

func (h *OrderHandler) GetCoupons(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	coupons, _ := h.orderService.ListCoupons(userUUID)
	response.Success(c, coupons)
}

type WalletHandler struct {
	walletService *service.WalletService
	log           *zap.Logger
}

func NewWalletHandler(walletService *service.WalletService, log *zap.Logger) *WalletHandler {
	return &WalletHandler{walletService: walletService, log: log}
}

func (h *WalletHandler) GetBalance(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	balance, err := h.walletService.GetBalance(userUUID)
	if err != nil {
		response.ErrorInternal(c, "获取钱包余额失败")
		return
	}
	response.Success(c, balance)
}

func (h *WalletHandler) ListTransactions(c *gin.Context) {
	userUUID := c.GetString("user_uuid")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	if page <= 0 {
		page = 1
	}
	if pageSize <= 0 {
		pageSize = 10
	}
	items, total, err := h.walletService.ListTransactions(userUUID, page, pageSize)
	if err != nil {
		response.ErrorInternal(c, "获取交易记录失败")
		return
	}
	response.SuccessWithMeta(c, items, response.BuildMeta(page, pageSize, total))
}

func (h *WalletHandler) Withdraw(c *gin.Context) {
	var req struct {
		Amount float64 `json:"amount" binding:"required,min=1"`
		Method string  `json:"method" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorBadRequest(c, errcode.ErrParamInvalid, "参数校验失败")
		return
	}
	userUUID := c.GetString("user_uuid")
	result, err := h.walletService.Withdraw(userUUID, req.Amount, req.Method)
	if err != nil {
		response.ErrorBadRequest(c, errcode.ErrWithdrawExceedBalance, "余额不足")
		return
	}
	response.SuccessMsg(c, "提现申请已提交", result)
}
