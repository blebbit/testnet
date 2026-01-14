package compose

version: "3"

//
// Helpers
//
#pg: {
  name: string
  embed: {
    // setup a volume
    volumes: "\(name)_pgdata": {}

    // postgres container
    services: "\(name)_pg": {
      image: "postgres:16"
      ports: ["5432"]
      environment: [
        "POSTGRES_DB=\(name)",
        "POSTGRES_USER=\(name)",
        "POSTGRES_PASSWORD=\(name)",
      ]
      volumes: [
        "\(name)_pgdata:/var/lib/postgresql/data",
      ]
      healthcheck: {
        test: "pg_isready -U \(name)"
        interval: "500ms"
        timeout: "10s"
        retries: 20
      }
    }

    // service deps on
    services: (name): {
      depends_on: "\(name)_pg": {
        condition: "service_healthy"
        restart: true
      }
    }
  }
}


//
// PLC
//
(#pg & { name: "plc"}).embed
services: plc: {
  image: "blebbit/plc:latest"
  ports: ["7000:3000"]
  restart: "always"
  env_file: ["./env/plc.env"]
}

//
// Relay
//
(#pg & { name: "relay"}).embed
services: relay: {
  image: "blebbit/relay:latest"
  ports: ["7001:3000"]
  restart: "always"
  env_file: ["./env/relay.env"]
  volumes: [
    "relay_data:/data",
  ]
  depends_on: {
    plc: condition: "service_started"
  }
}
volumes: {
  relay_data: {}
}


//
// Jetstream
//
services: jetstream: {
  image: "blebbit/jetstream:latest"
  ports: ["7002:7002"]
  restart: "always"
  env_file: ["./env/jetstream.env"]
  volumes: [
    "jetstream_data:/data",
  ]
  depends_on: {
    plc: condition: "service_started"
    relay: condition: "service_started"
  }
}
volumes: {
  jetstream_data: {}
}


//
// SpiceDB (for the PDS)
//
(#pg & { name: "spicedb"}).embed
services: spicedb_pg_init: {
  image: "postgres:16"
  restart: "on-failure:3"
  command: "psql postgres://spicedb:spicedb@spicedb_pg:5432/spicedb?sslmode=disable -c \"ALTER SYSTEM SET track_commit_timestamp = on;\""
  depends_on: {
    "spicedb_pg": {
      condition: "service_healthy"
      restart: true
    }
  }
}
services: spicedb_pg_mig: {
  image: "authzed/spicedb:latest"
  command: "migrate head"
  restart: "on-failure"
  environment: [
    "SPICEDB_DATASTORE_ENGINE=postgres",
    "SPICEDB_DATASTORE_CONN_URI=postgres://spicedb:spicedb@spicedb_pg:5432/spicedb?sslmode=disable",
  ]
  depends_on: {
    spicedb_pg: {
      condition: "service_healthy"
      restart: true
    }
    spicedb_pg_init: condition: "service_completed_successfully"
  }
}
services: spicedb: {
  image: "authzed/spicedb"
  command: "serve --http-enabled"
  restart: "always"
  ports: [
    "8080",
    "9090",
    "50051",
  ]
  environment: [
    "SPICEDB_GRPC_PRESHARED_KEY=testnet-spicedb",
    "SPICEDB_DATASTORE_ENGINE=postgres",
    "SPICEDB_DATASTORE_CONN_URI=postgres://spicedb:spicedb@spicedb_pg:5432/spicedb?sslmode=disable",
  ]
  depends_on: {
    spicedb_pg: {
      condition: "service_healthy"
      restart: true
    }
    spicedb_pg_mig: condition: "service_completed_successfully"
  }

}

//
// PDS
//
services: pds: {
  image: "blebbit/pds:latest"
  ports: ["6000:3000"]
  restart: "always"
  env_file: ["./env/pds.env"]
  volumes: [
    "pds_data:/app/data",
    "pds_blobs:/app/blobs",
  ]
  depends_on: {
    plc: condition: "service_started"
    // relay: condition: "service_started"
    spicedb: condition: "service_started"
  }
}
volumes: {
  pds_data: {}
  pds_blobs: {}
}


//
// Admin
//

//
// Log-Mon
//
