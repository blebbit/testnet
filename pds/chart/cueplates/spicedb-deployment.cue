package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: spicedb_deployment: k8s.Deployment & {
  #name: "spicedb"

  spec: {
    replicas: 1
    template: {
      spec: {
        initContainers: [{
          name: "wait-db"
          image: "postgres"
          env: [{
            name: "DB_URL"
            valueFrom: secretKeyRef: {
              key: "uri"
              name: "pds-pg-app"
            }
          }]
          command: ["sh", "-ec", """
            until pg_isready -d $DB_URL; do
              sleep 1
            done
          """]
        },{
          name: "mig-db"
          image: "authzed/spicedb:latest"
          imagePullPolicy: "IfNotPresent"
          command: ["spicedb", "migrate", "head"]
          env: [{
            name: "SPICEDB_DATASTORE_ENGINE"
            value: "postgres"
          },{
            name: "SPICEDB_DATASTORE_CONN_URI"
            valueFrom: secretKeyRef: {
              key: "uri"
              name: "pds-pg-app"
            }
          }]
        }]
        containers: [{
          name: "pds-spicedb"
          image: "docker.io/authzed/spicedb:latest"
          imagePullPolicy: "IfNotPresent"
          command: ["spicedb", "serve", "--http-enabled"]
          env: [{
            name: "SPICEDB_GRPC_PRESHARED_KEY"
            valueFrom: secretKeyRef: {
              key: "PDS_SPICEDB_TOKEN"
              name: "pds-env"
            }
          },{
            name: "SPICEDB_DATASTORE_ENGINE"
            value: "postgres"
          },{
            name: "SPICEDB_DATASTORE_CONN_URI"
            valueFrom: secretKeyRef: {
              key: "uri"
              name: "pds-pg-app"
            }
          }]
          ports: [{
            name: "grpc"
            containerPort: 50051
          },{
            name: "http"
            containerPort: 8080
          },{
            name: "prometheus"
            containerPort: 9090
          }]
        }]
      }
    }
  }
}