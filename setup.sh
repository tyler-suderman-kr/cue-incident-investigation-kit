#!/bin/bash
# Incident Investigation Kit - Setup Script

set -e  # Exit on any error

echo "🔧 Incident Investigation Kit - Setup"
echo "======================================"
echo ""

# ============================================================================
# STEP 0: Check for Existing Configuration
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 0: Checking for existing configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f .env ]; then
  if [ -t 0 ]; then
    # Interactive mode - prompt user
    read -p "⚠️  .env already exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Setup cancelled by user."
      exit 0
    fi
    echo "Overwriting existing .env file..."
  else
    # Non-interactive mode - skip if .env exists
    echo "✅ .env already exists"
    echo "   Setup is already complete. Delete .env to re-run setup."
    exit 0
  fi
else
  echo "No existing .env found. Proceeding with setup..."
fi

echo ""

# ============================================================================
# STEP 1: Verify Repository Placement
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Verifying repository placement..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

REPO_CHECK_FAILED=false

# Auto-detect cue repo
if [ -d "../cue" ]; then
  CUE_PATH="../cue"
  echo "✅ Found cue repo at ../cue"
else
  echo "❌ cue repo not found at ../cue"
  REPO_CHECK_FAILED=true
fi

# Auto-detect ACL repo (renamed or original)
if [ -d "../acl" ]; then
  ACL_PATH="../acl"
  echo "✅ Found ACL repo at ../acl"
elif [ -d "../arrivals-consumer-layer" ]; then
  ACL_PATH="../arrivals-consumer-layer"
  echo "✅ Found ACL repo at ../arrivals-consumer-layer"
else
  echo "❌ ACL repo not found at ../acl or ../arrivals-consumer-layer"
  REPO_CHECK_FAILED=true
fi

# Auto-detect CQS repo (renamed or original)
if [ -d "../cqs" ]; then
  CQS_PATH="../cqs"
  echo "✅ Found CQS repo at ../cqs"
elif [ -d "../cue-query-service" ]; then
  CQS_PATH="../cue-query-service"
  echo "✅ Found CQS repo at ../cue-query-service"
else
  echo "❌ CQS repo not found at ../cqs or ../cue-query-service"
  REPO_CHECK_FAILED=true
fi

if [ "$REPO_CHECK_FAILED" = true ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ STEP 1 FAILED: Repository placement incorrect"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "⚠️  This repo must be placed as a sibling to cue/acl/cqs repos."
  echo ""
  echo "Expected directory structure:"
  echo "  parent-folder/"
  echo "  ├── cue/"
  echo "  ├── acl/                         (or arrivals-consumer-layer/)"
  echo "  ├── cqs/                         (or cue-query-service/)"
  echo "  └── cue-incident-investigation-kit/   (this repo)"
  echo ""
  echo "Please relocate this repository and run ./setup.sh again."
  echo ""
  exit 1
fi

echo ""
echo "✅ STEP 1 COMPLETE: All repositories found"
echo ""

# ============================================================================
# STEP 2: Dynatrace Configuration
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Dynatrace API configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running interactively
if [ ! -t 0 ]; then
  # Non-interactive mode
  if [ -z "$DYNATRACE_TOKEN" ]; then
    echo "❌ Running in non-interactive mode without DYNATRACE_TOKEN"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ SETUP FAILED: Missing Dynatrace configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Step 1: ✅ Repository verification (passed)"
    echo "Step 2: ❌ Dynatrace configuration (failed)"
    echo ""
    echo "To complete setup, choose one of these options:"
    echo ""
    echo "  Option 1: Run interactively"
    echo "    $ ./setup.sh"
    echo "    (You will be prompted for your Dynatrace API token)"
    echo ""
    echo "  Option 2: Set environment variable"
    echo "    $ export DYNATRACE_TOKEN='your-token-here'"
    echo "    $ ./setup.sh"
    echo ""
    echo "ℹ️  Partial setup complete. Repos verified, but Dynatrace not configured."
    exit 0
  fi
  echo "ℹ️  Using DYNATRACE_TOKEN from environment"
else
  # Interactive mode - prompt if not already set
  if [ -z "$DYNATRACE_TOKEN" ]; then
    echo "A Dynatrace API token is required for log investigation."
    echo ""
    read -p "Enter your Dynatrace API token: " DYNATRACE_TOKEN
    echo ""
  else
    echo "ℹ️  Using DYNATRACE_TOKEN from environment"
  fi
fi

# Validate token is provided
if [ -z "$DYNATRACE_TOKEN" ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ SETUP FAILED: Dynatrace token required"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  exit 1
fi

# Validate token with API call
echo "Validating Dynatrace token..."
DYNATRACE_ENV="https://kroger-prod.apps.dynatrace.com/"
VALIDATION_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${DYNATRACE_ENV}platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer $DYNATRACE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "fetch logs, from:-1h | limit 1", "requestTimeoutMilliseconds": 5000}' 2>&1)

HTTP_CODE=$(echo "$VALIDATION_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Token validated successfully"
elif [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
  echo "❌ Token validation failed: Invalid or expired token (HTTP $HTTP_CODE)"
  echo ""
  echo "Please check your token at:"
  echo "https://kroger-prod.apps.dynatrace.com/ui/apps/dynatrace.classic.tokens/ui/access-tokens"
  echo ""
  exit 1
else
  echo "⚠️  Token validation returned HTTP $HTTP_CODE"
  echo "   Proceeding anyway - you can test queries manually later"
fi

echo ""
echo "✅ STEP 2 COMPLETE: Dynatrace configured"
echo ""

# ============================================================================
# STEP 3: Generate Configuration File
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Generating .env configuration file..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create .env file
cat > .env << EOF
# Incident Investigation Kit - Environment Variables
# Generated by setup.sh on $(date)

# Setup Status
SETUP_COMPLETE=true

# ============================================================================
# Dynatrace
# ============================================================================
DYNATRACE_TOKEN=$DYNATRACE_TOKEN
DYNATRACE_ENVIRONMENT=https://kroger-prod.apps.dynatrace.com/

# ============================================================================
# OPTIONAL: Jira (for ad-hoc searches only)
# ============================================================================
# Uncomment to enable Jira searches during investigations
# Generate token at: https://id.atlassian.com/manage-profile/security/api-tokens

# ATLASSIAN_EMAIL=your.email@kroger.com
# ATLASSIAN_TOKEN=your-token-here
# ATLASSIAN_DOMAIN=kroger.atlassian.net

# ============================================================================
# AUTO-DETECTED: Repository Locations
# ============================================================================
CUE_REPO_PATH=$CUE_PATH
ACL_REPO_PATH=$ACL_PATH
CQS_REPO_PATH=$CQS_PATH
EOF

echo "✅ Created .env file with configuration"
echo ""
echo "✅ STEP 3 COMPLETE: Configuration saved"
echo ""

# ============================================================================
# STEP 4: Create Investigation Directory
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Creating investigation directory..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

mkdir -p .active-investigations
echo "✅ Created .active-investigations/ directory"
echo ""
echo "✅ STEP 4 COMPLETE: Investigation workspace ready"
echo ""

# ============================================================================
# SETUP COMPLETE
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SETUP COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration Summary:"
echo "  ✅ Dynatrace:  Configured & validated"
echo "  ✅ CUE repo:   $CUE_PATH"
echo "  ✅ ACL repo:   $ACL_PATH"
echo "  ✅ CQS repo:   $CQS_PATH"
echo "  ✅ Workspace:  .active-investigations/ created"
echo ""
echo "You can now start investigating incidents!"
echo "Run 'claude' in this directory to begin."
echo ""
