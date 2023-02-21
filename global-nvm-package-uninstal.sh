#!/usr/bin/env bash

# Diable SC1091 for loading nvm.
# shellcheck disable=SC1091

RED=$(tput setaf 1);
GREEN=$(tput setaf 2);
BLUE=$(tput setaf 4);
BOLD=$(tput bold);
RESET=$(tput sgr0);
NEWLINE=$'\n'

# Grab the package name from input, exit if none specified.
PACKAGE=$1
if [ -z ${1+x} ]
then
  echo "Package name not specified."
  exit 1
fi

if ! [ -d "$NVM_DIR" ]; then
	printf "\$NVM_DIR not defined. Make sure nvm is correctly installed.\\n"
	exit 1
fi

# Load nvm to run commands.
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Get installed node versions.
NODE_VERSIONS=$(nvm ls --no-colors --no-alias | grep -o 'v[0-9.]*')
RETURN_CODE=$?
if [ ${RETURN_CODE} -ne 0 ]
then
  echo "${RED}Failed to get node versions. Exiting.${RESET}${NEWLINE}"
  exit $RETURN_CODE;
fi

echo "${NEWLINE}${BOLD}Installed node versions${RESET}"
echo "${NODE_VERSIONS}${NEWLINE}"

# Prompt user to be sure.
while true; do
  read -r -p "${BOLD}Confirm removal of ${PACKAGE} from installed node versions?${RESET} (y/n) " yn
  case $yn in
    [Yy] ) break;;
    [Nn] ) exit;;
    * ) echo "Please answer (y)es or (n)o.";;
  esac
done

# Loop through node versions and run the uninstall command.
for NODE_VERSION in $NODE_VERSIONS; do
  CMD="nvm exec ${NODE_VERSION:1} npm uninstall -g ${PACKAGE}"
  echo -n "${BLUE}${BOLD}>${RESET} Removing ${PACKAGE} from node ${NODE_VERSION} ... ${RESET}"
  $CMD > /dev/null 2>&1

  RETURN_CODE=$?
  if [ ${RETURN_CODE} -ne 0 ]
  then
    echo "${RED}Failed${RESET}"
  else
    echo "${GREEN}Done${RESET}"
  fi
done
