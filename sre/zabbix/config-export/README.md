# config-export/

Exportações da configuração Zabbix do lab (hosts, templates, triggers).

Gerado por:

```bash
./sre/zabbix/scripts/backup-zabbix-config.sh
```

**Versiona no Git** antes do `terraform destroy`.  
Após novo `apply`: `restore-zabbix-config.sh` + `sync-host-agent-ips.sh`.

Ver [../05-BACKUP-E-RESTORE.md](../05-BACKUP-E-RESTORE.md).
