package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: spicedb_service: k8s.Service & {
  #name: "spicedb"
  spec: {
    ports: [{
      name: "grpc"
      port: 50051
    },{
      name: "http"
      port: 8080
    },{
      name: "prometheus"
      port: 9090
    }]
  }
}