import { Hero } from '@/components/landing/hero'
import { ValueProps } from '@/components/landing/value-props'
import { HowItWorks } from '@/components/landing/how-it-works'
import { Featured } from '@/components/landing/featured'
import { StatsWall } from '@/components/landing/stats-wall'
import { Faq } from '@/components/landing/faq'

export const revalidate = 60

export default function Home() {
  return (
    <>
      <Hero />
      <ValueProps />
      <HowItWorks />
      <Featured />
      <StatsWall />
      <Faq />
    </>
  )
}
