import { test, expect } from '@playwright/test'

test('landing page renders hero and CTAs', async ({ page }) => {
  await page.goto('/')
  await expect(page.getByText('把模糊的需求')).toBeVisible()
  await expect(page.getByRole('link', { name: /我是项目方/ })).toBeVisible()
  await expect(page.getByRole('link', { name: /我是团队方/ })).toBeVisible()
})

test('FAQ items are togglable', async ({ page }) => {
  await page.goto('/')
  await page.getByText('KAIZAO 是做什么的？').click()
  await expect(page.getByText(/AI 驱动的软件需求撮合平台/)).toBeVisible()
})
