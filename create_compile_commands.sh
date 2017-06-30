#!/bin/sh
set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $(basename $0) BAZEL_TARGET"
    exit 1
fi

bazel build --experimental_action_listener=//tools/actions:generate_compile_commands_listener $1
python3 ./tools/actions/generate_compile_commands_json.py
exit 0
