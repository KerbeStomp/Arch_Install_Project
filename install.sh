#!/bin/bash

# set paths
INSTALL_DIR=$(dirname "$0")
SCRIPTS="$INSTALL_DIR"/components

MAIN="$INSTALL_DIR"/main.sh
ERROR_CODES="$INSTALL_DIR"/error_codes.sh

# read permissions for error codes
echo -e "\nEnabling read permissions for error codes."
if chmod +r "$ERROR_CODES"; then
    echo -e "\tSuccessfully accessed error codes."
else
    echo -e "\tUnable to access error codes..."
    return 1
fi

# execute permissions for component scripts
echo -e "\nEnabling execute permissions for components."
for script in "$SCRIPTS"/*.sh; do
    if chmod +x "$script"; then
        echo -e "\tSuccessfully gave $(basename "$script") permissions."
    else
        echo -e "\tUnable to give $(basename "$script") permissions..."
        return 1
    fi
done



# execute permissions for main script
echo -e "\nEnabling execute permissions for main script."
if chmod +x "$MAIN"; then
    echo -e "\tSuccessfully gave main script execute permissions."
else
    echo -e "\tUnable to give main execute permissions..."
    return 1
fi

echo "About to call main script..."
"$MAIN"