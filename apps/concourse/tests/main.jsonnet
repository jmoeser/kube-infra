local Concourse = import '../main.jsonnet';
local name = 'concourse-test';

//docker run --rm -v $PWD/:/keys concourse/concourse generate-key -t rsa -f /keys/session_signing_key
//docker run --rm -v $PWD/:/keys concourse/concourse generate-key -t ssh -f /keys/host_key
//docker run --rm -v $PWD/:/keys concourse/concourse generate-key -t ssh -f /keys/worker_key

{
    concourse: Concourse.ConcourseInstance(name, std.extVar('namespace'), devel=true) {
        instanceConfig+: {
            databasePassword: "Password!",
            host_key: importstr 'host_key',
            host_key_pub: importstr 'host_key.pub',
            session_signing_key: importstr 'session_signing_key',
            worker_key: importstr 'worker_key',
            worker_key_pub: importstr 'worker_key.pub',
            worker_count: 0,
        }
    },
}
