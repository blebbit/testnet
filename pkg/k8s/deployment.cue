package k8s

import (
  "github.com/blebbit/testnet/env"
)

Deployment: {
  #name: string
  apiVersion: "apps/v1"
  kind: "Deployment"
  metadata: {
    name: #name
    labels: {
      "app.kubernetes.io/name": #name
      envhash: env[#name].#hash
    }
  }

  let M = metadata

  spec: {
    selector: matchLabels: { for k,v in M.labels if k != "envhash" { (k): v }}
    template: {
      metadata: labels: M.labels
      spec: {
        restartPolicy: "Always"
      }
    }
  }

}

