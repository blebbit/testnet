@experiment(aliasv2)
package main

import (
	"github.com/hofstadter-io/hof/catalogs/env/bases"
	"github.com/hofstadter-io/hof/catalogs/env/packs"
	// "github.com/hofstadter-io/hof/catalogs/env/utils"
	"github.com/hofstadter-io/hof/schemas/env"

	"github.com/verdverm/testnet/patches"
)

// let root = self

_flags: {
	ppds: bool | *false @tag(ppds,type=bool)
}

cmd: {
	[string]~(k1,_): env.#Cmd & {
		// @env(), name: k1
		tasks: [string]~(k2,_): {
			steps: [...[...{name: "\(k1).\(k2)"}]]
		}
	}

	init: tasks: {
		secrets: {
			steps: [[
				env.#ExportDir & {
					@env()
					path: "./env"
					sources: [env.#Dir & {
						path: "/work"
						sources: [
							env.#Container & {
								from: bases.debian13.default
								steps: [env.Bash & {script: _relay}, env.Bash & {script: _pds}]
							},
						]
					}]
				},
			]]

			_relay: """
				(
				  echo RELAY_ADMIN_PASSWORD=$(openssl rand -hex 32 | tr -d '\n')
				) > relay.secret.env
				"""
			_pds: """
				(
				  echo PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX=$(openssl rand -hex 32 | tr -d '\n')
				  echo PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=$(openssl rand -hex 32 | tr -d '\n')
				  echo PDS_DPOP_SECRET=$(openssl rand -hex 32 | tr -d '\n')
				  echo PDS_JWT_SECRET=$(openssl rand -hex 32 | tr -d '\n')
				  echo PDS_ADMIN_PASSWORD=$(openssl rand -hex 32 | tr -d '\n')
				  echo PDS_SPICEDB_TOKEN=$(openssl rand -hex 32 | tr -d '\n')
				) > pds.secret.env
				"""
		}
	}
}

testnet: {
	// @atproto PLC
	plc: {
		// supporting components
		config: env.#HostFile & {path: "./env/plc.env"}
		(packs.databases.Postgres & {#name: "plc"}).#out
		postgres: {@env(), #hof: id: "plc-pg", #hof: metadata: name: #hof.id}

		// configured to run
		runner: env.#Container & {
			from: builds.plc.ctr
			steps: [
				env.BindService & {service: plc.postgres},
				env.EnvFile & {file: plc.config},
			]
		}
		// service version
		service: env.#Service & {
			@env(), #hof: id: "plc-svc", #hof: metadata: name: #hof.id
			hostname: "plc"
			ports: [{port: 3000, frontend: 4003}]
			source: plc.runner
		}
	}

	// @atproto Relay
	relay: {
		// supporting components
		secret: env.#Secret & {name: "relay-secret", source: "file://env/relay.secret.env"}
		config: env.#HostFile & {path: "./env/relay.env"}
		data: env.#Cache & {name: "relay-data"}
		(packs.databases.Postgres & {#name: "relay"}).#out
		postgres: {@env(), #hof: id: "relay-pg", #hof: metadata: name: #hof.id}

		// configured to run
		runner: env.#Container & {
			@env(), #hof: id: "relay-run", #hof: metadata: name: #hof.id
			from: builds.relay.ctr
			steps: [
				env.BindService & {service: plc.service},
				env.BindService & {service: relay.postgres},
				env.Mount & {path: "/data", source: relay.data},
				env.SecretFile & {file: relay.secret},
				env.EnvFile & {file: relay.config},
			]
		}

		// service version
		service: env.#Service & {
			@env(), #hof: id: "relay-svc", #hof: metadata: name: #hof.id
			hostname: "relay"
			ports: [{port: 3000, frontend: 4002}]
			source: relay.runner
		}
	}

	// @atproto Jetstream
	jetstream: {
		config: env.#HostFile & {path: "./env/jetstream.env"}
		data: env.#Cache & {name: "jetstream-data"}
		runner: env.#Container & {
			@env(), #hof: id: "jetstream-run", #hof: metadata: name: #hof.id
			from: builds.jetstream.ctr
			steps: [
				env.BindService & {service: plc.service},
				env.BindService & {service: relay.service},
				env.Mount & {path: "/data", source: jetstream.data},
				env.EnvFile & {file: jetstream.config},
			]
		}
		service: env.#Service & {
			@env(), #hof: id: "jetstream-svc", #hof: metadata: name: #hof.id
			hostname: "jetstream"
			ports: [{port: 3000, frontend: 4001}]
			source: jetstream.runner
		}
	}

	// @bluesky/pds or @blebbit/permissioned-pds
	pds: {
		config: env.#HostFile & {path: "./env/pds.env"}
		// secret: env.#HostFile & {path: "./env/pds.secret.env"}
		secret: env.#Secret & {name: "pds-secret", source: "file://env/pds.secret.env"}
		data: env.#Cache & {name: "pds-data"}
		blobs: env.#Cache & {name: "pds-blobs"}
		runner: env.#Container & {
			from: _ | *builds.pds.ctr
			if _flags.ppds {
				from: builds.ppds.ctr
			}
			steps: [
				env.BindService & {service: plc.service},
				env.BindService & {service: relay.service},
				if _flags.ppds { env.BindService & {service: pds.spicedb.svc} },
				env.Mount & {path: "/app/data", source: pds.data},
				env.Mount & {path: "/app/blobs", source: pds.blobs},
				env.SecretFile & {file: pds.secret},
				env.EnvFile & {file: pds.config},
			]
		}
		service: env.#Service & {
			@env(), #hof: id: "pds-svc", #hof: metadata: name: #hof.id
			hostname: "pds"
			ports: [{port: 3000, frontend: 4000}]
			source: runner
			args: ["node", "--heapsnapshot-signal=SIGUSR2", "--enable-source-maps", "--require=./tracer.js", "index.js"]
		}

		if _flags.ppds == true {
			spicedb: {
				postgres?: {@env(), #hof: id: "pds-spicedb-pg", #hof: metadata: name: #hof.id}
				// postgresVolume?: {@env(), #hof: id: "pds-spicedb-pg-data", #hof: metadata: name: #hof.id}
				(packs.databases.Postgres & {#name: "pds-spicedb"}).#out
				svc: env.#Service & {
					@env(pds-spicedb-svc)
					hostname: "pds-spicedb"
					ports: [{port: 8080}, {port: 9090}, {port: 50051}]
					args: ["serve", "--http-enabled"]
					useEntrypoint: true
					source: spicedb.ctr
				}
				ctr: env.#Container & {
					@env(pds-spicedb-ctr)
					from: "authzed/spicedb:latest"
					envs: {
						SPICEDB_GRPC_PRESHARED_KEY: "testnet-spicedb"
						SPICEDB_DATASTORE_ENGINE:   "postgres"
						SPICEDB_DATASTORE_CONN_URI: "postgres://pds-spicedb:pds-spicedb@pds-spicedb-pg:5432/pds-spicedb?sslmode=disable"
					}
					steps: [
						env.BindService & {service: spicedb.postgres},
						env.Exec & {args: ["migrate", "head"], useEntrypoint: true},
					]
				}
			}
		}
	}
}

builds: {
	// give things consistent names
	[string]~(group,_): [string]~(subgroup,_): {
		@env()
		#hof: id: "\(group)-\(subgroup)"
		#hof: metadata: name: "\(group)-\(subgroup)"
	}

	repos: {
		verdverm: env.#GitRepo & {url: "https://github.com/verdverm/atproto"}
		atproto: env.#GitRepo & {url: "https://github.com/bluesky-social/atproto"}
		didplc: env.#GitRepo & {url: "https://github.com/did-method-plc/did-method-plc"}
		indigo: env.#GitRepo & {url: "https://github.com/bluesky-social/indigo"}
		jetstream: env.#GitRepo & {url: "https://github.com/bluesky-social/jetstream"}
	}
	ppds: {
		code: env.#Dir & {sources: [repos.verdverm]}
		ctr: env.#DockerBuild & {source: code, dockerfile: "services/pds/Dockerfile"}
	}
	pds: {
		code: env.#Dir & {sources: [repos.atproto]}
		ctr: env.#DockerBuild & {source: code, dockerfile: "services/pds/Dockerfile"}
	}
	plc: {
		code: env.#Dir & {sources: [repos.didplc]}
		// patch
		fixd: env.#Dir & {sources: [repos.didplc], patch: patches.plc}
		ctr: env.#DockerBuild & {source: fixd, dockerfile: "packages/server/Dockerfile"}
	}
	relay: {
		code: env.#Dir & {sources: [repos.indigo]}
		// patch
		fixd: env.#Dir & {sources: [repos.indigo], patch: patches.relay}
		ctr: env.#DockerBuild & {source: fixd, dockerfile: "cmd/relay/Dockerfile"}
	}
	jetstream: {
		code: env.#Dir & {sources: [repos.jetstream]}
		ctr: env.#DockerBuild & {source: code}
	}

	// hack: {
	// 	ctr: env.#Container

	// 	// images
	// 	dev: env.#Container & {
	// 		from: ctr
	// 		steps: [
	// 			env.User & {name: "root"},
	// 			env.Workdir & {path: "/app"},
	// 			env.Envfile & {file: testnet.plc.config},
	// 			env.BindService & {service: testnet.plc.postgres},
	// 			env.Entrypoint & {args: ["sh"]},
	// 			env.DefaultTerm & {args: ["sh"]},
	// 		]
	// 	}
	// }
}
