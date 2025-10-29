package cueplates

import (
  "encoding/base64"

  "github.com/blebbit/testnet/env"
)

apiVersion: "v1"
kind: "Secret"
metadata: name: "jetstream-env"
data: {
  for k,v in env.jetstream {
    (k): base64.Encode(null, v)
  }
}