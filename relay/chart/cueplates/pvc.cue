apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata: name: "relay-data"
spec: {
  accessModes: ["ReadWriteOnce"]
  storageClassName: "local-path"
  resources: {
    requests: storage: "2Gi"
  }
}