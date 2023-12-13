#!/usr/bin/env bash

set -ex

BRED='\033[1;31m' # Bold red
BYELLOW='\033[1;33m' # Bold yellow
NC='\033[0m' # No Color

DIR="$1"

if [ -z "${DIR}" ]; then
    echo "Error: missing directory to test."
    exit 1
fi

check_diff() {
    expected="$1"

    set +e
    terraform plan -detailed-exitcode
    status=$?
    set -e
    # ${status} possible values:
    # 0 - Succeeded, diff is empty (no changes)
    # 1 - Errored
    # 2 - Succeeded, there is a diff

    if [ "${status}" -ne "${expected}" ]; then
        case "${expected}" in
            0)
            echo -e "${BRED}Error: we don't expect any diff here!${NC}"
            exit 1
            ;;
            2)
            echo -e "${BRED}Error: we DO expect some diff here!${NC}"
            exit 1
            ;;
        esac
    fi
}

# Go to the directory to test
cd "${DIR}"

#############################################################
# Part 1: Check that CICD environment won't detect any diff #
#############################################################

echo -e "${BYELLOW}Part 1: Check that CICD environment won't detect any diff${NC}"

# Init & apply
rm -rf builds
terraform init
terraform apply -auto-approve

# Check that the CICD job doesn't detect any diff
echo -e "${BYELLOW}1.1: Check that there is no diff after 'terraform apply'.${NC}"
check_diff 0

# Remove the builds directory to simulate the CICD empty environment
rm -rf builds

# Check that the CICD job doesn't detect any diff
echo -e "${BYELLOW}1.2: Check that there is no diff after removing the 'builds' directory.${NC}"
check_diff 0

###############################################################################
# Part 2: Check that CICD environment will detect diff if lambda code changes #
###############################################################################

echo -e "${BYELLOW}Part 2: Check that CICD environment will detect diff if lambda code changes${NC}"

# Change the lambda code
echo "" >> src/foo/index.py

# Remove the builds directory to simulate the CICD empty environment
rm -rf builds

# Check that the CICD job DOES detect some diff
echo -e "${BYELLOW}2.1: Check that there IS some diff after changing the lambda code & removing the 'builds' directory.${NC}"
check_diff 2

# Apply
terraform apply -auto-approve

# Check that the CICD job doesn't detect any diff
echo -e "${BYELLOW}2.2: Check that there is no diff after 'terraform apply'.${NC}"
check_diff 0

# Remove the builds directory to simulate the CICD empty environment
rm -rf builds

# Check that the CICD job doesn't detect any diff
echo -e "${BYELLOW}2.3: Check that there is no diff after removing the 'builds' directory.${NC}"
check_diff 0

#######
# End #
#######

echo -e "${BYELLOW}All tests have passed successfully.${NC}"
