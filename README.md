# kube-infra

[jsonnet](https://jsonnet.org/) based re-useable templates of Kubernetes deployments that can be deployed using [kubecfg](https://github.com/bitnami/kubecfg). For examples of how to use them look under the tests directory of each application. For instance in the Concourse tests file:

```
local Concourse = import '../main.jsonnet';
local name = 'concourse-test';

{
    concourse: Concourse.ConcourseInstance(name, std.extVar('namespace'), devel=true) {
        instanceConfig+: {
            databasePassword: "Password!",
            host_key: importstr 'host_key',
            host_key_pub: importstr 'host_key.pub',
            session_signing_key: importstr 'session_signing_key',
            worker_key: importstr 'worker_key',
            worker_key_pub: importstr 'worker_key.pub',
            worker_count: 1,
        }
    },
}
```

We pull in the main.jsonnet file in the outer directory which contains the deployment definition and then override some configuration with our own passwords/keys as needed.

[kubeval](https://github.com/instrumenta/kubeval) is used for validation of generated deployment YAML artefacts and [conftest](https://github.com/instrumenta/conftest) is used to ensure they comply with policy as defined under `policy/`.

## Tests

Tests set up via Concourse pipeline in `pipeline.yaml`.
