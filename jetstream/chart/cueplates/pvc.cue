package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: pvc: k8s.LocalPathPVC & { 
  #name: "\(vars.name)-data"
  #size: "2Gi"
}