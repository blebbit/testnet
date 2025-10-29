package k8s

import (
  "encoding/base64"

  "github.com/blebbit/testnet/env"
)

SecretEnvFile: {
  #name: string
  apiVersion: "v1"
  kind: "Secret"
  metadata: {
    name: "\(#name)-env"
    labels: {
      "app.kubernetes.io/name": #name
    }
  }
  data: {
    for k,v in env[#name] {
      (k): base64.Encode(null, v)
    }
  }
}