apiVersion: "apps/v1"
kind: "Deployment"
metadata: {
  name: "spicedb"
  labels: {
    service: name
  }
}

let M = metadata

spec: {
  replicas: 1
  selector: matchLabels: M.labels
  template: {
    metadata: labels: M.labels

    spec: {
      initContainers: [{
        name: "wait-db"
        image: "postgres"
        env: [{
          name: "DB_URL"
          valueFrom: secretKeyRef: {
            key: "uri"
            name: "pds-pg-app"
          }
        }]
        command: ["sh", "-ec", """
          until pg_isready -d $DB_URL; do
            sleep 1
          done
        """]
      },{
        name: "mig-db"
        image: "authzed/spicedb:latest"
        imagePullPolicy: "IfNotPresent"
        env: [{
          name: "SPICEDB_DATASTORE_ENGINE"
          value: "postgres"
        },{
          name: "SPICEDB_DATASTORE_CONN_URI"
          valueFrom: secretKeyRef: {
            key: "uri"
            name: "pds-pg-app"
          }
        }]
      }]
      containers: [{
        name: "pds-spicedb"
        image: "docker.io/authzed/spicedb:latest"
        imagePullPolicy: "IfNotPresent"
        command: ["spicedb", "serve", "--http-enabled"]
        env: [{
          name: "SPICEDB_GRPC_PRESHARED_KEY"
          value: "tbd-make-this-a-real-secret-with-eso"
        },{
          name: "SPICEDB_DATASTORE_ENGINE"
          value: "postgres"
        },{
          name: "SPICEDB_DATASTORE_CONN_URI"
          valueFrom: secretKeyRef: {
            key: "uri"
            name: "pds-pg-app"
          }
        }]
        ports: [{
          name: "grpc"
          containerPort: 50051
        },{
          name: "http"
          containerPort: 8443
        },{
          name: "prometheus"
          containerPort: 9090
        }]
      }]
      restartPolicy: "Always"
    }
  }
}