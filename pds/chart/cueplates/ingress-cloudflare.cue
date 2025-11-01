@if(cloudflare)

package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: ingress: k8s.CloudflareIngress & {
  #in: {
    vars
    port: 3000
  }
  spec: {
    rules: [{
      host: "\(#in.name).\(#in.domain)"
      http: {
        paths: [{
          backend: {
            service: {
              name: "pds"
              port: {
                number: 3000
              }
            }
          }
          path:     "/"
          pathType: "Prefix"
        }]
      }
    },{
      host: "*.\(#in.name).\(#in.domain)"
      http: {
        paths: [{
          backend: {
            service: {
              name: "pds"
              port: {
                number: 3000
              }
            }
          }
          path:     "/.well-known/atproto-did"
          pathType: "Exact"
        }]
      }
    }]
  }
}