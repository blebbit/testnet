COMPONENTS = plc pds relay jetstream
TESTNET_NS = testnet
REGISTRY = tbd...

.PHONY: help help/%
help:
	cat Makefile
help/%:
	make -C $(patsubst help/%,%,$@) help

%.yaml: %.cue
	cue export $(patsubst %.yaml,%,$@).cue -fo $@

# fetching source, building images
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


# initial env files
.PHONY: env
env:
	cp */*.env .


# docker compose related
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

# kubernetes related
k8s.operators: k8s.operators.prep k8s.operators.repos k8s.operators.cnpg
.PHONY: k8s.operators

k8s.operators.repos:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo add tailscale https://pkgs.tailscale.com/helmcharts
	helm repo add cloudflare https://cloudflare.github.io/helm-charts
	helm repo add cnpg https://cloudnative-pg.github.io/charts
	helm repo update
.PHONY: k8s.operators

k8s.operators.prep:
	kubectl create namespace operators
.PHONY: k8s.operators.prep

k8s.operators.tailscale:
	helm upgrade --install \
		tailscale tailscale/tailscale-operator \
		--namespace=operators \
		--set-string oauth.clientId="${TAILSCALE_CLIENT}" \
		--set-string oauth.clientSecret="${TAILSCALE_SECRET}" \
		--wait
.PHONY: k8s.operators.tailscale

k8s.operators.ingress-nginx:
	helm upgrade --install \
		ingress-nginx ingress-nginx/ingress-nginx \
		--namespace=operators \
		--set controller.service.type=ClusterIP \
		--set controller.ingressClassResource.default=true \
		--wait
.PHONY: k8s.operators.ingress-nginx

k8s.operators.cloudflare: k8s.operators.ingress-nginx
	helm upgrade --install \
		cloudflare cloudflare/cloudflare-tunnel \
		--namespace=$(TESTNET_NS) \
		--set-string oauth.clientId="${TAILSCALE_CLIENT}" \
		--set-string oauth.clientSecret="${TAILSCALE_SECRET}" \
		--wait
.PHONY: k8s.operators.cloudflare

# https://github.com/cloudnative-pg/charts
k8s.operators.cnpg:
	helm upgrade --install \
		cnpg cnpg/cloudnative-pg \
		--namespace=operators \
		--wait
.PHONY: k8s.operators.cnpg

k8s.namespace:
	kubectl create namespace $(TESTNET_NS)
.PHONY: k8s.namespace

SECRETS = $(addsuffix .secret,$(COMPONENTS))
.PHONY: k8s.secrets $(SECRETS)
k8s.secrets: $(SECRETS)
$(SECRETS): 
	kubectl create secret generic $(patsubst %.secret,%,$@)-env \
	  --namespace $(TESTNET_NS) \
	  --from-env-file=$(patsubst %.secret,%,$@).env

SERVICES = $(addsuffix .service,$(COMPONENTS))
.PHONY: k8s.services $(SERVICES)
k8s.services: $(SERVICES)
$(SERVICES): 
	@if [ -d ./$(patsubst %.service,%,$@)/chart/cueplates ]; then \
	cd  ./$(patsubst %.service,%,$@)/chart/cueplates && \
	for f in `ls *.cue`; do cue export $$f -fo ../templates/$${f%.cue}.yaml; done \
	fi
	cd $(patsubst %.service,%,$@)/chart && \
	helm upgrade --install \
	  $(patsubst %.service,%,$@) ./ \
	  --namespace $(TESTNET_NS) \
	  --wait

DELETES = $(addsuffix .delete,$(COMPONENTS))
.PHONY: k8s.delete $(DELETES)
k8s.services: $(DELETES)
$(DELETES): 
	cd $(patsubst %.delete,%,$@)/chart && \
	helm uninstall $(patsubst %.delete,%,$@) \
	  --namespace $(TESTNET_NS) \



# K3S_REMOTE="some ip or hostname you can ssh to"
K3S_REMOTE=tungsten-lan

PUSH = $(addsuffix .push,$(COMPONENTS))
.PHONY: push $(PUSH)
push: $(PUSH)
$(PUSH):
	docker save blebbit/$(patsubst %.push,%,$@) -o ./$(patsubst %.push,%,$@).tar
	scp ./$(patsubst %.push,%,$@).tar $(K3S_REMOTE):$(patsubst %.push,%,$@).tar
	ssh $(K3S_REMOTE) -- sudo ctr -n k8s.io image import ./$(patsubst %.push,%,$@).tar
	rm ./$(patsubst %.push,%,$@).tar
