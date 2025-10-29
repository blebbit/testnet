package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: pds_data: k8s.LocalPathPVC & { 
  #name: "\(vars.name)-data"
  #size: "10Gi"
}

helm: pds_blobs: k8s.LocalPathPVC & { 
  #name: "\(vars.name)-blobs"
  #size: "20Gi"
}