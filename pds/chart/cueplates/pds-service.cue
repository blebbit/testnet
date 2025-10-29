package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: pds_service: k8s.Service & { #name: vars.name }