package main

name = input.metadata.name
kind = input.kind

labels {
    input.metadata.labels["version"]
    input.metadata.labels["name"]
    input.metadata.labels["part-of"]
    input.metadata.labels["app"]
}

deny[msg] {
  input.kind = "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot = true
  msg = sprintf("Deployment/%s must not allow containers to run as root", [name])
}

deny[msg] {
  input.kind = "StatefulSet"
  not input.spec.template.spec.securityContext.runAsNonRoot = true
  msg = sprintf("StatefulSet/%s must not allow containers to run as root", [name])
}

deny[msg] {
  input.kind != "Namespace"
  not input.metadata.namespace
  msg = sprintf("%s/%s - Must have a namespace", [kind, name])
}

deny[msg] {
  input.kind = "Deployment"
  not input.spec.selector.matchLabels.app
  msg = "Containers must provide app label for pod selectors"
}

warn[msg] {
  input.kind != "Namespace"
  not labels
  msg = sprintf("%s/%s should include labels: app/version/name/part-of", [kind, name])
}
