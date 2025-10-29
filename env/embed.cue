@extern(embed)

package env

import (
  "crypto/md5"
  "encoding/hex"
  "strings"
)

_files: _ @embed(glob=*.env, type=text)

for path, contents in _files {
  let name = strings.Split(path, ".")[0]
  let lines = strings.Split(contents, "\n")
  let filtered = [for line in lines if !strings.HasPrefix(line, "#") && strings.TrimSpace(line) != "" { line }]
  let pairs = [for line in filtered { strings.SplitN(line, "=", 2) }]
  (name): {
    #hash: hex.Encode(md5.Sum(contents))
    for pair in pairs {
      (pair[0]): pair[1]
    }
  }
}

pds: _
spicedb: pds