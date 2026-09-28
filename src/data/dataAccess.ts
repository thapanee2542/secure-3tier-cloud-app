import { Member, APIResponse } from '../types/member'
import { LOCAL_MEMBERS } from './members'

/**
 * DATA ACCESS LAYER
 * 
 * Abstracts local vs. API data sources for member information.
 * This allows seamless switching between local development and deployed API calls.
 * 
 * Modes:
 * - 'local': Reads from hardcoded LOCAL_MEMBERS array (default, works offline)
 * - 'api': Calls the deployed API Gateway endpoint
 */

type DataMode = 'local' | 'api'

const isLocalMode = (): boolean => {
  const mode = getDataMode()
  return mode === 'local'
}

const getDataMode = (): DataMode => {
  const envMode = import.meta.env.VITE_DATA_MODE as DataMode | undefined
  return envMode === 'api' ? 'api' : 'local'
}

const getApiBaseUrl = (): string => {
  const url = import.meta.env.VITE_API_BASE_URL as string | undefined
  if (!url) {
    throw new Error(
      'VITE_API_BASE_URL is not set. Configure it in .env.local when using api mode.'
    )
  }
  return url.replace(/\/$/, '') // Remove trailing slash
}

const getCloudFrontDomain = (): string => {
  return import.meta.env.VITE_CLOUDFRONT_DOMAIN as string || ''
}

/**
 * Fetch members from local data or API
 * 
 * Returns members with properly formatted photoUrl:
 * - Local mode: photoUrl points to /public/{photoKey}
 * - API mode: Lambda generates photoUrl using CloudFront domain
 */
export async function getMembers(): Promise<Member[]> {
  if (isLocalMode()) {
    return getLocalMembers()
  }

  try {
    return await getApiMembers()
  } catch (error) {
    console.error('API call failed; falling back to local data:', error)
    return getLocalMembers()
  }
}

/**
 * Local mode: Return hardcoded members with local photo paths
 */
function getLocalMembers(): Member[] {
  return LOCAL_MEMBERS.map((member) => ({
    ...member,
    // In local mode, photoUrl is already set to relative /public path
  }))
}

/**
 * API mode: Fetch members from API Gateway → Lambda → DynamoDB
 * 
 * Expected API response:
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "id": "member-001",
 *       "name": "Alice Johnson",
 *       "role": "...",
 *       "bio": "...",
 *       "photoKey": "photos/alice-johnson.jpg",
 *       "photoUrl": "https://d1234567.cloudfront.net/photos/alice-johnson.jpg"
 *     },
 *     ...
 *   ]
 * }
 */
async function getApiMembers(): Promise<Member[]> {
  const apiUrl = getApiBaseUrl()
  const endpoint = `${apiUrl}/members`

  console.log(`Fetching members from API: ${endpoint}`)

  const response = await fetch(endpoint, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
    credentials: 'omit', // No credentials for CORS requests to API Gateway
  })

  if (!response.ok) {
    throw new Error(
      `API error: ${response.status} ${response.statusText}\nURL: ${endpoint}`
    )
  }

  const data: APIResponse = await response.json()

  if (!data.success || !data.data) {
    throw new Error(`Invalid API response: ${JSON.stringify(data)}`)
  }

  return data.data
}

/**
 * Get current configuration for debugging/display
 */
export function getConfiguration() {
  return {
    mode: getDataMode(),
    apiBaseUrl: isLocalMode() ? null : getApiBaseUrl(),
    cloudFrontDomain: getCloudFrontDomain(),
    isLocalMode: isLocalMode(),
  }
}
