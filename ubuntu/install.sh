#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."

if (( EUID != 0 )); then
  echo "Use: sudo ./ubuntu/install.sh /caminho/wireguard.conf /home/usuario [transmissao|completo]" >&2
  exit 1
fi

conf=${1:?Informe o arquivo de configuração WireGuard}
discord_home=${2:?Informe a pasta pessoal do usuário do Discord}
mode=${3:-transmissao}

if [[ ! -r /etc/os-release ]]; then
  echo "Não foi possível identificar a distribuição." >&2
  exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != "pop" && "${ID:-}" != "ubuntu" ]]; then
  echo "Este instalador é destinado ao Pop!_OS e Ubuntu." >&2
  exit 1
fi
if [[ ! "${VERSION_ID:-}" =~ ^24\.04 ]]; then
  echo "Alvo validado para Pop!_OS/Ubuntu 24.04; versão detectada: ${VERSION_ID:-desconhecida}." >&2
  exit 1
fi

[[ "$discord_home" =~ ^/[a-zA-Z0-9_./-]+$ && -d "$discord_home" ]] || {
  echo "Pasta pessoal inválida ou com caracteres não suportados." >&2
  exit 1
}
[[ "$mode" == transmissao || "$mode" == completo ]] || {
  echo "Modo inválido: use transmissao ou completo." >&2
  exit 1
}
[[ -x build/discord-golive-bypass ]] || {
  echo "Execute ./ubuntu/build.sh primeiro." >&2
  exit 1
}
command -v wg >/dev/null 2>&1 || {
  echo "Dependências ausentes. Execute: sudo apt update && sudo apt install wireguard-tools iproute2" >&2
  exit 1
}
command -v ip >/dev/null 2>&1 || {
  echo "iproute2 não está instalado. Execute: sudo apt install iproute2" >&2
  exit 1
}
command -v systemctl >/dev/null 2>&1 || {
  echo "systemd/systemctl não está disponível neste sistema." >&2
  exit 1
}

./build/discord-golive-bypass --check --config "$conf" --home "$discord_home" --mode "$mode"

systemctl stop discord-golive-bypass.service 2>/dev/null || true
install -d -m 700 /etc/discord-golive-bypass
install -D -m 755 build/discord-golive-bypass /usr/local/libexec/discord-golive-bypass

if [[ "$(readlink -f -- "$conf")" != /etc/discord-golive-bypass/wireguard.conf ]]; then
  install -m 600 -- "$conf" /etc/discord-golive-bypass/wireguard.conf
else
  chmod 600 /etc/discord-golive-bypass/wireguard.conf
fi

printf 'DISCORD_HOME=%s\nMODE=%s\n' "$discord_home" "$mode" > /etc/discord-golive-bypass/settings
chmod 600 /etc/discord-golive-bypass/settings
install -m 644 ubuntu/discord-golive-bypass.service /etc/systemd/system/discord-golive-bypass.service

systemctl daemon-reload
systemctl enable --now discord-golive-bypass.service
systemctl --no-pager status discord-golive-bypass.service
