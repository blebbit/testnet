_vars: {
  domain: string @tag(TESTNET_DOMAIN)
  tunnelName: string @tag(CLOUDFLARE_TUNNEL_NAME)
  tunnelId: string @tag(CLOUDFLARE_TUNNEL_ID)
}

cloudflare: {
  tunnelName: _vars.tunnelName
  tunnelId: _vars.tunnelId
  secretName: "cloudflare-tunnel-creds"
  ingress: [{
    hostname: "*.\(_vars.domain)"
    service: "https://ingress-nginx-controller.operators.svc.cluster.local:443"
    originRequest: noTLSVerify: true
  }]
}

replicaCount: 1

resources: {
  limits: {
    cpu: "100m"
    memory: "128Mi"
  }
  requests: {
    cpu: "100m"
    memory: "128Mi"
  }
}
