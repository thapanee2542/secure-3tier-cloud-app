import React from 'react'
import { Member } from '../types/member'

interface MemberCardProps {
  member: Member
}

export const MemberCard: React.FC<MemberCardProps> = ({ member }) => {
  const { name, role, bio, photoUrl } = member

  return (
    <div className="card member-card">
      <div className="member-card-image">
        <img
          src={photoUrl}
          alt={`${name}, ${role}`}
          loading="lazy"
          onError={(e) => {
            // Graceful fallback for missing images
            const img = e.currentTarget as HTMLImageElement
            img.src =
              'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22280%22 height=%22280%22%3E%3Crect fill=%22%23334155%22 width=%22280%22 height=%22280%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 font-size=%2220%22 fill=%22%2394a3b8%22 text-anchor=%22middle%22 dy=%22.3em%22%3ENo Image%3C/text%3E%3C/svg%3E'
          }}
        />
      </div>
      <h3>{name}</h3>
      <p className="role">{role}</p>
      <p>{bio}</p>
    </div>
  )
}
