help:
	cat Makefile
deps:
	if [[ -d did-method-plc ]]; then cd did-method-plc && git fetch --prune && git pull; else git clone https://github.com/did-method-plc/did-method-plc; fi
image:
	cd did-method-plc && docker build -t blebbit/plc:latest -f packages/server/Dockerfile --platform linux/amd64 .
up:
	docker compose up -d

