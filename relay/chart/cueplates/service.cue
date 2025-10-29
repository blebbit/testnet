package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: service: k8s.Service & {
  #name: vars.name
  spec: {
    ports: [{
      name: "http"
      port: 3000
      targetPort: 2470
    }]
  }
}