#!/usr/bin/env bash
# Copyright 2026 The Kairos Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This script manages the staging/src/kairos.io/apis directory.
# It can initialize the staging directory from the kairos-apis repo,
# or sync changes to it.
#
# Usage:
#   ./hack/sync-apis.sh [command] [options]
#
# Commands:
#   init         Initialize staging directory from kairos-apis repo
#   sync         (default) Sync staging directory to kairos-apis repo
#
# Options:
#   --target-branch   Target branch in apis repo (default: main)
#   --force           Force overwrite existing staging directory (for init)
#   --help            Show this help message
#
# Environment variables:
#   APIS_REPO_DIR   Local directory of the apis repository (required for sync)
#                   In GitHub Actions, set this to the checkout path
#   APIS_REPO_URL   URL of the apis repository (for init only,
#                   default: https://github.com/NekoChan1108/kairos-apis.git)
#   TARGET_BRANCH   Target branch in apis repo (default: main)

set -o errexit
set -o nounset
set -o pipefail

# Get the root of the repo
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${SCRIPT_ROOT}"

# Configuration
STAGING_DIR="${SCRIPT_ROOT}/staging/src/kairos.io/apis"
APIS_REPO_URL=${APIS_REPO_URL:-"https://github.com/NekoChan1108/kairos-apis.git"}
APIS_REPO_DIR=${APIS_REPO_DIR:-""}
TARGET_BRANCH=${TARGET_BRANCH:-"main"}
FORCE=false
COMMAND="sync"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Cleanup function for error handling
cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        print_error "Script failed with exit code ${exit_code}"
    fi
}
trap cleanup EXIT

show_help() {
    cat << EOF
Usage: $0 [command] [options]

Manage the staging/src/kairos.io/apis directory.

Commands:
  init         Initialize staging directory from kairos-apis repo
  sync         (default) Sync staging directory to kairos-apis repo

Options:
  --target-branch   Target branch in apis repo (default: main)
  --force           Force overwrite existing staging directory (init only)
  --help            Show this help message

Environment Variables:
  APIS_REPO_DIR   Local directory of the apis repository (required for sync)
  APIS_REPO_URL   URL of the apis repository (for init only,
                  default: https://github.com/NekoChan1108/kairos-apis.git)
  TARGET_BRANCH   Target branch in apis repo (default: main)

Examples:
  # Initialize staging directory for the first time
  $0 init

  # Re-initialize staging directory (overwrite existing)
  $0 init --force

  # Initialize from a specific branch
  $0 init --target-branch release-1.0

  # Sync changes (requires APIS_REPO_DIR to be set)
  APIS_REPO_DIR=/path/to/apis-repo $0 sync
EOF
}

# Initialize staging directory from apis repo
do_init() {
    print_info "Initializing staging directory from ${APIS_REPO_URL}..."

    if [[ -d "${STAGING_DIR}" ]] && [[ -n "$(ls -A "${STAGING_DIR}" 2>/dev/null)" ]]; then
        if [[ "${FORCE}" != "true" ]]; then
            print_error "Staging directory already exists and is not empty: ${STAGING_DIR}"
            print_info "Use --force to overwrite existing content"
            exit 1
        fi
        print_warning "Force mode: will overwrite existing staging directory"
    fi

    mkdir -p "${STAGING_DIR}"

    local TEMP_DIR=$(mktemp -d /tmp/kairos-apis-init.XXXXXX)
    print_info "Cloning apis repository (branch: ${TARGET_BRANCH})..."
    if ! git clone --depth 1 --branch "${TARGET_BRANCH}" "${APIS_REPO_URL}" "${TEMP_DIR}" 2>&1; then
        print_error "Failed to clone. Does branch '${TARGET_BRANCH}' exist in ${APIS_REPO_URL}?"
        exit 1
    fi

    print_info "Copying to staging directory..."
    rsync -av --delete \
        --exclude='.git' \
        --exclude='.github' \
        --exclude='.gitignore' \
        --exclude='GOVERNANCE.md' \
        --exclude='OWNERS' \
        --exclude='SECURITY.md' \
        --exclude='LICENSE' \
        "${TEMP_DIR}/" "${STAGING_DIR}/"

    rm -rf "${TEMP_DIR}"

    print_success "Staging directory initialized successfully!"
    print_info "Location: ${STAGING_DIR}"
    print_info ""
    print_info "Next steps:"
    print_info " 1. The go.mod should have a replace directive:"
    print_info "    replace kairos.io/apis => ./staging/src/kairos.io/apis"
    print_info " 2. Make API changes in ${STAGING_DIR}"
    print_info " 3. Run 'go build ./...' to verify changes"
    print_info " 4. Commit and push changes"
}

# Sync staging directory to apis repo
do_sync() {
    if [[ ! -d "${STAGING_DIR}" ]]; then
        print_error "Staging directory does not exist: ${STAGING_DIR}"
        print_info "Run '$0 init' to initialize it first"
        exit 1
    fi

    if [[ -z "$(ls -A "${STAGING_DIR}" 2>/dev/null)" ]]; then
        print_error "Staging directory is empty: ${STAGING_DIR}"
        print_info "Run '$0 init' to initialize it first"
        exit 1
    fi

    if [[ -z "${APIS_REPO_DIR}" ]]; then
        print_error "APIS_REPO_DIR environment variable is required"
        print_info "Set it to the local checkout path of the apis repository"
        exit 1
    fi

    if [[ ! -d "${APIS_REPO_DIR}" ]]; then
        print_error "APIS_REPO_DIR does not exist: ${APIS_REPO_DIR}"
        exit 1
    fi

    print_info "Syncing staging directory to ${APIS_REPO_DIR}..."

    rsync -av --delete \
        --exclude='.git' \
        --exclude='.github' \
        --exclude='.gitignore' \
        --exclude='GOVERNANCE.md' \
        --exclude='OWNERS' \
        --exclude='SECURITY.md' \
        --exclude='LICENSE' \
        "${STAGING_DIR}/" "${APIS_REPO_DIR}/"

    cd "${APIS_REPO_DIR}"
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "SYNC_RESULT=success"
    else
        echo "SYNC_RESULT=no_changes"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        init)
            COMMAND="init"
            shift
            ;;
        sync)
            COMMAND="sync"
            shift
            ;;
        --target-branch)
            TARGET_BRANCH="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

case "${COMMAND}" in
    init)
        do_init
        ;;
    sync)
        do_sync
        ;;
    *)
        print_error "Unknown command: ${COMMAND}"
        show_help
        exit 1
        ;;
esac