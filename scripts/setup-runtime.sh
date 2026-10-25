#!/usr/bin/env bash
# Rebuild the ignored local Python/WASI runtime on Linux x86_64.
# Versions and archive checksums retained from the original Rootward runner snapshot.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
runtime_dir="$project_root/sandbox/runtime"
cache_dir="$project_root/.cache/runtime-downloads"
wasmtime_version="v49.0.0"
python_version="3.14.7"
wasmtime_sha="a956c279ac6e80109369a285db30fc46f68239fa1bbeb03ccfa8e913bbca85fc"
python_sha="2e064d3fb8172471d39d741348efa722349c40b96301f69968dff714999c584b"
if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  echo 'This bootstrap supports Linux x86_64. Supply a matching Wasmtime/Python WASI runtime on other platforms.' >&2
  exit 1
fi
if [[ -x "$runtime_dir/bin/wasmtime" && -f "$runtime_dir/python/python.cwasm" ]]; then
  echo "Python/WASI runtime already present: $runtime_dir"
  exit 0
fi
for dependency in curl sha256sum tar unzip; do
  command -v "$dependency" > /dev/null || { echo "Missing dependency: $dependency" >&2; exit 1; }
done
mkdir -p "$cache_dir" "$runtime_dir/bin" "$runtime_dir/python"
touch "$runtime_dir/.gdignore"
fetch() {
  local url="$1" checksum="$2" archive="$3"
  if [[ ! -f "$archive" ]] || ! printf '%s  %s\n' "$checksum" "$archive" | sha256sum --check --quiet; then
    curl --fail --location --silent --show-error "$url" --output "$archive.part"
    printf '%s  %s\n' "$checksum" "$archive.part" | sha256sum --check --quiet
    mv "$archive.part" "$archive"
  fi
}
fetch "https://github.com/bytecodealliance/wasmtime/releases/download/$wasmtime_version/wasmtime-$wasmtime_version-x86_64-linux.tar.xz" \
  "$wasmtime_sha" "$cache_dir/wasmtime.tar.xz"
fetch "https://github.com/brettcannon/cpython-wasi-build/releases/download/v$python_version/python-$python_version-wasi_sdk-24.zip" \
  "$python_sha" "$cache_dir/python.zip"
tar -xJf "$cache_dir/wasmtime.tar.xz" -C "$cache_dir"
cp "$cache_dir/wasmtime-$wasmtime_version-x86_64-linux/wasmtime" "$runtime_dir/bin/wasmtime"
unzip -qo "$cache_dir/python.zip" -d "$runtime_dir/python"
"$runtime_dir/bin/wasmtime" compile -W epoch-interruption=y "$runtime_dir/python/python.wasm" -o "$runtime_dir/python/python.cwasm"
# Compile the stdlib once; optional modules in the WASI distribution can be unavailable.
"$runtime_dir/bin/wasmtime" run --allow-precompiled -W timeout=900s \
  --dir "$runtime_dir/python/lib::/lib" --env PYTHONHOME=/ \
  "$runtime_dir/python/python.cwasm" -m compileall -q /lib/python3.14 > /dev/null 2>&1 || true
# WASI has no chmod: host read-only permissions protect the shared stdlib mount.
chmod -R a-w "$runtime_dir/python/lib"
printf 'wasmtime %s, cpython %s\n' "$wasmtime_version" "$python_version" > "$runtime_dir/VERSIONS"
echo "Installed Python/WASI runtime: $runtime_dir"
