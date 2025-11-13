help:
	cat Makefile
deps:
	if [[ -d indigo ]]; then cd indigo && git stash && git fetch --prune && git pull && git stash pop; else git clone https://github.com/bluesky-social/indigo; fi
diff:
	cd indigo && git diff
image:
	cd indigo && docker build -t blebbit/relay:latest -f ./cmd/relay/Dockerfile --platform linux/amd64 .