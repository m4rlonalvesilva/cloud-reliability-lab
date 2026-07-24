# Runbook — Disco cheio (filesystem)

## Sintoma

- Trigger de filesystem low / disk space  
- `df -h` mostra uso alto (ex. >90%)  
- Apps falham a escrever logs, DB, temp  

## Impacto

Serviços deixam de gravar dados; risco de crash. Severidade: **HIGH**.

## Diagnóstico

```bash
df -h
df -hi
sudo du -xhd1 /var 2>/dev/null | sort -h | tail -15
sudo du -xhd1 /var/tmp 2>/dev/null | sort -h | tail -10
```

## Causas possíveis

- Logs sem rotação  
- Dump / backup antigo  
- Drill de lab em `/var/tmp/crl-lab-fill`  
- Container images / overlay a crescer  

## Mitigação / Resolução

```bash
# Lab — apagar o fill do drill
sudo bash ~/drills/disk-full.sh restore
# ou
sudo rm -rf /var/tmp/crl-lab-fill

# Prod — exemplos
sudo journalctl --vacuum-size=200M
# limpar logs da app com owner; NÃO apagar à sorte em /var/lib
```

## Validação

- [ ] `df -h` com espaço livre  
- [ ] Problem OK no Zabbix  
- [ ] App volta a escrever  

## Lab

```bash
bash drills/disk-full.sh start
bash drills/disk-full.sh restore
```
