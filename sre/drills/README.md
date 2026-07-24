# Drills SRE — reproduzir e restaurar incidentes

Cada script: `start` (provoca) e `restore` (limpa).  
**Corre sempre o restore** antes de sair da sessão.

| Script | Cenário |
|--------|---------|
| `agent-down.sh` | Agent Zabbix parado |
| `cpu-high.sh` | CPU alta |
| `memory-high.sh` | Memória alta |
| `disk-full.sh` | Disco parcialmente cheio |
| `inodes-full.sh` | Inodes esgotados |
| `service-down.sh` | Serviço `crl-lab-app` parado (`install`/`start`/`restore`) |
| `port-down.sh` | Porta 8089 em baixo |
| `load-high.sh` | Load average alta |
| `clock-skew.sh` | NTP/chrony parado |
| `kubelet-down.sh` | Kubelet parado (NotReady) |
| `containerd-down.sh` | Containerd parado |
| `log-storm.sh` | Tempestade de logs |

Catálogo e ordem de prática: [`../zabbix/03-CENARIOS-VIDA-REAL.md`](../zabbix/03-CENARIOS-VIDA-REAL.md)
