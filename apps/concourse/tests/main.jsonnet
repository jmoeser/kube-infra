local Concourse = import '../main.jsonnet';
local name = 'concourse-test';

{
    concourse: Concourse.ConcourseInstance(name, std.extVar('namespace'), devel=true),
}
