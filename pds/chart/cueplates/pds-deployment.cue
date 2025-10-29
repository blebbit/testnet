package cueplates

import (
  "github.com/blebbit/testnet/env"
)

apiVersion: "apps/v1"
kind: "Deployment"
metadata: {
  name: "pds"
  labels: {
    service: name
    envhash: env.pds.#hash
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
      // initContainers: [{
      //   name: "wait-spicedb"
      //   image: "postgres"
      //   env: [{
      //     name: "DB_URL"
      //     valueFrom: secretKeyRef: {
      //       key: "uri"
      //       name: "plc-pg-app"
      //     }
      //   }]
      //   command: ["sh", "-ec", """
      //     until pg_isready -d $DB_URL; do
      //       sleep 1
      //     done
      //   """]
      // }]
      containers: [{
        name: M.name
        image: "docker.io/blebbit/pds:latest"
        imagePullPolicy: "Never"
        envFrom:[{
          secretRef: name: "pds-env"
        }]
        volumeMounts: [{
          name: "data"
          mountPath: "/app/data"
        },{
          name: "blobs"
          mountPath: "/app/blobs"
        }]
      }]

      volumes: [{
        name: "data"
        persistentVolumeClaim: claimName: "pds-data"
      },{
        name: "blobs"
        persistentVolumeClaim: claimName: "pds-blobs"
      }]
    }
  }
}