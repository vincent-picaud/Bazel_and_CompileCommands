#!/bin/sh
set -e

if [ ! -f "WORKSPACE" ]; then
    echo "Not in a Bazel root directory (WORKSPACE file does not exist), aborted!" 
    exit 1
fi

force=0

if [ "$1" = "-f" ]; then
  force=1
fi

current_file=tools/actions/BUILD
if [ "$force" -eq 1 ] || [ ! -f "$current_file" ]; then
    current_file_dir="$(dirname "$current_file")"

    mkdir -p "$current_file_dir"
    echo "Create $current_file" 1>&2
    more > "$current_file" <<'//MY_CODE_STREAM' 
<<tools/actions/BUILD>>
//MY_CODE_STREAM
else 
echo "File $current_file already exists, aborted! (you can use -f to force overwrite)" 
exit 1
fi
current_file=tools/actions/generate_compile_command.py
if [ "$force" -eq 1 ] || [ ! -f "$current_file" ]; then
    current_file_dir="$(dirname "$current_file")"

    mkdir -p "$current_file_dir"
    echo "Create $current_file" 1>&2
    more > "$current_file" <<'//MY_CODE_STREAM' 
<<tools/actions/generate_compile_command.py>>
//MY_CODE_STREAM
else 
echo "File $current_file already exists, aborted! (you can use -f to force overwrite)" 
exit 1
fi
current_file=tools/actions/generate_compile_commands_json.py
if [ "$force" -eq 1 ] || [ ! -f "$current_file" ]; then
    current_file_dir="$(dirname "$current_file")"

    mkdir -p "$current_file_dir"
    echo "Create $current_file" 1>&2
    more > "$current_file" <<'//MY_CODE_STREAM' 
<<tools/actions/generate_compile_commands_json.py>>
//MY_CODE_STREAM
else 
echo "File $current_file already exists, aborted! (you can use -f to force overwrite)" 
exit 1
fi
current_file=third_party/bazel/protos/extra_actions_base.proto
if [ "$force" -eq 1 ] || [ ! -f "$current_file" ]; then
    current_file_dir="$(dirname "$current_file")"

    mkdir -p "$current_file_dir"
    echo "Create $current_file" 1>&2
    more > "$current_file" <<'//MY_CODE_STREAM' 
<<third_party/bazel/protos/extra_actions_base.proto>>
//MY_CODE_STREAM
else 
echo "File $current_file already exists, aborted! (you can use -f to force overwrite)" 
exit 1
fi
echo "Generate third_party/bazel/protos/extra_actions_base_pb2.py" 1>&2
protoc third_party/bazel/protos/extra_actions_base.proto --python_out=.
current_file=third_party/bazel/BUILD
if [ "$force" -eq 1 ] || [ ! -f "$current_file" ]; then
    current_file_dir="$(dirname "$current_file")"

    mkdir -p "$current_file_dir"
    echo "Create $current_file" 1>&2
    more > "$current_file" <<'//MY_CODE_STREAM' 
<<third_party/bazel/BUILD>>
//MY_CODE_STREAM
else 
echo "File $current_file already exists, aborted! (you can use -f to force overwrite)" 
exit 1
fi

exit 0
