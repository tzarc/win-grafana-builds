#!/bin/bash

set -eEuo pipefail

this_script="$(readlink -f "${BASH_SOURCE[0]}")"
script_dir="$(readlink -f "$(dirname "$this_script")")"

if [[ ! -f "$script_dir/go1.16.7.linux-amd64.tar.gz" ]] ; then
    wget -O "$script_dir/go1.16.7.linux-amd64.tar.gz" https://golang.org/dl/go1.16.7.linux-amd64.tar.gz
fi

if [[ ! -x "$script_dir/go/bin" ]] ; then
    tar zxf "$script_dir/go1.16.7.linux-amd64.tar.gz" -C "$script_dir"
fi

export PATH="$PATH:$script_dir/go/bin"

echo -- -----------------
env | sort
echo -- -----------------
go env | sort
echo -- -----------------
yarn --version
echo -- -----------------

git submodule update --init --recursive

cd grafana \
    && go run build.go -goos windows -goarch amd64 -cc x86_64-w64-mingw32-gcc build \
    && make deps-js \
    && make build-js \
    && rm -rf node_modules/ packages/*/node_modules/ plugins-bundled/internal/input-datasource/node_modules/ \
    && 7za a ../grafana-homepath.zip -tzip conf plugins-bundled public scripts tools \
    && cd ..
cp grafana/bin/windows-amd64/grafana-server.exe .

cd tempo && make GOOS=windows GOARCH=amd64 tempo && cd ..
cp tempo/bin/windows/tempo-amd64 ./tempo.exe

git submodule foreach git log -n1 --oneline | tee revisions.txt