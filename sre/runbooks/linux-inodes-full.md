# Runbook — Inodes esgotados

## Sintoma

- `df -h` ainda tem espaço em GB, mas apps falham com “No space left”  
- `df -hi` mostra inodes a 100%  
- Tipicamente muitos ficheiros pequenos  

## Impacto

Não crias ficheiros novos (logs, sockets, deploys). Severidade: **HIGH**.

## Diagnóstico

```bash
df -hi
sudo find /var/tmp/crl-lab-inodes -type f 2>/dev/null | wc -l
# Prod: achar diretórios com muitos ficheiros
sudo find /var -xdev -type d -print0 2>/dev/null | head -1 >/dev/null
# Exemplo prático:
sudo du --inodes -d1 /var/tmp 2>/dev/null | sort -n | tail -10
```

## Mitigação / Resolução

```bash
sudo bash ~/drills/inodes-full.sh restore
# Prod: limpar caches de app, sessões, spool de mail, etc. com critério
```

## Validação

- [ ] `df -hi` com inodes livres  
- [ ] Consegues `touch /var/tmp/crl-inode-test && rm /var/tmp/crl-inode-test`  

## Lab

```bash
bash drills/inodes-full.sh start
bash drills/inodes-full.sh restore
```
