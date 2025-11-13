help:
	cat Makefile
deps:
	if [[ -d atproto ]]; then rm -rf atproto; fi && git clone https://github.com/blebbit/atproto;
diff:
	cd atproto && git diff
image:
	cd atproto && docker build -t blebbit/pds:latest -f ./services/pds/Dockerfile --platform linux/amd64 .
up:
	docker compose up -d

