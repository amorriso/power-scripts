cat configure-runner.sh 
#!/bin/bash

# Arguments
URL=""
TOKEN=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --url) URL="$2"; shift ;;
        --token) TOKEN="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$URL" ] || [ -z "$TOKEN" ]; then
    echo "Both --url and --token must be provided."
    exit 1
fi

# Extract repository name from URL
REPO_NAME=$(basename "$URL")
# Extract organization name from URL
ORG=$(echo "$URL" | awk -F'/' '{print $(NF-1)}')
RUNNER_DIR="/home/github-runner/${REPO_NAME}-actions-runner"

# 1. Set up the actions-runner folder and download the runner (as github-runner user)
export HOME=/home/github-runner
mkdir -p "$RUNNER_DIR" && cd "$RUNNER_DIR"
curl -o actions-runner-linux-x64-2.322.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.322.0/actions-runner-linux-x64-2.322.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.322.0.tar.gz
./config.sh --url "$URL" --token "$TOKEN"

# 2. Install and configure systemd service using the runner's svc.sh script (run as root)
sudo bash -c "cd \"$RUNNER_DIR\" && ./svc.sh install"

# 2.1 Modify the generated systemd service file to run as github-runner and use the correct WorkingDirectory
SERVICE_FILE="/etc/systemd/system/actions.runner.${ORG}-${REPO_NAME}.cactus.service"
sudo sed -i "s|^WorkingDirectory=.*|WorkingDirectory=${RUNNER_DIR}|" "$SERVICE_FILE"
sudo sed -i "s|^User=.*|User=github-runner|" "$SERVICE_FILE"

# 3. Reload systemd and start (restart) the runner service
SERVICE_NAME="actions.runner.${ORG}-${REPO_NAME}.cactus.service"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"
