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
py_binary(
  name = 'generate_compile_command',
  srcs = [
    'generate_compile_command.py',
  ],
  deps = [
    '//third_party/bazel:extra_actions_proto_py',
  ],
)

action_listener(
  name = 'generate_compile_commands_listener',
  visibility = ['//visibility:public'],
  mnemonics = [
    'CppCompile',
  ],
  extra_actions = [':generate_compile_commands_action'],
)

extra_action(
  name = 'generate_compile_commands_action',
  tools = [
    ':generate_compile_command',
  ],
  out_templates = [
    '$(ACTION_ID)_compile_command',
  ],
  cmd = '$(location :generate_compile_command) $(EXTRA_ACTION_FILE)' +
        ' $(output $(ACTION_ID)_compile_command)',
)
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
# This is the implementation of a Bazel extra_action which generates
# _compile_command files for generate_compile_commands.py to consume.

import sys

import third_party.bazel.protos.extra_actions_base_pb2 as extra_actions_base_pb2

def _get_cpp_command(cpp_compile_info):
  compiler = cpp_compile_info.tool
  options = ' '.join(cpp_compile_info.compiler_option)
  source = cpp_compile_info.source_file
  output = cpp_compile_info.output_file
  return '%s %s -c %s -o %s' % (compiler, options, source, output), source

def main(argv):
  action = extra_actions_base_pb2.ExtraActionInfo()
  with open(argv[1], 'rb') as f:
    action.MergeFromString(f.read())
    command, source_file = _get_cpp_command(
      action.Extensions[extra_actions_base_pb2.CppCompileInfo.cpp_compile_info])
  with open(argv[2], 'w') as f:
    f.write(command)
    f.write('\0')
    f.write(source_file)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
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
#!/usr/bin/python3

# This reads the _compile_command files :generate_compile_commands_action
# generates a outputs a compile_commands.json file at the top of the source
# tree for things like clang-tidy to read.

# Overall usage directions: run Bazel with
# --experimental_action_listener=//tools/actions:generate_compile_commands_listener
# for all the files you want to use clang-tidy with and then run this script.
# After that, `clang-tidy build_tests/gflags.cc` should work.

import sys
import pathlib
import os.path
import subprocess

'''
Args:
  path: The pathlib.Path to _compile_command file.
  command_directory: The directory commands are run from.
Returns a string to stick in compile_commands.json.
'''
def _get_command(path, command_directory):
  with path.open('r') as f:
    contents = f.read().split('\0')
    if len(contents) != 2:
      # Old/incomplete file or something; silently ignore it.
      return None
    return '''{
        "directory": "%s",
        "command": "%s",
        "file": "%s"
      }''' % (command_directory, contents[0].replace('"', '\\"'), contents[1])

'''
Args:
  path: A directory pathlib.Path to look for _compile_command files under.
  command_directory: The directory commands are run from.
Yields strings to stick in compile_commands.json.
'''
def _get_compile_commands(path, command_directory):
  for f in path.iterdir():
    if f.is_dir():
      yield from _get_compile_commands(f, command_directory)
    elif f.name.endswith('_compile_command'):
      command = _get_command(f, command_directory)
      if command:
        yield command

def main(argv):
  source_path = os.path.join(os.path.dirname(__file__), '../..')
  action_outs = os.path.join(source_path,
                             'bazel-bin/../extra_actions',
                             'tools/actions/generate_compile_commands_action')
  command_directory = subprocess.check_output(
    ('bazel', 'info', 'execution_root'),
    cwd=source_path).decode('utf-8').rstrip()
  commands = _get_compile_commands(pathlib.Path(action_outs), command_directory)
  with open(os.path.join(source_path, 'compile_commands.json'), 'w') as f:
    f.write('[{}]'.format(','.join(commands)))
    
if __name__ == '__main__':
  sys.exit(main(sys.argv))
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
// Copyright 2014 The Bazel Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// proto definitions for the blaze extra_action feature.

syntax = "proto2";

package blaze;

option java_multiple_files = true;
option java_package = "com.google.devtools.build.lib.actions.extra";

// A list of extra actions and metadata for the print_action command.
message ExtraActionSummary {
  repeated DetailedExtraActionInfo action = 1;
}

// An individual action printed by the print_action command.
message DetailedExtraActionInfo {
  // If the given action was included in the output due to a request for a
  // specific file, then this field contains the name of that file so that the
  // caller can correctly associate the extra action with that file.
  //
  // The data in this message is currently not sufficient to run the action on a
  // production machine, because not all necessary input files are identified,
  // especially for C++.
  //
  // There is no easy way to fix this; we could require that all header files
  // are declared and then add all of them here (which would be a huge superset
  // of the files that are actually required), or we could run the include
  // scanner and add those files here.
  optional string triggering_file = 1;
  // The actual action.
  required ExtraActionInfo action = 2;
}

// Provides information to an extra_action on the original action it is
// shadowing.
message ExtraActionInfo {
  extensions 1000 to max;

  // The label of the ActionOwner of the shadowed action.
  optional string owner = 1;

  // Only set if the owner is an Aspect.
  // Corresponds to AspectValue.AspectKey.getAspectClass.getName()
  // This field is deprecated as there might now be
  // multiple aspects applied to the same target.
  // This is the aspect name of the last aspect
  // in 'aspects' (8) field.
  optional string aspect_name = 6 [deprecated = true];

  // Only set if the owner is an Aspect.
  // Corresponds to AspectValue.AspectKey.getParameters()
  // This field is deprecated as there might now be
  // multiple aspects applied to the same target.
  // These are the aspect parameters of the last aspect
  // in 'aspects' (8) field.
  map<string, StringList> aspect_parameters = 7 [deprecated = true];
  message StringList {
    option deprecated = true;
    repeated string value = 1;
  }

  message AspectDescriptor {
    // Corresponds to AspectDescriptor.getName()
    optional string aspect_name = 1;
    // Corresponds to AspectDescriptor.getParameters()
    map<string, StringList> aspect_parameters = 2;
    message StringList {
      repeated string value = 1;
    }
  }

  // If the owner is an aspect, all aspects applied to the target
  repeated AspectDescriptor aspects = 8;

  // An id uniquely describing the shadowed action at the ActionOwner level.
  optional string id = 2;

  // The mnemonic of the shadowed action. Used to distinguish actions with the
  // same ActionType.
  optional string mnemonic = 5;
}

message EnvironmentVariable {
  // It is possible that this name is not a valid variable identifier.
  required string name = 1;
  // The value is unescaped and unquoted.
  required string value = 2;
}

// Provides access to data that is specific to spawn actions.
// Usually provided by actions using the "Spawn" & "Genrule" Mnemonics.
message SpawnInfo {
  extend ExtraActionInfo {
    optional SpawnInfo spawn_info = 1003;
  }

  repeated string argument = 1;
  // A list of environment variables and their values. No order is enforced.
  repeated EnvironmentVariable variable = 2;
  repeated string input_file = 4;
  repeated string output_file = 5;
}

// Provides access to data that is specific to C++ compile actions.
// Usually provided by actions using the "CppCompile" Mnemonic.
message CppCompileInfo {
  extend ExtraActionInfo {
    optional CppCompileInfo cpp_compile_info = 1001;
  }

  optional string tool = 1;
  repeated string compiler_option = 2;
  optional string source_file = 3;
  optional string output_file = 4;
  // Due to header discovery, this won't include headers unless the build is
  // actually performed. If set, this field will include the value of
  // "source_file" in addition to the headers.
  repeated string sources_and_headers = 5;
  // A list of environment variables and their values. No order is enforced.
  repeated EnvironmentVariable variable = 6;
}

// Provides access to data that is specific to C++ link  actions.
// Usually provided by actions using the "CppLink" Mnemonic.
message CppLinkInfo {
  extend ExtraActionInfo {
    optional CppLinkInfo cpp_link_info = 1002;
  }

  repeated string input_file = 1;
  optional string output_file = 2;
  optional string interface_output_file = 3;
  optional string link_target_type = 4;
  optional string link_staticness = 5;
  repeated string link_stamp = 6;
  repeated string build_info_header_artifact = 7;
  // The list of command line options used for running the linking tool.
  repeated string link_opt = 8;
}

// Provides access to data that is specific to java compile actions.
// Usually provided by actions using the "Javac" Mnemonic.
message JavaCompileInfo {
  extend ExtraActionInfo {
    optional JavaCompileInfo java_compile_info = 1000;
  }

  optional string outputjar = 1;
  repeated string classpath = 2;
  repeated string sourcepath = 3;
  repeated string source_file = 4;
  repeated string javac_opt = 5;
  repeated string processor = 6;
  repeated string processorpath = 7;
  repeated string bootclasspath = 8;
}

// Provides access to data that is specific to python rules.
// Usually provided by actions using the "Python" Mnemonic.
message PythonInfo {
  extend ExtraActionInfo {
    optional PythonInfo python_info = 1005;
  }

  repeated string source_file = 1;
  repeated string dep_file = 2;
}
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
licenses(["notice"])

py_library(
    name = "extra_actions_proto_py",
    srcs = ["protos/extra_actions_base_pb2.py"],
    visibility = ["//visibility:public"],
)
//MY_CODE_STREAM
else 
echo "File $current_file already exists, aborted! (you can use -f to force overwrite)" 
exit 1
fi

exit 0
