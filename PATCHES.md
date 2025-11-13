# Patches

This file outlines the patches we apply to upstream services

1. PDS, see https://github.com/blebbit/atproto for details, mainly "permissioned spaces"
2. PLC, change ENV var loading for databause url to make it CNPG friendly
3. Relay, changes to go build in alpine because we do not have git tags (maybe we can now, because upstream patch merged? forget which service that was, and maybe it's that we should pin the clone to a tag)


### PLC

`github.com/did-method-plc/did-method-plc/packages/server/service/index.js`

```diff
--- a/packages/server/service/index.js
+++ b/packages/server/service/index.js
@@ -5,14 +5,14 @@ const { Database, PlcServer } = require('..')
 
 const main = async () => {
   const version = process.env.PLC_VERSION
-  const dbCreds = JSON.parse(process.env.DB_CREDS_JSON)
+  const dbUrl = process.env.DB_URL
   const dbSchema = process.env.DB_SCHEMA || undefined
   const enableMigrations = process.env.ENABLE_MIGRATIONS === 'true'
   if (enableMigrations) {
-    const dbMigrateCreds = JSON.parse(process.env.DB_MIGRATE_CREDS_JSON)
+    const dbMigUrl = process.env.DB_MIGRATE_URL
     // Migrate using credentialed user
     const migrateDb = Database.postgres({
-      url: pgUrl(dbMigrateCreds),
+      url: dbMigUrl,
       schema: dbSchema,
     })
     await migrateDb.migrateToLatestOrThrow()
@@ -23,7 +23,7 @@ const main = async () => {
   const dbPoolIdleTimeoutMs = parseMaybeInt(process.env.DB_POOL_IDLE_TIMEOUT_MS)
   // Use lower-credentialed user to run the app
   const db = Database.postgres({
-    url: pgUrl(dbCreds),
+    url: dbUrl,
     schema: dbSchema,
     poolSize: dbPoolSize,
     poolMaxUses: dbPoolMaxUses,
@@ -39,11 +39,6 @@ const main = async () => {
   })
 }
 
-const pgUrl = ({ username = "postgres", password = "postgres", host = "localhost", port = "5432", database = "postgres", sslmode }) => {
-  const enc = encodeURIComponent
-  return `postgresql://${username}:${enc(password)}@${host}:${port}/${database}${sslmode ? `?sslmode=${enc(sslmode)}` : ''}`
-}
-
 const parseMaybeInt = (str) => {
   return str ? parseInt(str, 10) : undefined
 }
```

### Relay

```diff
--- a/cmd/relay/Dockerfile
+++ b/cmd/relay/Dockerfile
@@ -11,8 +11,9 @@ WORKDIR /dockerbuild
 
 # timezone data for alpine builds
 ENV GOEXPERIMENT=loopvar
-RUN GIT_VERSION=$(git describe --tags --long --always) && \
-    go build -tags timetzdata -o /relay ./cmd/relay
+# RUN GIT_VERSION=$(git describe --tags --long --always) && \
+#     go build -tags timetzdata -o /relay ./cmd/relay
+RUN go build -tags timetzdata -o /relay ./cmd/relay
```