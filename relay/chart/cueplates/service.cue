package cueplates

apiVersion: "v1"
kind: "Service"
metadata: {
  name: "relay"
  labels: {
    service: name
  }
}
spec: {
  ports: [{
    name: "http"
    port: 3000
    targetPort: 2470
  }]
  selector: metadata.labels
  type: "ClusterIP"
}