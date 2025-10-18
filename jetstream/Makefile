help:
	cat Makefile
deps:
	if [[ -d jetstream ]]; then cd jetstream && git fetch --prune && git pull; else git clone https://github.com/bluesky-social/jetstream; fi
image:
	cd jetstream && docker build -t blebbit/jetstream:latest .
up:
	docker compose up -d

