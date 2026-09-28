import { useEffect, useRef, useState } from 'react'
import { Member } from './types/member'
import { getMembers, getConfiguration } from './data/dataAccess'
import { Hero } from './components/Hero'
import { MemberGrid } from './components/MemberGrid'
import { Architecture } from './components/Architecture'
import { ErrorBoundary } from './components/ErrorBoundary'

function App() {
  const [members, setMembers] = useState<Member[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const membersRef = useRef<HTMLDivElement>(null)

  const loadMembers = async () => {
    setIsLoading(true)
    setError(null)
    try {
      const data = await getMembers()
      setMembers(data)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load members'
      setError(message)
      console.error('Error loading members:', err)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    loadMembers()

    // Log configuration for debugging
    const config = getConfiguration()
    console.log('App Configuration:', config)
  }, [])

  const handleExploreClick = () => {
    membersRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  return (
    <ErrorBoundary>
      <div className="app">
        {/* Hero Section */}
        <Hero onExploreClick={handleExploreClick} />

        {/* Members Section */}
        <section className="section" ref={membersRef}>
          <div className="container">
            <div className="section-header">
              <h2>Meet Our Team</h2>
              <p>
                Cloud security specialists designing and implementing a secure,
                scalable three-tier AWS serverless architecture
              </p>
            </div>

            <MemberGrid
              members={members}
              isLoading={isLoading}
              error={error}
              onRetry={loadMembers}
            />
          </div>
        </section>

        {/* Architecture Section */}
        <Architecture />

        {/* Footer */}
        <footer>
          <div className="container">
            <div>
              <h4>Project</h4>
              <ul>
                <li>
                  <a href="https://github.com" target="_blank" rel="noopener noreferrer">
                    GitHub Repository
                  </a>
                </li>
                <li>
                  <a href="#docs">Documentation</a>
                </li>
              </ul>
            </div>
            <div>
              <h4>Technology</h4>
              <ul>
                <li>React + Vite + TypeScript</li>
                <li>AWS Lambda + API Gateway</li>
                <li>DynamoDB + CloudFront</li>
                <li>Infrastructure as Code (Terraform)</li>
              </ul>
            </div>
            <div>
              <h4>Resources</h4>
              <ul>
                <li>
                  <a
                    href="https://aws.amazon.com/serverless"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    AWS Serverless
                  </a>
                </li>
                <li>
                  <a
                    href="https://www.terraform.io/"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Terraform
                  </a>
                </li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            <p>
              © 2024 Secure 3-Tier Cloud App. Cloud Security Term Project - Group 1
            </p>
          </div>
        </footer>
      </div>
    </ErrorBoundary>
  )
}

export default App
