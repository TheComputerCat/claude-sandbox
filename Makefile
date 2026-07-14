IMAGE_NAME  := claude-sandbox
CLAUDE_HOME := claude-home
SSH_PORT    := 2222

.PHONY: help build start stop run claude

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "  build   Build the Docker image"
	@echo "  start   Start Colima"
	@echo "  stop    Stop Colima"
	@echo "  run     Start the container"
	@echo "  claude  Start Colima + container + Claude Code"

build:
	docker --context colima-claude build --build-arg SSH_PUBLIC_KEY="$$(cat ~/.ssh/claude_sandbox.pub)" -t $(IMAGE_NAME) .

start:
	colima start -p claude --vm-type vz --vz-rosetta --cpu 2 --memory 4 --disk 20 --mount=none

stop:
	colima stop -p claude

_run:
	docker --context colima-claude run -d --rm \
	-v "$(CLAUDE_HOME):/home/claude" \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-p "$(SSH_PORT):22" \
	--name claude-sandbox \
	$(IMAGE_NAME)

run: _run

claude: start _run
	docker --context colima-claude exec -it claude-sandbox su - claude -c "claude"