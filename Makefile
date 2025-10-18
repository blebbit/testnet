COMPONENTS = plc pds relay jetstream

.PHONY: help help/%
help:
	cat Makefile
help/%:
	make -C $(patsubst help/%,%,$@) help

%.yaml: %.cue
	cue export $(patsubst %.yaml,%,$@).cue -fo $@

DEPS = $(addsuffix .deps,$(COMPONENTS))
.PHONY: deps $(DEPS)
deps: $(DEPS)
$(DEPS): 
	make -C $(patsubst %.deps,%,$@) deps

IMGS = $(addsuffix .image,$(COMPONENTS))
.PHONY: images $(IMGS)
images: deps $(IMGS)
$(IMGS):
	make -C $(patsubst %.image,%,$@) image

PREP = $(addsuffix .prep,$(COMPONENTS))
.PHONY: prep $(PREP)
prep: $(PREP)
$(PREP): 
	make -C $(patsubst %.prep,%,$@) prep

.PHONY: env
env:
	cp */*.env .


.PHONY: init
init: prep env

.PHONY: up down clean
up: docker-compose.yaml
	docker compose up -d
down:
	docker compose down
clean: down
	docker volume rm \
	 testnet_plc_pgdata \
	 testnet_relay_pgdata \
	 testnet_jetstream_data \
	 testnet_pds_data \
	 testnet_pds_blobs \
	 testnet_spicedb_pgdata