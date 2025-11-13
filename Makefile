COMPONENTS = plc pds relay jetstream
TESTNET_NS = testnet
REGISTRY = tbd...

CUE_TAGS = 
expose:
	@echo "no exposure"
ifeq ($(TESTNET_EXPOSE),cloudflare)
CUE_TAGS=-t cloudflare -t TESTNET_DOMAIN=$(TESTNET_DOMAIN) -t CLOUDFLARE_TUNNEL_ID=$(CLOUDFLARE_TUNNEL_ID)
expose:
	@echo "cloudflare" $(CUE_TAGS)
endif
ifeq ($(TESTNET_EXPOSE),tailscale)
expose:
	@echo "tailscale"
endif

tags:
	@echo "'$(CUE_TAGS)'"

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


DIFFS = $(addsuffix .diff,$(COMPONENTS))
.PHONY: diffs $(DIFFS)
diffs: $(DIFFS)
$(DIFFS):
	make -C $(patsubst %.diff,%,$@) diff


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

k8s.operators.repos: k8s.operators.prep
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo add tailscale https://pkgs.tailscale.com/helmcharts
	helm repo add cloudflare https://cloudflare.github.io/helm-charts
	helm repo add external-dns https://kubernetes-sigs.github.io/external-dns
	helm repo add cnpg https://cloudnative-pg.github.io/charts
	helm repo update
.PHONY: k8s.operators.repos

k8s.operators.prep:
	-kubectl create namespace operators
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

k8s.operators.external-dns:
	helm upgrade --install \
		external-dns external-dns/external-dns \
		--namespace=operators \
		--set sources[0]=ingress \
		--set policy=sync \
		--set provider.name=cloudflare \
		--set env[0].name=CF_API_TOKEN \
		--set env[0].valueFrom.secretKeyRef.name=cloudflare-api-key \
		--set env[0].valueFrom.secretKeyRef.key=apiKey \
		--wait
.PHONY: k8s.operators.external-dns

k8s.operators.cloudflare:
	make k8s.operators.ingress-nginx
	make k8s.operators.external-dns

	kubectl create secret generic cloudflare-api-key \
		--from-literal=apiKey=$(CLOUDFLARE_APIKEY) \
		--from-literal=email=$(CLOUDFLARE_EMAIL) \
		--namespace=operators
	kubectl create secret generic cloudflare-tunnel-creds \
		--from-file=credentials.json=$(CLOUDFLARE_JSON_CREDS) \
		--namespace=operators

	cue export dmz/tunnel-values.cue \
	  -t TESTNET_DOMAIN=$(TESTNET_DOMAIN) \
	  -t CLOUDFLARE_TUNNEL_NAME=$(CLOUDFLARE_TUNNEL_NAME) \
	  -t CLOUDFLARE_TUNNEL_ID=$(CLOUDFLARE_TUNNEL_ID) \
		-o tunnel-values.yaml
	helm upgrade --install \
		cloudflare cloudflare/cloudflare-tunnel \
		--namespace=operators \
		--values=tunnel-values.yaml
		--wait
	rm tunnel-values.yaml
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

SERVICES = $(addsuffix .service,$(COMPONENTS))
$(SERVICES): 
	if [ -d ./$(patsubst %.service,%,$@)/chart/cueplates ]; then \
	cd  ./$(patsubst %.service,%,$@)/chart && \
	echo "apiVersion: v1" > ./templates/cueplates.yaml && \
	echo "kind: List" >> ./templates/cueplates.yaml && \
	echo "items:" >> ./templates/cueplates.yaml && \
	cue export $(CUE_TAGS) ./cueplates --out yaml -e '[for _,v in helm {v}]' >> ./templates/cueplates.yaml; \
	fi
	cd $(patsubst %.service,%,$@)/chart && \
	helm upgrade --install \
	  $(patsubst %.service,%,$@) ./ \
	  --namespace $(TESTNET_NS) \
	  --wait
.PHONY: $(SERVICES)

DELETES = $(addsuffix .delete,$(COMPONENTS))
$(DELETES): 
	cd $(patsubst %.delete,%,$@)/chart && \
	helm uninstall $(patsubst %.delete,%,$@) \
	  --namespace $(TESTNET_NS)
.PHONY: $(DELETES)



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
