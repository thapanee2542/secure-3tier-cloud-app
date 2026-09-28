import React from 'react'

interface LoadingSpinnerProps {
  message?: string
}

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  message = 'Loading members...',
}) => (
  <div className="loading-container">
    <div className="spinner" aria-label="Loading"></div>
    <span className="loading-text">{message}</span>
  </div>
)
