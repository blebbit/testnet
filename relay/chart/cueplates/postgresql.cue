package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: postgresql: k8s.Postgresql & {
  #name: vars.name
  spec: {
    storage: size: "5Gi"
  }
}