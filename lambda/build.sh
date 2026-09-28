#!/bin/bash
# Build Lambda deployment package
# This script creates a zip file containing the Lambda handler and its dependencies

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACKAGE_DIR="${SCRIPT_DIR}/package"
ZIP_FILE="${SCRIPT_DIR}/lambda_deployment.zip"

echo "=== Building Lambda Deployment Package ==="
echo "Script directory: $SCRIPT_DIR"
echo "Package directory: $PACKAGE_DIR"

# Clean previous build
if [ -d "$PACKAGE_DIR" ]; then
  echo "Cleaning previous package directory..."
  rm -rf "$PACKAGE_DIR"
fi

# Create package directory
mkdir -p "$PACKAGE_DIR"
echo "Created package directory"

# Copy handler
echo "Copying handler.py..."
cp "$SCRIPT_DIR/handler.py" "$PACKAGE_DIR/"

# Install/copy dependencies (if needed)
# For this project, boto3 and botocore are built-in to Lambda runtime
# If you need additional packages, uncomment below:
# echo "Installing Python dependencies..."
# pip install -r "$SCRIPT_DIR/requirements.txt" -t "$PACKAGE_DIR"

# Create zip file
echo "Creating deployment zip file..."
cd "$PACKAGE_DIR"
zip -r "$ZIP_FILE" .
cd -

echo "✓ Build complete!"
echo "Deployment package: $ZIP_FILE"
echo "Package size: $(du -h "$ZIP_FILE" | cut -f1)"
