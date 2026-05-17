import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    container: {
      center: true,
      padding: '16px',
      screens: { sm: '640px', md: '768px', lg: '1024px', xl: '1280px', '2xl': '1280px' },
    },
    extend: {
      colors: {
        bg: 'hsl(var(--bg) / <alpha-value>)',
        'bg-subtle': 'hsl(var(--bg-subtle) / <alpha-value>)',
        fg: 'hsl(var(--fg) / <alpha-value>)',
        'fg-muted': 'hsl(var(--fg-muted) / <alpha-value>)',
        'fg-faint': 'hsl(var(--fg-faint) / <alpha-value>)',
        border: 'hsl(var(--border) / <alpha-value>)',
        'accent-1': 'hsl(var(--accent-1) / <alpha-value>)',
        'accent-2': 'hsl(var(--accent-2) / <alpha-value>)',
        'accent-3': 'hsl(var(--accent-3) / <alpha-value>)',
        'accent-4': 'hsl(var(--accent-4) / <alpha-value>)',
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        DEFAULT: 'var(--radius)',
        lg: 'var(--radius-lg)',
        pill: 'var(--radius-pill)',
      },
      backdropBlur: { glass: '20px' },
      boxShadow: {
        glass: '0 1px 0 rgba(255,255,255,.9) inset, 0 8px 24px rgba(60,60,100,.08)',
      },
      fontFamily: {
        sans: ['var(--font-geist-sans)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-geist-mono)', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}
export default config
