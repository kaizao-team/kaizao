import type { MetadataRoute } from 'next'
import { listProjectsServer, listExpertsServer } from '@/lib/api/market'

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base: MetadataRoute.Sitemap = [
    { url: `${SITE}/`, changeFrequency: 'weekly', priority: 1 },
    { url: `${SITE}/projects`, changeFrequency: 'hourly', priority: 0.9 },
    { url: `${SITE}/experts`, changeFrequency: 'daily', priority: 0.8 },
    { url: `${SITE}/about`, changeFrequency: 'monthly', priority: 0.5 },
  ]

  try {
    const projects = await listProjectsServer({ size: 100 })
    base.push(...projects.list.map((p) => ({
      url: `${SITE}/projects/${p.id}`,
      lastModified: p.created_at,
      changeFrequency: 'daily' as const,
      priority: 0.7,
    })))
  } catch {}
  try {
    const experts = await listExpertsServer({ size: 100 })
    base.push(...experts.list.map((e) => ({
      url: `${SITE}/experts/${e.id}`,
      changeFrequency: 'weekly' as const,
      priority: 0.7,
    })))
  } catch {}

  return base
}
