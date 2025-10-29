package cueplates

import (
  "github.com/blebbit/testnet/env"
)

apiVersion: "apps/v1"
kind: "Deployment"
metadata: {
  name: "relay"
  labels: {
    service: name
    envhash: env.relay.#hash
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
          name: "DATABASE_URL"
          valueFrom: secretKeyRef: {
            key: "uri"
            name: "relay-pg-app"
          }
        }]
        command: ["sh", "-ec", """
          until pg_isready -d $DATABASE_URL; do
            sleep 1
          done
        """]
      }]
      containers: [{
        name: M.name
        image: "docker.io/blebbit/relay:latest"
        imagePullPolicy: "Never"
        envFrom:[{
          secretRef: name: "relay-env"
        }]
        env: [{
          name: "DATABASE_URL"
          valueFrom: secretKeyRef: {
            key: "uri"
            name: "relay-pg-app"
          }
        }]
        volumeMounts: [{
          name: "data"
          mountPath: "/data"
        }]
      }]
      restartPolicy: "Always"

      volumes: [{
        name: "data"
        persistentVolumeClaim: claimName: "relay-data"
      }]
    }
  }
}