# Discord Go Live Bypass — Linux

Adaptação Linux do [DiscordGoLiveBypass](https://github.com/thomassolcia/DiscordGoLiveBypass), com WireGuard nativo e inicialização automática pelo systemd.

## Distribuições

- **Pop!_OS 24.04 LTS e Ubuntu 24.04 LTS:** veja [instalação APT](ubuntu/README.md).
- **Fedora:** veja [instalação DNF](fedora/README.md).

O código compartilhado é Go. As instruções e scripts de cada distribuição ficam em suas pastas próprias.

## O que o programa faz

Encaminha destinos selecionados do Discord por uma VPN WireGuard com saída fora do Brasil. No modo padrão (`transmissao`), acompanha os logs do cliente para incluir os servidores de mídia do Go Live no túnel. O modo `completo` encaminha os destinos conhecidos do Discord, incluindo voz e câmera.

**Importante:** o roteamento é feito por endereço IP, não por processo. Outros aplicativos que acessarem os mesmos destinos IP também podem usar o túnel. Não há garantia de funcionamento para todas as versões do Discord, contas, VPNs ou redes.

## Segurança

- A configuração WireGuard contém uma chave privada. Não a publique nem a envie em issues.
- O programa aceita apenas campos WireGuard reconhecidos e não executa hooks como `PostUp` ou `PreDown`.
- O instalador protege a configuração em `/etc/discord-golive-bypass/wireguard.conf` com permissão `0600`.
- O campo `DNS` da configuração não é aplicado; o resolvedor do sistema permanece em uso.
- Se a VPN cair, destinos selecionados podem ficar sem conexão até o túnel voltar ou o serviço ser parado. Não há fallback automático nesta versão.

## Desenvolvimento

Requer Go 1.23 ou superior:

```bash
go test ./...
go vet ./...
```

Os testes automatizados cobrem parsing de configuração, seleção e reconciliação de rotas, interpretação de eventos RTC e leitura/rotação de logs. O workflow de CI compila e testa no Ubuntu 24.04. A instalação systemd e uma transmissão real precisam ser verificadas em cada máquina de destino.

## Créditos e licença

Derivado de [thomassolcia/DiscordGoLiveBypass](https://github.com/thomassolcia/DiscordGoLiveBypass), sob licença [GPL-3.0](LICENSE). Consulte [NOTICE.md](NOTICE.md) para os créditos e a origem do código.
