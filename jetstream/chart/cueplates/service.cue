package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: service: k8s.Service & { #name: vars.name }