help:
	cat Makefile
deps:
	if [[ -d did-method-plc ]]; then cd did-method-plc && git stash && git fetch --prune && git pull && git stash pop; else git clone https://github.com/did-method-plc/did-method-plc; fi
diff:
	cd did-method-plc && git diff
image:
	cd did-method-plc && docker build -t blebbit/plc:latest -f packages/server/Dockerfile --platform linux/amd64 .
up:
	docker compose up -d

