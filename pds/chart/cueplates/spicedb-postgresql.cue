package cueplates

apiVersion: "postgresql.cnpg.io/v1"
kind: "Cluster"
metadata: {
  name: "pds-pg"
}
spec: {
  instances: 1
  storage: size: "5Gi"

  bootstrap: initdb: {
    database: "pds"
    owner: "pds"
    postInitSQL: [
      "ALTER SYSTEM SET track_commit_timestamp = on;"
    ]
  }
}