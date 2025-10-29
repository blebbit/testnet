package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: deployment: k8s.Deployment & {
  #name: "plc"

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
          name: #name
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
      }
    }
  }
}