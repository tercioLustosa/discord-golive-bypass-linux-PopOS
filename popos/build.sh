#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."

command -v go >/dev/null 2>&1 || {
  echo "Go não encontrado. Instale com: sudo apt install golang-go" >&2
  exit 1
}

case "${1:-build}" in
  test)
    GOTOOLCHAIN=auto go test ./...
    GOTOOLCHAIN=auto go vet ./...
    ;;
  build)
    mkdir -p build
    CGO_ENABLED=0 GOTOOLCHAIN=auto go build -trimpath -ldflags="-s -w" -o build/discord-golive-bypass .
    echo "Compilado: $PWD/build/discord-golive-bypass"
    ;;
  *)
    echo "Uso: ./popos/build.sh [build|test]" >&2
    exit 1
    ;;
esac
