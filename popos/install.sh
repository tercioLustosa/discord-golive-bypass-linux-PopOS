#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."

if (( EUID != 0 )); then
  echo "Use: sudo ./popos/install.sh /caminho/arquivo-wireguard.conf /home/usuario [transmissao|completo]" >&2
  exit 1
fi

conf=${1:?Informe o caminho do arquivo de configuração WireGuard}
discord_home=${2:?Informe a pasta pessoal do usuário do Discord}
mode=${3:-transmissao}

if [[ ! -r /etc/os-release ]]; then
  echo "Não foi possível identificar o sistema operacional." >&2
  exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != "pop" || "${VERSION_ID:-}" != "24.04" ]]; then
  echo "Este instalador é exclusivo para Pop!_OS 24.04. Sistema detectado: ${PRETTY_NAME:-desconhecido}." >&2
  exit 1
fi

[[ -f "$conf" && -r "$conf" ]] || {
  echo "Arquivo WireGuard não encontrado ou sem permissão de leitura: $conf" >&2
  exit 1
}
[[ "$discord_home" =~ ^/[a-zA-Z0-9_./-]+$ && -d "$discord_home" ]] || {
  echo "Pasta pessoal inválida. Use um caminho absoluto sem espaços ou caracteres especiais." >&2
  exit 1
}
[[ "$mode" == transmissao || "$mode" == completo ]] || {
  echo "Modo inválido: use transmissao ou completo." >&2
  exit 1
}
[[ -x build/discord-golive-bypass ]] || {
  echo "Executável não encontrado. Execute ./popos/build.sh primeiro." >&2
  exit 1
}
command -v wg >/dev/null 2>&1 || {
  echo "Dependência ausente: sudo apt install wireguard-tools" >&2
  exit 1
}
command -v ip >/dev/null 2>&1 || {
  echo "Dependência ausente: sudo apt install iproute2" >&2
  exit 1
}
command -v systemctl >/dev/null 2>&1 || {
  echo "systemd/systemctl não está disponível." >&2
  exit 1
}

./build/discord-golive-bypass --check --config "$conf" --home "$discord_home" --mode "$mode"

systemctl stop discord-golive-bypass.service 2>/dev/null || true
install -d -o root -g root -m 700 /etc/discord-golive-bypass
install -D -o root -g root -m 755 build/discord-golive-bypass /usr/local/libexec/discord-golive-bypass

if [[ "$(readlink -f -- "$conf")" != /etc/discord-golive-bypass/wireguard.conf ]]; then
  install -o root -g root -m 600 -- "$conf" /etc/discord-golive-bypass/wireguard.conf
else
  chown root:root /etc/discord-golive-bypass/wireguard.conf
  chmod 600 /etc/discord-golive-bypass/wireguard.conf
fi

printf 'DISCORD_HOME=%s\nMODE=%s\n' "$discord_home" "$mode" > /etc/discord-golive-bypass/settings
chown root:root /etc/discord-golive-bypass/settings
chmod 600 /etc/discord-golive-bypass/settings
install -o root -g root -m 644 popos/discord-golive-bypass.service /etc/systemd/system/discord-golive-bypass.service

systemctl daemon-reload
systemctl enable --now discord-golive-bypass.service
systemctl --no-pager status discord-golive-bypass.service
