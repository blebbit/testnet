package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: deployment: k8s.Deployment & {
  #name: "jetstream"

  spec: {
    replicas: 1
    template: {
      spec: {
        containers: [{
          name: #name
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
}