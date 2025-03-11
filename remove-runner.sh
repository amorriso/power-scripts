#!/bin/bash
# Script to manage the deletion of GitHub Actions runner service
#
# Modes:
#   --list
#     Lists all service files in /etc/systemd/system that contain "actions" in their name.
#
#   --remove [service_file]
#     Stops, disables, and deletes the specified runner service file.
#     If no service_file is given and only one matching service is found (matching the pattern
#     'actions.runner.*.spider.service'), it is removed automatically.
#
# Usage:
#   ./manage_runner.sh --list
#   ./manage_runner.sh --remove actions.runner.<ORG>-<REPO>.spider.service
#   (or simply: ./manage_runner.sh --remove   if exactly one matching file exists)

usage() {
    echo "Usage:"
    echo "  $0 --list"
    echo "      List all service files in /etc/systemd/system that contain 'actions' in their name."
    echo ""
    echo "  $0 --remove [service_file]"
    echo "      Remove the specified runner service and clean up."
    echo "      If service_file is not provided and exactly one matching service is found"
    echo "      (pattern: actions.runner.*.spider.service), it will be removed automatically."
    exit 1
}

if [ "$#" -lt 1 ]; then
    usage
fi

if [ "$1" == "--list" ]; then
    echo "Listing services containing 'actions' in /etc/systemd/system:"
    sudo ls /etc/systemd/system | grep actions
    exit 0

elif [ "$1" == "--remove" ]; then
    SERVICE_FILE=""
    if [ "$#" -eq 2 ]; then
        SERVICE_FILE="$2"
    else
        # Attempt to auto-detect a single matching runner service file
        MATCHES=( $(sudo ls /etc/systemd/system | grep 'actions.runner.*.spider.service') )
        if [ ${#MATCHES[@]} -eq 0 ]; then
            echo "No runner service file found matching 'actions.runner.*.spider.service'."
            exit 1
        elif [ ${#MATCHES[@]} -eq 1 ]; then
            SERVICE_FILE="${MATCHES[0]}"
            echo "Found one runner service: $SERVICE_FILE"
        else
            echo "Multiple runner service files found:"
            for file in "${MATCHES[@]}"; do
                echo "  $file"
            done
            echo "Please specify the service file to remove as a second argument."
            exit 1
        fi
    fi

    echo "Stopping service $SERVICE_FILE..."
    sudo systemctl stop "$SERVICE_FILE"
    
    echo "Disabling service $SERVICE_FILE..."
    sudo systemctl disable "$SERVICE_FILE"
    
    echo "Removing service file /etc/systemd/system/$SERVICE_FILE..."
    sudo rm "/etc/systemd/system/$SERVICE_FILE"
    
    echo "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    echo "Resetting any failed state..."
    sudo systemctl reset-failed

    echo "Service $SERVICE_FILE has been removed."
    exit 0

else
    usage
fi

