package cueplates

import (
  "github.com/blebbit/testnet/env"
)

apiVersion: "apps/v1"
kind: "Deployment"
metadata: {
  name: "plc"
  labels: {
    service: name
    envhash: env.plc.#hash
  }
}

let M = metadata

spec: {
  replicas: 1
  selector: matchLabels: { for k,v in M.labels if k != "envhash" { (k): v }}
  template: {
    metadata: labels: M.labels

    spec: {
      initContainers: [{
        name: "wait-db"
        image: "postgres"
        env: [{
          name: "DB_URL"
          valueFrom: secretKeyRef: {
            key: "uri"
            name: "plc-pg-app"
          }
        }]
        command: ["sh", "-ec", """
          until pg_isready -d $DB_URL; do
            sleep 1
          done
        """]
      }]
      containers: [{
        name: M.name
        image: "docker.io/blebbit/plc:latest"
        imagePullPolicy: "Never"
        envFrom:[{
          secretRef: name: "plc-env"
        }]
        env: [{
          name: "DB_URL"
          valueFrom: secretKeyRef: {
            key: "uri"
            name: "plc-pg-app"
          }
        },{
          name: "DB_MIGRATE_URL"
          valueFrom: secretKeyRef: {
            key: "uri"
            name: "plc-pg-app"
          }
        }]
      }]
      restartPolicy: "Always"
    }
  }
}