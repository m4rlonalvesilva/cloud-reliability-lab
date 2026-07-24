# Runbook — Zabbix Agent down / unreachable

## Sintoma

- Host a vermelho / Agent unavailable na UI  
- Problems com trigger de agent / “Zabbix agent is not available” (nome varia com o template)  
- Latest data deixa de atualizar  

## Impacto

- **Perda de monitoração** daquele host (cego para CPU, disco, serviços via agent)  
- Em produção: podes ter SSH/consola, mas alertas de app/infra daquela máquina falham  

Severidade sugerida: **HIGH** (não é “a app caiu”, mas perdes visibilidade).

## Diagnóstico

1. Ainda consegues **SSH** ao host?  
2. O serviço do agent está a correr?

```bash
sudo systemctl status zabbix-agent2 --no-pager
sudo journalctl -u zabbix-agent2 -n 80 --no-pager
ps aux | grep -i '[z]abbix_agent2'
```

3. Conf do agent aponta para o Server certo?

```bash
grep -E '^(Server|ServerActive|Hostname)=' /etc/zabbix/zabbix_agent2.conf
```

4. Do Server (opcional):

```bash
sudo zabbix_get -s <IP_PRIVADO_DO_HOST> -k agent.ping
# esperado: 1
```

## Causas possíveis

- `systemctl stop` / crash / OOM matou o agent  
- Conf errada (`Server`/`Hostname`)  
- Rede/SG (no lab raro, SG self já permite)  
- Disco cheio a impedir logs/socket  

## Mitigação / Resolução

```bash
sudo systemctl start zabbix-agent2
sudo systemctl enable zabbix-agent2
sudo systemctl restart zabbix-agent2
sudo systemctl status zabbix-agent2 --no-pager
```

Se não arrancar: ler o journal, corrigir conf, garantir disco com espaço (`df -h`).

## Validação

- [ ] `systemctl is-active zabbix-agent2` → `active`  
- [ ] UI: agent verde  
- [ ] Latest data a atualizar  
- [ ] Problem em OK / desapareceu  

## Escalonamento (prod)

- Sem SSH e sem agent → escalar infra/rede/hypervisor  
- Agent a crashar em loop → abrir incidente com logs + versão do pacote  

## Lab — reproduzir / restaurar

```bash
# No host alvo:
sudo bash sre/drills/agent-down.sh start    # se o repo estiver no host
# ou:
sudo systemctl stop zabbix-agent2

# Restaurar:
sudo bash sre/drills/agent-down.sh restore
# ou:
sudo systemctl start zabbix-agent2
```

Guia de prática: [../zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md](../zabbix/02-ENTENDER-E-TRATAR-ALERTAS.md)
