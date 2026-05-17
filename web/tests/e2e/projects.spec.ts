import { test, expect } from '@playwright/test'

test('project market is reachable from landing', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('link', { name: '需求广场' }).first().click()
  await expect(page).toHaveURL(/\/projects$/)
  await expect(page.getByRole('heading', { name: '需求广场' })).toBeVisible()
})
