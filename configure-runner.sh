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
RUNNER_DIR="/home/github-runner/${REPO_NAME}-actions-runner"

# 1. Set up the actions-runner folder and download the runner (as github-runner user)
sudo -u github-runner bash <<EOF
mkdir -p $RUNNER_DIR && cd $RUNNER_DIR
curl -o actions-runner-linux-x64-2.320.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.320.0/actions-runner-linux-x64-2.320.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.320.0.tar.gz
./config.sh --url $URL --token $TOKEN
EOF

# 2. Configure systemd service
sudo bash -c "cat <<EOT > /etc/systemd/system/${REPO_NAME}-github-runner.service
[Unit]
Description=GitHub Actions Runner for $REPO_NAME
After=network.target

[Service]
ExecStart=$RUNNER_DIR/run.sh
User=github-runner
WorkingDirectory=$RUNNER_DIR
Restart=always

[Install]
WantedBy=multi-user.target
EOT"

# 3. Reload systemd and start the runner service
sudo systemctl daemon-reload
sudo systemctl enable ${REPO_NAME}-github-runner
sudo systemctl start ${REPO_NAME}-github-runner
