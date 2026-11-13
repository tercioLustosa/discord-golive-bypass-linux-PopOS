# Instalação no Pop!_OS e Ubuntu 24.04

Este guia instala a versão Linux do Discord Go Live Bypass usando APT, WireGuard do kernel e systemd. O procedimento é voltado ao Pop!_OS 24.04 e Ubuntu 24.04 LTS; não exige GNOME nem KDE e não instala nem modifica o cliente Discord.

## Dependências

No terminal:

```bash
sudo apt update
sudo apt install git golang-go wireguard-tools iproute2
```

O projeto requer Go 1.23 ou superior. Confira:

```bash
go version
```

## Baixar, testar e compilar

```bash
git clone https://github.com/tercioLustosa/discord-golive-bypass-linux-PopOS.git
cd discord-golive-bypass-linux-PopOS
./ubuntu/build.sh test
./ubuntu/build.sh
```

O executável será criado em `build/discord-golive-bypass`.

## Criar uma configuração WireGuard

É necessária uma configuração WireGuard de uma VPN com servidor de saída fora do Brasil. O arquivo precisa conter uma interface com endereço IPv4 e um peer com `AllowedIPs = 0.0.0.0/0`; se a interface tiver endereço IPv6, o peer também precisa incluir `::/0`.

Na Proton VPN, gere e baixe uma configuração WireGuard para Linux pelo painel da sua conta. Salve o arquivo, por exemplo, em `~/Downloads/proton.conf`.

**O arquivo contém uma chave privada. Não o publique no GitHub nem o compartilhe.** O instalador copia a configuração para `/etc/discord-golive-bypass/wireguard.conf` com permissão restrita (0600). O programa não executa hooks WireGuard como `PostUp` ou `PreDown`.

Valide o arquivo antes da instalação:

```bash
./build/discord-golive-bypass --check --config "$HOME/Downloads/proton.conf" --home "$HOME"
```

## Instalar e iniciar

Com Discord instalado para o usuário atual, execute na pasta do projeto:

```bash
sudo ./ubuntu/install.sh "$HOME/Downloads/proton.conf" "$HOME"
```

Para instalar no modo completo (inclui os destinos conhecidos de voz e câmera):

```bash
sudo ./ubuntu/install.sh "$HOME/Downloads/proton.conf" "$HOME" completo
```

O modo padrão é `transmissao`. O instalador valida a configuração, instala o executável e o serviço systemd, protege o arquivo WireGuard e habilita a inicialização automática.

Depois, feche completamente o Discord, abra-o novamente, entre na chamada e teste o Go Live. O serviço é iniciado automaticamente nas próximas inicializações.

## Comandos de operação

```bash
systemctl status discord-golive-bypass --no-pager
sudo journalctl -u discord-golive-bypass -n 80 --no-pager
sudo wg show dglb0
```

Parar e desabilitar:

```bash
sudo systemctl disable --now discord-golive-bypass
```

Reativar:

```bash
sudo systemctl enable --now discord-golive-bypass
```

Para alterar o modo:

```bash
sudoedit /etc/discord-golive-bypass/settings
sudo systemctl restart discord-golive-bypass
```

Defina `MODE=transmissao` ou `MODE=completo`.

## Desinstalar

A partir da pasta do projeto:

```bash
sudo ./ubuntu/uninstall.sh
```

O script remove o serviço, o executável e a configuração WireGuard protegida em `/etc/discord-golive-bypass`.

## Limitações importantes

- O modo `transmissao` acompanha os logs do Discord nativo e do Flatpak estável nos caminhos conhecidos. Para navegador, instalação Flatpak com ID/caminho diferente ou logs incompatíveis, use `completo`.
- O roteamento é por endereço IP, não por processo. Outros aplicativos que acessarem os mesmos IPs também podem passar pelo túnel.
- A lista de redes e o formato dos logs podem mudar com atualizações do Discord. Não há garantia de funcionamento em todas as versões, contas ou redes.
- O campo `DNS` da configuração não é aplicado; o resolvedor do sistema continua em uso.
- Se a VPN cair, os destinos selecionados podem ficar sem conexão até a VPN voltar ou o serviço ser parado. Não há fallback automático de saúde nesta versão.
- O serviço usa rotas IP e interface WireGuard próprias. Outras VPNs, regras de policy routing ou firewalls podem interferir.
- O instalador não altera UFW, NetworkManager, DNS, Secure Boot nem configurações do kernel.

## Testes

```bash
./ubuntu/build.sh test
./ubuntu/build.sh
bash -n ubuntu/build.sh ubuntu/install.sh ubuntu/uninstall.sh
```

Os testes automatizados verificam o núcleo de parsing, roteamento e leitura de logs. A instalação systemd e uma transmissão real precisam ser verificadas no computador de destino.
