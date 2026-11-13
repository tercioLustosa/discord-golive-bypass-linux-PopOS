# Discord Go Live Bypass — Pop!_OS 24.04

Projeto Linux dedicado exclusivamente ao **Pop!_OS 24.04 LTS**. Usa WireGuard do kernel, rotas seletivas por IP e um serviço systemd para encaminhar destinos do Discord por uma VPN com saída fora do Brasil.

> **Atenção:** este projeto não faz isolamento por processo. As rotas são aplicadas a endereços IP; outros aplicativos que acessarem os mesmos IPs também poderão usar a VPN. Leia as limitações antes de instalar.

## O que você precisa

- Pop!_OS 24.04 LTS atualizado.
- Discord instalado no computador (cliente nativo ou Flatpak estável para o modo `transmissao`).
- Uma configuração WireGuard válida de uma VPN cujo servidor tenha saída fora do Brasil. O projeto não fornece VPN nem credenciais.
- Conexão com a internet durante a instalação e a primeira compilação.

## 1. Instalar todas as dependências

Abra o Terminal e execute:

```bash
sudo apt update
sudo apt install -y git golang-go wireguard-tools iproute2 ca-certificates
```

Para que serve cada pacote:

| Pacote | Uso |
|---|---|
| `git` | Baixar e atualizar o código |
| `golang-go` | Compilar e testar o programa |
| `wireguard-tools` | Disponibilizar o comando `wg` |
| `iproute2` | Disponibilizar o comando `ip`, usado nas rotas |
| `ca-certificates` | Certificados para baixar o toolchain Go, se necessário |

O projeto requer Go 1.23 ou superior. O pacote do Pop!_OS 24.04 pode trazer uma versão anterior; os scripts usam `GOTOOLCHAIN=auto` para o próprio Go baixar a versão 1.23 indicada em `go.mod`. Por isso, mantenha acesso à internet durante a compilação.

Confira as ferramentas:

```bash
go version
wg --version
ip -Version
systemctl --version
```

## 2. Baixar o projeto e executar os testes

Execute como usuário normal, sem `sudo`:

```bash
git clone https://github.com/tercioLustosa/discord-golive-bypass-linux-PopOS.git
cd discord-golive-bypass-linux-PopOS
./popos/build.sh test
./popos/build.sh
```

O primeiro comando de compilação pode baixar automaticamente o Go 1.23. Ao terminar, o executável deve existir em `build/discord-golive-bypass`.

## 3. Obter uma configuração WireGuard

Você precisa de um arquivo de configuração WireGuard de um provedor VPN com servidor de saída fora do Brasil. Este projeto não cria uma conta VPN nem gera chaves.

Exemplo usando Proton VPN:

1. Entre na sua conta no site oficial da Proton VPN.
2. Abra a área de downloads/configurações WireGuard.
3. Gere uma configuração para **Linux** e escolha um servidor disponível fora do Brasil.
4. Baixe o arquivo de configuração WireGuard (`.conf`) e salve em `Downloads` com o nome `proton.conf`.

Documentação do provedor: [Proton VPN — WireGuard configurations](https://protonvpn.com/support/wireguard-configurations).

Você pode usar outro provedor, desde que forneça um arquivo WireGuard com saída IPv4 completa. O arquivo deve conter:

- uma seção `[Interface]` com `PrivateKey` e `Address` IPv4;
- uma seção `[Peer]` com `PublicKey`, `Endpoint` e `AllowedIPs = 0.0.0.0/0`;
- se o endereço da interface incluir IPv6, `AllowedIPs` também deve incluir `::/0`.

**Proteja esse arquivo:** ele contém sua chave privada. Não o envie para outras pessoas, não o publique no GitHub e não o coloque dentro da pasta do repositório. O instalador o copia para `/etc/discord-golive-bypass/wireguard.conf` com permissão restrita.

Valide o caminho e a configuração antes de instalar:

```bash
ls -l "$HOME/Downloads/proton.conf"
./build/discord-golive-bypass --check --config "$HOME/Downloads/proton.conf" --home "$HOME"
```

Se salvou com outro nome ou em outra pasta, substitua o caminho nos próximos comandos. Se a validação falhar, confira se baixou uma configuração WireGuard `.conf`, não um arquivo OpenVPN `.ovpn`.

## 4. Instalar e ativar o serviço

Na pasta do repositório, execute:

```bash
sudo ./popos/install.sh "$HOME/Downloads/proton.conf" "$HOME"
```

O instalador:

1. confirma que o sistema é Pop!_OS 24.04;
2. verifica as dependências e valida o arquivo WireGuard;
3. instala o executável em `/usr/local/libexec/`;
4. guarda a configuração VPN em `/etc/discord-golive-bypass/` com permissão `0600`;
5. instala e habilita o serviço systemd;
6. inicia o serviço imediatamente.

O modo padrão é `transmissao`. Depois da instalação:

1. feche completamente o Discord (encerre também o processo na bandeja, se houver);
2. abra o Discord novamente;
3. entre novamente na chamada e inicie o Go Live.

O serviço inicia automaticamente nas próximas inicializações do Pop!_OS. Não é necessário executar o instalador toda vez.

## 5. Verificar se está funcionando

```bash
systemctl status discord-golive-bypass --no-pager
sudo journalctl -u discord-golive-bypass -n 80 --no-pager
sudo wg show dglb0
ip -4 route show dev dglb0
```

Depois que o túnel trocar dados, `wg show dglb0` deve apresentar um handshake recente. O journal mostra mensagens como `túnel ativo` e, quando detectada, a conexão da transmissão que entrou no túnel.

Para confirmar uma rota específica:

```bash
ip -4 route get 162.159.128.1
```

O resultado deve indicar `dev dglb0` quando o IP consultado estiver entre os destinos roteados naquele modo. Isso verifica a rota local, não garante por si só que o Go Live esteja funcionando.

## 6. Comandos para controlar o serviço

Ver estado:

```bash
systemctl status discord-golive-bypass --no-pager
```

Parar temporariamente:

```bash
sudo systemctl stop discord-golive-bypass
```

Iniciar novamente:

```bash
sudo systemctl start discord-golive-bypass
```

Desabilitar também a inicialização automática:

```bash
sudo systemctl disable --now discord-golive-bypass
```

Habilitar novamente:

```bash
sudo systemctl enable --now discord-golive-bypass
```

## 7. Modo completo (voz e câmera)

O modo padrão `transmissao` encaminha os destinos de controle do Discord e detecta os IPs de mídia das transmissões pelos logs do cliente. Para encaminhar também os destinos conhecidos de voz e câmera, altere o modo:

```bash
sudoedit /etc/discord-golive-bypass/settings
```

Altere a linha para:

```ini
MODE=completo
```

Salve, reinicie o serviço e reabra o Discord:

```bash
sudo systemctl restart discord-golive-bypass
```

Para voltar ao modo padrão, defina `MODE=transmissao` e reinicie o serviço. O modo completo pode aumentar a latência da chamada porque a voz também passa pelo servidor VPN.

## 8. Atualizar o programa

Entre na pasta do repositório e execute:

```bash
git pull --ff-only
./popos/build.sh test
./popos/build.sh
sudo ./popos/install.sh /etc/discord-golive-bypass/wireguard.conf "$HOME"
```

Se você usa `MODE=completo`, informe o modo no final do comando de instalação:

```bash
sudo ./popos/install.sh /etc/discord-golive-bypass/wireguard.conf "$HOME" completo
```

## 9. Diagnóstico e recuperação

Consultar os registros completos:

```bash
sudo journalctl -u discord-golive-bypass -b --no-pager
```

Verificar o túnel:

```bash
sudo wg show dglb0
ip link show dglb0
```

Se aparecer que a interface `dglb0` já existe, não execute repetidamente o instalador. Primeiro confirme que o serviço está parado:

```bash
sudo systemctl stop discord-golive-bypass
ip link show dglb0
```

Somente se tiver certeza de que a interface é uma sobra desta ferramenta e que nenhum outro serviço a utiliza, remova-a:

```bash
sudo ip link del dglb0
sudo ip -6 route flush type unreachable metric 42760
```

Em seguida, inicie o serviço novamente:

```bash
sudo systemctl start discord-golive-bypass
```

Se o serviço não iniciar, envie a saída de `systemctl status` e `journalctl` para diagnóstico, mas **nunca envie o arquivo WireGuard**, pois contém sua chave privada.

## 10. Desinstalar completamente

Na pasta do repositório:

```bash
sudo ./popos/uninstall.sh
```

O script para e desabilita o serviço, remove o executável, apaga a configuração WireGuard protegida e recarrega o systemd. Ele não remove o Discord, o Git, o Go, o WireGuard do sistema nem o repositório baixado.

## Limitações importantes

- Compatibilidade alvo: **Pop!_OS 24.04 LTS**. Não há scripts de instalação para Fedora ou outras distribuições.
- O modo `transmissao` lê os logs do Discord nativo e do Flatpak estável nos caminhos conhecidos. Se o Discord estiver em outro caminho, use `completo`.
- O navegador não é monitorado pelo leitor de logs; para ele, use `completo`.
- O roteamento é por IP, não por processo. Outros aplicativos que acessarem os mesmos endereços IP também podem usar o túnel.
- O campo `DNS` da configuração WireGuard não é aplicado; o DNS atual do sistema continua em uso. Hooks como `PostUp` e `PreDown` são rejeitados por segurança.
- Se a VPN cair, os destinos selecionados podem ficar sem conexão até o túnel voltar ou o serviço ser parado. Esta versão não possui fallback automático.
- Atualizações do Discord podem mudar os endereços IP ou o formato dos logs. O funcionamento precisa ser testado após atualizações relevantes.

## Desenvolvimento

```bash
./popos/build.sh test
./popos/build.sh
```

A integração contínua testa e compila em Ubuntu 24.04, base de pacotes do Pop!_OS 24.04. Isso não substitui o teste de instalação e de uma transmissão real no Pop!_OS.

## Créditos e licença

Derivado de [thomassolcia/DiscordGoLiveBypass](https://github.com/thomassolcia/DiscordGoLiveBypass), sob licença [GPL-3.0](LICENSE). Consulte [NOTICE.md](NOTICE.md) para os créditos e a origem do código. Projeto independente, sem afiliação com Discord ou Proton.
