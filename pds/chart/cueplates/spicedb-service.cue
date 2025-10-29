apiVersion: "v1"
kind: "Service"
metadata: {
  name: "spicedb"
  labels: {
    service: name
  }
}
spec: {
  type: "ClusterIP"
  selector: metadata.labels
  ports: [{
    name: "grpc"
    port: 50051
  },{
    name: "http"
    port: 8443
  },{
    name: "prometheus"
    port: 9090
  }]
}