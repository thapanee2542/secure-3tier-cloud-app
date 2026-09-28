import React from 'react'

export const Architecture: React.FC = () => {
  return (
    <section className="section">
      <div className="container">
        <div className="section-header">
          <h2>Architecture Overview</h2>
          <p>
            A three-tier serverless architecture on AWS with secure data flow,
            private networking, and infrastructure as code
          </p>
        </div>

        <div className="architecture-container">
          <div className="architecture-diagram">
            <svg
              viewBox="0 0 400 350"
              xmlns="http://www.w3.org/2000/svg"
              width="100%"
              height="auto"
            >
              {/* Web Tier */}
              <rect
                x="50"
                y="20"
                width="300"
                height="60"
                fill="rgba(6, 182, 212, 0.1)"
                stroke="rgb(6, 182, 212)"
                strokeWidth="2"
                rx="4"
              />
              <text
                x="200"
                y="55"
                textAnchor="middle"
                fill="rgb(6, 182, 212)"
                fontSize="14"
                fontWeight="600"
              >
                WEB TIER: CloudFront + S3 (React + Photos)
              </text>

              {/* Arrow down */}
              <line
                x1="200"
                y1="80"
                x2="200"
                y2="110"
                stroke="rgb(6, 182, 212)"
                strokeWidth="2"
                markerEnd="url(#arrowhead)"
              />

              {/* Application Tier */}
              <rect
                x="50"
                y="110"
                width="300"
                height="60"
                fill="rgba(124, 58, 237, 0.1)"
                stroke="rgb(124, 58, 237)"
                strokeWidth="2"
                rx="4"
              />
              <text
                x="200"
                y="145"
                textAnchor="middle"
                fill="rgb(124, 58, 237)"
                fontSize="14"
                fontWeight="600"
              >
                APPLICATION TIER: API Gateway + Lambda
              </text>

              {/* Arrow down */}
              <line
                x1="200"
                y1="170"
                x2="200"
                y2="200"
                stroke="rgb(124, 58, 237)"
                strokeWidth="2"
                markerEnd="url(#arrowhead-purple)"
              />

              {/* Private Network */}
              <rect
                x="20"
                y="200"
                width="360"
                height="120"
                fill="rgba(16, 185, 129, 0.05)"
                stroke="rgb(16, 185, 129)"
                strokeWidth="2"
                strokeDasharray="5,5"
                rx="4"
              />
              <text
                x="30"
                y="220"
                fill="rgb(16, 185, 129)"
                fontSize="12"
                fontWeight="600"
              >
                PRIVATE NETWORK (VPC)
              </text>

              {/* VPC Endpoints */}
              <rect
                x="30"
                y="230"
                width="140"
                height="40"
                fill="rgba(16, 185, 129, 0.1)"
                stroke="rgb(16, 185, 129)"
                strokeWidth="1"
                rx="3"
              />
              <text
                x="100"
                y="255"
                textAnchor="middle"
                fill="rgb(16, 185, 129)"
                fontSize="11"
              >
                DynamoDB Endpoint
              </text>

              {/* Lambda Function */}
              <rect
                x="230"
                y="230"
                width="140"
                height="40"
                fill="rgba(124, 58, 237, 0.1)"
                stroke="rgb(124, 58, 237)"
                strokeWidth="1"
                rx="3"
              />
              <text
                x="300"
                y="255"
                textAnchor="middle"
                fill="rgb(124, 58, 237)"
                fontSize="11"
              >
                Lambda Function
              </text>

              {/* Arrow between endpoint and lambda */}
              <line
                x1="170"
                y1="250"
                x2="230"
                y2="250"
                stroke="rgb(16, 185, 129)"
                strokeWidth="1"
                markerEnd="url(#arrowhead-green)"
              />

              {/* Data Tier */}
              <rect
                x="50"
                y="280"
                width="300"
                height="50"
                fill="rgba(239, 68, 68, 0.1)"
                stroke="rgb(239, 68, 68)"
                strokeWidth="2"
                rx="4"
              />
              <text
                x="200"
                y="315"
                textAnchor="middle"
                fill="rgb(239, 68, 68)"
                fontSize="14"
                fontWeight="600"
              >
                DATA TIER: DynamoDB Members Table
              </text>

              {/* Arrow from Lambda to DynamoDB */}
              <line
                x1="300"
                y1="270"
                x2="300"
                y2="280"
                stroke="rgb(16, 185, 129)"
                strokeWidth="1"
                markerEnd="url(#arrowhead-green)"
              />

              {/* Arrow markers */}
              <defs>
                <marker
                  id="arrowhead"
                  markerWidth="10"
                  markerHeight="10"
                  refX="9"
                  refY="3"
                  orient="auto"
                >
                  <polygon points="0 0, 10 3, 0 6" fill="rgb(6, 182, 212)" />
                </marker>
                <marker
                  id="arrowhead-purple"
                  markerWidth="10"
                  markerHeight="10"
                  refX="9"
                  refY="3"
                  orient="auto"
                >
                  <polygon points="0 0, 10 3, 0 6" fill="rgb(124, 58, 237)" />
                </marker>
                <marker
                  id="arrowhead-green"
                  markerWidth="10"
                  markerHeight="10"
                  refX="9"
                  refY="3"
                  orient="auto"
                >
                  <polygon points="0 0, 10 3, 0 6" fill="rgb(16, 185, 129)" />
                </marker>
              </defs>
            </svg>
          </div>

          <div className="architecture-description">
            <div className="tier">
              <div className="tier-title">🌐 Web Tier</div>
              <p>
                Browser requests go through CloudFront HTTPS to a private S3 bucket
                containing the React build and member photos. Restricted access via
                Origin Access Control.
              </p>
            </div>

            <div className="tier">
              <div className="tier-title">⚡ Application Tier</div>
              <p>
                API Gateway provides the public HTTPS endpoint for the GET /members
                API. Calls are routed to Lambda running in private VPC subnets.
              </p>
            </div>

            <div className="tier">
              <div className="tier-title">🔒 Private Network</div>
              <p>
                Lambda runs in private subnets across two Availability Zones. VPC
                endpoints enable secure communication with DynamoDB without exposing
                data through the public internet.
              </p>
            </div>

            <div className="tier">
              <div className="tier-title">💾 Data Tier</div>
              <p>
                DynamoDB stores member profiles (ID, name, role, bio, photoKey).
                Lambda generates CloudFront URLs for photos and returns formatted
                JSON responses.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
