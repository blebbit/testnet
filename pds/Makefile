help:
	cat Makefile
deps:
	if [[ -d atproto ]]; then cd atproto && git fetch --prune && git pull; else git clone https://github.com/blebbit/atproto; fi
image:
	cd atproto && docker build -t blebbit/pds:latest -f ./services/pds/Dockerfile .
up:
	docker compose up -d

