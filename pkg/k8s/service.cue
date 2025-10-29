package k8s

Service: {
  #name: string
  #port: int | *3000

  apiVersion: "v1"
  kind: "Service"
  metadata: {
    name: #name
    labels: {
      "app.kubernetes.io/name": #name
    }
  }

  spec: {
    ports: [...] | *[{
      name: "http"
      port: #port
    }]
    selector: metadata.labels
    type: "ClusterIP"
  }
}
