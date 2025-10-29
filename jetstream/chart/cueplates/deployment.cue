package cueplates

import (
  "github.com/blebbit/testnet/env"
)

apiVersion: "apps/v1"
kind: "Deployment"
metadata: {
  name: "jetstream"
  labels: {
    service: name
    envhash: env.jetstream.#hash
  }
}

let M = metadata

spec: {
  replicas: 1
  selector: matchLabels: { for k,v in M.labels if k != "envhash" { (k): v }}
  template: {
    metadata: labels: M.labels

    spec: {
      restartPolicy: "Always"

      containers: [{
        name: M.name
        image: "docker.io/blebbit/jetstream:latest"
        imagePullPolicy: "Never"
        envFrom:[{
          secretRef: name: "jetstream-env"
        }]
        volumeMounts: [{
          name: "data"
          mountPath: "/data"
        }]
      }]

      volumes: [{
        name: "data"
        persistentVolumeClaim: claimName: "jetstream-data"
      }]
    }
  }
}