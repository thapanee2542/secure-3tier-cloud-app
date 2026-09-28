import React from 'react'
import { Member } from '../types/member'
import { MemberCard } from './MemberCard'
import { LoadingSpinner } from './LoadingSpinner'

interface MemberGridProps {
  members: Member[]
  isLoading: boolean
  error: string | null
  onRetry?: () => void
}

export const MemberGrid: React.FC<MemberGridProps> = ({
  members,
  isLoading,
  error,
  onRetry,
}) => {
  if (isLoading) {
    return <LoadingSpinner message="Loading team members..." />
  }

  if (error) {
    return (
      <div className="error-container">
        <h3>Failed to load members</h3>
        <p>{error}</p>
        {onRetry && (
          <button className="error-retry" onClick={onRetry}>
            Retry
          </button>
        )}
      </div>
    )
  }

  if (members.length === 0) {
    return (
      <div className="empty-container">
        <h3>No members found</h3>
        <p>There are currently no team members to display.</p>
      </div>
    )
  }

  return (
    <div className="members-grid">
      {members.map((member) => (
        <MemberCard key={member.id} member={member} />
      ))}
    </div>
  )
}
