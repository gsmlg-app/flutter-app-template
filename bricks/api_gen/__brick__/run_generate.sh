#!/usr/bin/env bash

which openapi-generator
if [ $? -eq 0 ]
then
    GEN_CMD="openapi-generator"
else
    GEN_CMD="openapi-generator-cli"
fi

INPUT_FILE="openapi.yaml"
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
RELATIVE_PATH="$SCRIPT_DIR/../../app_api/{{package_name}}"
OUT_DIR=$RELATIVE_PATH
CWD=$(pwd)

if [ ! -f $INPUT_FILE ]
then
   echo "$INPUT_FILE not found"
   exit 1; 
fi

$GEN_CMD generate \
    -i "$INPUT_FILE" \
    -g dart-dio \
    -o "$OUT_DIR" \
    --skip-validate-spec \
    --package-name "{{package_name}}" \
    --config config.yml

cd $OUT_DIR

dart run build_runner build --delete-conflicting-outputs
dart format .

cd $CWD

