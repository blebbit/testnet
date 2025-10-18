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
make init
```

> [!WARNING]
> You need to adjust the `<component>.env` files. Most should be straight forward.
> Follow the [PDS setup guide](https://github.com/bluesky-social/pds/blob/main/README.md) for that one...

### Domains

This setup uses a Cloudflare tunnel with the following settings

- `plc.<domain>` -> `:7000`
- `relay.<domain>` -> `:7001`
- `jetstream.<domain>` -> `:7002`
- `pds.<domain>` -> `:6000`


### Lifecycle the network

This uses docker compose

```
make up
make down
make clean
```


### Create accounts

You can use the normal pdsadmin scrips,
copied into the local pds directory for convenience.