#!/usr/bin/env bash

##
# Big Bite package installer script.
#
# Prerequisites:
#   - GitHub CLI
##

# Set some colors.
RED=$(tput setaf 1);
GREEN=$(tput setaf 2);
YELLOW=$(tput setaf 3);
BLUE=$(tput setaf 4);
BOLD=$(tput bold);
RESET=$(tput sgr0);
NEWLINE=$'\n'

##
# Preflight checks.
##

# Set the platform.
PLATFORM=$(/usr/bin/uname -m)

# Set the installation path.
INSTALL_PATH=/usr/local/bin/

# Set the GitHub organization.
ORG=bigbite

# Make sure Mac OS.
if [[ ${OSTYPE} != 'darwin'* ]]
then
  echo "${NEWLINE}${BOLD}${YELLOW}MacOS only supported at this time.${RESET}"
  exit 1
fi

# Make sure arm64 or x86_64 as those are the binaries created.
if [[ ${PLATFORM} != "arm64" ]] && [[ ${PLATFORM} != "x86_64" ]]
then
  echo "${NEWLINE}${BOLD}${YELLOW}Only arm64 and x86_64 architecture supported at this time.${RESET}"
  exit 1
fi

# Make sure the GitHub CLI is installed.
if ! [ -x "$(command -v gh)" ]
then
  echo "${NEWLINE}Please install the GitHub CLI to run this script: https://cli.github.com/"
  exit 1
fi

# Check for flags.
while getopts r:p:v: flag
do
    case "${flag}" in
      r) REPO=${OPTARG};;
      p) PACKAGE_NAME=${OPTARG};;
      v) VERSION=${OPTARG};;
      *) echo "usage: $0 -r [-p] [-v]" >&2
         exit 1 ;;
    esac
done

# Make sure the repo is set.
if [ -z ${REPO+x} ]
then
  echo "${NEWLINE}${BOLD}${YELLOW}Argument required for the repository: -r${RESET}"
  exit 1;
fi

# Set the package name to the either the repo name or the specified package name incase it differs.
PACKAGE_NAME=${PACKAGE_NAME:-$REPO}

# Set the GitHub auth token from the GH_TOKEN environmnet variable, or try via GitHub CLI if not set.
GH_TOKEN=${GH_TOKEN:-$(gh auth token 2>/dev/null)}

# Exit if not token found.
if [ -z "$GH_TOKEN" ]
then
  echo "${NEWLINE}${BOLD}${RED}No GitHub token found${RESET}"
  echo "To get started with GitHub CLI, please run:  gh auth login"
  echo "Alternatively, populate the GH_TOKEN environment variable with a GitHub API authentication token."
  exit 1;
fi

##
# Installation.
##

# Handle if command failed.
cmd_fail_and_exit () {
  if [ -z "$1" ]
  then
    echo "${BOLD}${RED}>>>${RESET} Failed"
  else
    echo "${BOLD}${RED}>>>${RESET} Failed: ${1}"
  fi

  echo "${NEWLINE}${RED}${BOLD}Failed to install ${PACKAGE_NAME}.${RESET}"
  exit 1
}

# Handle if command was successfull.
cmd_success() {
  if [ -z "$1" ]
  then
    echo "${BOLD}${GREEN}>>>${RESET} Done"
  else
    echo "${BOLD}${GREEN}>>>${RESET} Done: ${1}"
  fi
}

# Check if version entered, if not find latest version.
if [ -z ${VERSION+x} ]
then
  echo "${NEWLINE}${BOLD}${BLUE}Checking latest release tag ... ${VERSION}"
  VERSION=$(curl --silent --fail -w '%{http_code}' -H "Authorization: token ${GH_TOKEN}" "https://api.github.com/repos/${ORG}/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  RETURN_CODE=$?
  if [ ${RETURN_CODE} -ne 0 ] || [ -z "${VERSION}" ] || [ "${VERSION}" = "null" ]
  then
    cmd_fail_and_exit
  else
    cmd_success "$VERSION"
  fi
fi

# Set binary filenanme to match output of vercel/pkg.
if [[ ${PLATFORM} == "x86_64" ]]
then
  BINARY="${PACKAGE_NAME}-${VERSION}-macos-x64"
elif [[ ${PLATFORM} == "arm64" ]]
then
  BINARY="${PACKAGE_NAME}-${VERSION}-macos-arm64"
fi

# Display binary that is being downloaded.
echo "${NEWLINE}${BOLD}${BLUE}Downloading ${BINARY} ...${RESET}"

# Download using the GitHub CLI.
gh release download --clobber -R "${ORG}/${REPO}" "${VERSION}" -p "${BINARY}"

# Check if return code is not 0 incase of failure.
RETURN_CODE=$?
if [ ${RETURN_CODE} -ne 0 ]
then
  cmd_fail_and_exit "$ERROR"
else
  cmd_success
fi

# Make sure the binary is executable.
chmod +x "${BINARY}"

# Ad Hoc codesign the binary. Temporary until code signing with certificates is implemented in CI.
codesign -fs - "${BINARY}" 2>/dev/null

# Check if install path exists, create it if not.
if [ ! -d "${INSTALL_PATH}" ]
then
  echo "${NEWLINE}${BLUE}${BOLD}Creating ${INSTALL_PATH} ...${RESET}"
  mkdir -p "${INSTALL_PATH}" || sudo mkdir -p "${INSTALL_PATH}"

  # If failed to create install path, display error message and exit.
  RETURN_CODE=$?
  if [ ${RETURN_CODE} -ne 0 ]
  then
    cmd_fail_and_exit
  else
    cmd_success
  fi
fi

# Display where the downloaded binary is being installed to.
echo "${NEWLINE}${BLUE}${BOLD}Installing to ${INSTALL_PATH} ...${RESET}"

# Move the binary to the install path.
{
  mv -f "${BINARY}" "${INSTALL_PATH}${PACKAGE_NAME}" 2>/dev/null
} || {
  sudo mv -f "${BINARY}" "${INSTALL_PATH}${PACKAGE_NAME}" 2>/dev/null
}

# If failed to install, display error message and exit.
RETURN_CODE=$?
if [ ${RETURN_CODE} -ne 0 ]
then
  cmd_fail_and_exit
else
  cmd_success
fi

# All done.
echo "${NEWLINE}${GREEN}${BOLD}Successfully installed ${PACKAGE_NAME} ${VERSION}!${RESET}"
