package k8s

LocalPathPVC: {
  #name: string
  #size: string

  apiVersion: "v1"
  kind: "PersistentVolumeClaim"
  metadata: name: #name
  spec: {
    accessModes: ["ReadWriteOnce"]
    storageClassName: "local-path"
    resources: {
      requests: storage: #size
    }
  } 
}