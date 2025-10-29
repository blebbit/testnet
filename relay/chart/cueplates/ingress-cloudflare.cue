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
}