import React from 'react'

interface HeroProps {
  onExploreClick?: () => void
}

export const Hero: React.FC<HeroProps> = ({ onExploreClick }) => {
  return (
    <section className="hero">
      <div className="container hero-content">
        <h1>
          Secure <span className="gradient-text">3-Tier Cloud</span> Architecture
        </h1>
        <p>
          A modern, serverless web application demonstrating best practices in cloud
          security, infrastructure as code, and scalable system design using AWS.
        </p>
        <button className="hero-cta" onClick={onExploreClick}>
          Explore Our Team
        </button>
      </div>
    </section>
  )
}
