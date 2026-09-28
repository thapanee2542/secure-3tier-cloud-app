import { Member } from '../types/member'

/**
 * LOCAL MEMBER DATA
 * 
 * TODO(CLOUD): When deployed to AWS:
 * 1. This file will be ignored in favor of API calls to Lambda/DynamoDB
 * 2. Image URLs will point to CloudFront instead of /public
 * 3. The API response will be fetched from VITE_API_BASE_URL
 */

export const LOCAL_MEMBERS: Member[] = [
  {
    id: 'member-001',
    name: 'Alice Johnson',
    role: 'Project Lead & Full-Stack Engineer',
    bio: 'Leaders in cloud security architecture. Expert in serverless patterns, infrastructure as code, and best practices for least-privilege access control.',
    photoKey: 'photos/alice-johnson.jpg',
    photoUrl: '/6907031857148.JPG',
  },
  {
    id: 'member-002',
    name: 'Bob Chen',
    role: 'Backend & Security Specialist',
    bio: 'Focused on Lambda security, DynamoDB encryption, and API Gateway authorization. Implements secure data pipelines and audit logging.',
    photoKey: 'photos/bob-chen.jpg',
    photoUrl: '/6907031857164.JPG',
  },
  {
    id: 'member-003',
    name: 'Carol Martinez',
    role: 'Frontend & DevOps Engineer',
    bio: 'Specializes in React performance, CloudFront CDN optimization, and CI/CD pipelines. Ensures secure and efficient media delivery.',
    photoKey: 'photos/carol-martinez.jpg',
    photoUrl: '/6907031857181.JPG',
  },
  {
    id: 'member-004',
    name: 'Thapanee Nooying',
    role: '6907031857211',
    bio: 'Designs resilient, scalable architectures with minimal costs. Expert in VPC design, DynamoDB patterns, and comprehensive documentation.',
    photoKey: 'photos/diana-patel.jpg',
    photoUrl: '/6907031857211.jpg',
  },
  {
    id: 'member-005',
    name: 'Diana Patel',
    role: 'Cloud Architect & Documentation Lead',
    bio: 'Designs resilient, scalable architectures with minimal costs. Expert in VPC design, DynamoDB patterns, and comprehensive documentation.',
    photoKey: 'photos/diana-patel.jpg',
    photoUrl: '/6907031857229.JPG',
  },
]
