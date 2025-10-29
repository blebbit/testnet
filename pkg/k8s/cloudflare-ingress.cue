package k8s

CloudflareIngress: {
  #in: {
    Vars
    port: int
  }

  apiVersion: "networking.k8s.io/v1"
  kind: "Ingress"
  metadata: {
    name: #in.name
    labels: {
      "app.kubernetes.io/name": #in.name
    }
    annotations: {
      "external-dns.alpha.kubernetes.io/cloudflare-proxied": "true"
      "external-dns.alpha.kubernetes.io/hostname": "\(#in.name).\(#in.domain)"
      "external-dns.alpha.kubernetes.io/target": "\(#in.tunnelId).cfargotunnel.com"
    }
  }
  spec: {
    rules: [{
      host: "\(#in.name).\(#in.domain)"
      http: {
        paths: [{
          backend: {
            service: {
              name: "\(#in.name)"
              port: number: #in.port
            }
          }
          path: "/"
          pathType: "Prefix"
        }]
      }
    }]
  }
}