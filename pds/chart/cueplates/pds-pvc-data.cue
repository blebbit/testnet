apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata: name: "pds-data"
spec: {
  accessModes: ["ReadWriteOnce"]
  storageClassName: "local-path"
  resources: {
    requests: storage: "10Gi"
  }
}