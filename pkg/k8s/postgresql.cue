package k8s

Postgresql: {
  #name: string

  apiVersion: "postgresql.cnpg.io/v1"
  kind: "Cluster"

  metadata: {
    name: "\(#name)-pg"
    labels: {
      "app.kubernetes.io/name": name
    }
  }

  spec: {
    instances: 1
    storage: size: string

    bootstrap: initdb: {
      database: #name
      owner: #name
    }
  }
}
