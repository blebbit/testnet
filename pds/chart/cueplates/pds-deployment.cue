package cueplates

import (
  "github.com/blebbit/testnet/pkg/k8s"
)

helm: pds_deployment: k8s.Deployment & {
  #name: "pds"

  spec: {
    replicas: 1
    template: {
      spec: {

        restartPolicy: "Always"
        // need to wait on spicedb ready
        // initContainers: [{
        //   name: "mig-db"
        //   image: "authzed/spicedb:latest"
        //   imagePullPolicy: "IfNotPresent"
        //   command: ["spicedb", "migrate", "head"]
        //   env: [{
        //     name: "SPICEDB_DATASTORE_ENGINE"
        //     value: "postgres"
        //   },{
        //     name: "SPICEDB_DATASTORE_CONN_URI"
        //     valueFrom: secretKeyRef: {
        //       key: "uri"
        //       name: "pds-pg-app"
        //     }
        //   }]
        // }]
        containers: [{
          name: #name
          image: "docker.io/blebbit/pds:latest"
          imagePullPolicy: "Never"
          envFrom:[{
            secretRef: name: "pds-env"
          }]
          volumeMounts: [{
            name: "data"
            mountPath: "/app/data"
          },{
            name: "blobs"
            mountPath: "/app/blobs"
          }]
        }]

        volumes: [{
          name: "data"
          persistentVolumeClaim: claimName: "pds-data"
        },{
          name: "blobs"
          persistentVolumeClaim: claimName: "pds-blobs"
        }]
      }
    }
  }
}