package handler

import "testing"

func TestIsPortfolioCategoryEnum(t *testing.T) {
	cases := []struct {
		in   string
		want bool
	}{
		{"", false},
		{"app", true},
		{"web", true},
		{"miniprogram", true},
		{"design", true},
		{"data", true},
		{"other", true},
		{"invalid", false},
		{"APP", false},
	}
	for _, c := range cases {
		if got := isPortfolioCategoryEnum(c.in); got != c.want {
			t.Errorf("isPortfolioCategoryEnum(%q) = %v, want %v", c.in, got, c.want)
		}
	}
}
