apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata: name: "pds-blobs"
spec: {
  accessModes: ["ReadWriteOnce"]
  storageClassName: "local-path"
  resources: {
    requests: storage: "20Gi"
  }
}