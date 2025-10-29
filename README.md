# TestNet

Our setup for building an independent ATProtocol network.
It runs the same code as mainnet, production built and configured.

The intention is to run a testnet where the atmosphere can do wild experiments.
For example, this setup runs our Permissioned PDS so we can make sure 
our patches are backwards compatible with mainnet and the protocol.

Following the steps below, you can create your own testnet or independent atproto network.
One the foundation settles, we will open our testnet to others.

### Setup

```
# build the images
make images

# initialize an env
make env
```

> [!WARNING]
> You need to adjust the `<component>.env` files. Most should be straight forward.
> Follow the [PDS setup guide](https://github.com/bluesky-social/pds/blob/main/README.md) for that one...
> Depening on how you wish to expose the services, various ENV files will need adjusting. (mainly the PDS again)


#### k3s / kubernetes setup

There are two methods, docker compose and kubernetes.
If you want an easy to use, single-node setup to try it out,
we recommend k3s, which handles all the dependencies,
has good defaults, and starts in about 30s.
It also supports multi-node setups

- https://docs.k3s.io/quick-start
- https://dev.to/olymahmud/resolving-the-k3s-config-file-permission-denied-error-27e5

```sh
# install k3s
curl -sfL https://get.k3s.io | sh -

# make config file as user
export KUBECONFIG=~/.kube/config
mkdir -p ~/.kube
sudo k3s kubectl config view --raw > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"
```


### Domains

This setup uses a Cloudflare tunnel with the following settings

- `plc.<domain>` -> `:7000`
- `relay.<domain>` -> `:7001`
- `jetstream.<domain>` -> `:7002`
- `pds.<domain>` -> `:6000`


### Lifecycle the network

#### With Docker Compose

```sh
make up
make down
make clean
```

#### With Kubernetes

> [!WARNING]
> If the k3s machine is not the same as this repo cloned,
> you'll need to push the images to your preferred registry or copy them over manually.


> [!DANGER]
> You can expose the services to the public internet if you wish.
> This should be done before you run the following commands.
> Cloudflare Tunnels was selected initially, other methods should work as well (i.e. tailscale network or dns + reverse proxy + certbot).

```sh
# Set the expose method, empty means not exposed, see options below
export TESTNET_EXPOSE=

# pick a top-level domain you control
export TESTNET_DOMAIN=example.com

# prepare kubernetes
make k8s.operators

# prepare namespace
make k8s.namespace

# install testnet services
make plc.service
make relay.service
make jetstream.service
make pds.service
```

#### Cloudflare setup

Follow this tutorial: https://itnext.io/exposing-kubernetes-apps-to-the-internet-with-cloudflare-tunnel-ingress-controller-and-e30307c0fcb0

You only need to follow these sections and set the ENV vars below.
The scripts will handle the operator installs and secret creation.

Sections

0. Pick a top-levl domain name you own
1. Cloudflare Token (apikey & email)
2. Create the tunnel (tunnel-name/id & json_creds)
3. Change Cloudflare TLS mode

```sh
export TESTNET_EXPOSE=cloudflare
export CLOUDFLARE_APIKEY=...
export CLOUDFLARE_EMAIL=...
export CLOUDFLARE_TUNNEL_NAME=testnet
export CLOUDFLARE_TUNNEL_ID=...
export CLOUDFLARE_JSON_CREDS=/home/bob/.cloudflared/<tunnel-id>.json
```


#### Tailscale setup

tbd

```sh
export TESTNET_EXPOSE=tailscale
export TAILSCALE_CLIENT=...
export TAILSCALE_SECRET=...
```

### Create accounts

You can use the normal pdsadmin scripts,
copied into the local pds directory for convenience.
The `goat` tool now has these features too!


## References, Notes, and Links

- https://tangled.org/@smokesignal.events/localdev
- https://github.com/bluesky-social/atproto/tree/main/packages/dev-env
- [old Bluesky doc for their, now retired, "testnet" (sandbox)](https://docs.bsky.app/blog/federation-sandbox), inspiration for similar doc for this project
- Cloudflare Setup: https://itnext.io/exposing-kubernetes-apps-to-the-internet-with-cloudflare-tunnel-ingress-controller-and-e30307c0fcb0
- Tailscale Setup: https://tailscale.com/kb/1236/kubernetes-operator | https://tailscale.com/kb/1439/kubernetes-operator-cluster-ingress

