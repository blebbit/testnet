package cueplates

apiVersion: "v1"
kind: "Service"
metadata: {
  name: "plc"
  labels: {
    service: name
  }
}
spec: {
  ports: [{
    name: "http"
    port: 3000
  }]
  selector: metadata.labels
  type: "ClusterIP"
}