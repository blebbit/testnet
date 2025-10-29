package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: deployment: k8s.Deployment & {
  #name: "relay"
  spec: {
    replicas: 1
    template: {

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
          name: #name
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
        volumes: [{
          name: "data"
          persistentVolumeClaim: claimName: "relay-data"
        }]
      }
    }
  }
}