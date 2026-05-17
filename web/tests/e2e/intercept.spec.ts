import { test, expect } from '@playwright/test'

test('clicking "联系" on project detail opens auth intercept when not logged in', async ({ page }) => {
  // 此用例需要有真实项目数据，本地后端连不上时会跳过
  await page.goto('/projects')
  const first = page.locator('a[href^="/projects/"]').first()
  const hasProjects = (await first.count()) > 0
  test.skip(!hasProjects, 'no projects in backend, skipping')

  await first.click()
  await page.getByRole('button', { name: /联系项目方/ }).click()
  await expect(page.getByText(/注册后即可/)).toBeVisible()
})
