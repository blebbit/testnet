package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: secret: k8s.SecretEnvFile & { #name: vars.name }