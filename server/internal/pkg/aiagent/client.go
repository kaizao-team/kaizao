package aiagent

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/vibebuild/server/internal/config"
	"go.uber.org/zap"
)

// Client 调用 AI-Agent（FastAPI /api/v2）
type Client struct {
	baseURL    string
	httpClient *http.Client
	log        *zap.Logger
}

// NewClient base_url 为空时返回 nil（调用方需判空）
func NewClient(cfg config.AIAgentConfig, log *zap.Logger) *Client {
	base := strings.TrimSpace(cfg.BaseURL)
	if base == "" {
		return nil
	}
	base = strings.TrimRight(base, "/")
	sec := cfg.TimeoutSec
	if sec <= 0 {
		sec = 120
	}
	return &Client{
		baseURL: base,
		httpClient: &http.Client{
			Timeout: time.Duration(sec) * time.Second,
		},
		log: log,
	}
}

// MatchRecommendRequest 对应 POST /api/v2/match/recommend
type MatchRecommendRequest struct {
	DemandID   string                 `json:"demand_id"`
	MatchType  string                 `json:"match_type,omitempty"`
	UserID     string                 `json:"user_id,omitempty"`
	Filters    map[string]interface{} `json:"filters,omitempty"`
	Pagination map[string]int         `json:"pagination,omitempty"`
}

// RecommendData 对应 AI-Agent 返回的 data 字段
type RecommendData struct {
	DemandID           string                 `json:"demand_id"`
	MatchType          string                 `json:"match_type"`
	Recommendations    []RecommendationItem   `json:"recommendations"`
	OverallSuggestion  string                 `json:"overall_suggestion"`
	NoMatchReason      *string                `json:"no_match_reason"`
	Meta               map[string]interface{} `json:"meta"`
}

// RecommendationItem 单条推荐（与 smart_matcher 输出对齐）
type RecommendationItem struct {
	ProviderID              string                 `json:"provider_id"`
	Rank                    int                    `json:"rank"`
	MatchScore              float64                `json:"match_score"`
	RecommendationReason    string                 `json:"recommendation_reason"`
	HighlightSkills         []string               `json:"highlight_skills"`
	SimilarProjectReference string                 `json:"similar_project_reference"`
	DimensionScores         map[string]interface{} `json:"dimension_scores"`
}

type apiEnvelope struct {
	Code      int             `json:"code"`
	Message   string          `json:"message"`
	Data      json.RawMessage `json:"data"`
	RequestID string          `json:"request_id"`
}

// MatchRecommend POST /api/v2/match/recommend
func (c *Client) MatchRecommend(ctx context.Context, reqID string, body MatchRecommendRequest) (*RecommendData, error) {
	if c == nil {
		return nil, fmt.Errorf("ai_agent_client_nil")
	}
	payload, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	url := c.baseURL + "/api/v2/match/recommend"
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(payload))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Content-Type", "application/json")
	if reqID != "" {
		httpReq.Header.Set("X-Request-ID", reqID)
	}

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		if c.log != nil {
			c.log.Warn("ai_agent_match_recommend_http", zap.Error(err))
		}
		return nil, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)

	var env apiEnvelope
	if err := json.Unmarshal(raw, &env); err != nil {
		if c.log != nil {
			c.log.Warn("ai_agent_match_recommend_parse", zap.Error(err), zap.Int("status", resp.StatusCode))
		}
		return nil, fmt.Errorf("ai_agent_invalid_json: %w", err)
	}
	if env.Code != 0 {
		msg := env.Message
		if msg == "" {
			msg = fmt.Sprintf("code=%d", env.Code)
		}
		return nil, fmt.Errorf("ai_agent_error: %s", msg)
	}
	if len(env.Data) == 0 || string(env.Data) == "null" {
		return &RecommendData{}, nil
	}
	var data RecommendData
	if err := json.Unmarshal(env.Data, &data); err != nil {
		return nil, fmt.Errorf("ai_agent_data_unmarshal: %w", err)
	}
	return &data, nil
}
