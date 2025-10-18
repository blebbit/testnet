help:
	cat Makefile
deps:
	if [[ -d indigo ]]; then cd indigo && git fetch --prune && git pull; else git clone https://github.com/bluesky-social/indigo; fi
prep:
image:
	cd indigo && docker build -t blebbit/relay:latest -f ./cmd/relay/Dockerfile .