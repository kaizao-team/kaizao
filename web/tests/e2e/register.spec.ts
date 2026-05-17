import { test, expect } from '@playwright/test'

test('register page step navigation works', async ({ page }) => {
  await page.goto('/auth/register')
  await expect(page.getByRole('heading', { name: '加入 KAIZAO' })).toBeVisible()
  await page.getByRole('button', { name: /我是项目方/ }).click()
  await page.getByRole('button', { name: '下一步' }).click()
  await expect(page.getByPlaceholder('手机号')).toBeVisible()
  // 不发短信，不走完真实注册
})
