#!/bin/sh
set -e
bazel build --experimental_action_listener=//tools/actions:generate_compile_commands_listener $1
python3 ./tools/actions/generate_compile_commands_json.py
