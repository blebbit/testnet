package cueplates

apiVersion: "postgresql.cnpg.io/v1"
kind: "Cluster"
metadata: {
  name: "plc-pg"
}
spec: {
  instances: 1
  storage: size: "5Gi"

  bootstrap: initdb: {
    database: "plc"
    owner: "plc"
  }
}