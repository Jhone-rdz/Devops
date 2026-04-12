
## Nível 1 – Observação

**1. Listar os arquivos de log gerados:**

```bash
ls lab_logs/
```

Arquivos gerados: `syslog.log`, `auth.log`, `app.log`, `db.log`, `disk.log`

**2. Acompanhar logs em tempo real:**

```bash
tail -f lab_logs/*.log
```

**3. Papel dos serviços:**

| Serviço | Função |
|---------|--------|
| `systemd` | Gerenciador de serviços do Linux; inicia, para e monitora todos os outros processos do sistema |
| `node` | Executa a aplicação backend em Node.js |
| `mysql` | Serviço do banco de dados relacional MySQL |
| `sshd` | Daemon de acesso remoto seguro (SSH); autentica conexões na porta 22 |

---

## Nível 2 – Análise

**4. Identificar erros da aplicação:**

```bash
grep "ERROR" lab_logs/app.log
```

**5. Identificar falhas no banco:**

```bash
grep "ERROR" lab_logs/db.log
```

**6. Detectar ataques SSH:**

```bash
grep "Failed password" lab_logs/auth.log
```

**7. Verificar problemas de disco:**

```bash
grep -E "ERROR|WARNING" lab_logs/disk.log
```

---

## Nível 3 – Correlação

**(a) Relacionar falhas da aplicação com logs do sistema:**

Toda vez que o `app.log` registra `ERROR: UnhandledPromiseRejectionWarning`, o `syslog.log` registra `node.service: Failed.` — o systemd percebe a queda do processo e também loga. O mesmo vale para o MySQL: o `db.log` mostra o erro de conexão e o `syslog.log` confirma `mysql.service: Failed.`

**(b) Existe padrão entre as falhas?**

Sim. As falhas são periódicas e independentes entre si, pois são geradas aleatoriamente (evento 0 a 4). Porém, em sistemas reais, falha no banco geralmente causa falha na aplicação logo em seguida, pois a API depende do MySQL.

**(c) Qual falha ocorre com maior frequência?**

Com 5 eventos possíveis (0 a 4), cada um tem ~20% de probabilidade. Em uma amostra grande, tenderão a ocorrer com frequência equivalente. Para verificar nos logs gerados:

```bash
echo "App:  $(grep -c ERROR lab_logs/app.log)"
echo "DB:   $(grep -c ERROR lab_logs/db.log)"
echo "SSH:  $(grep -c 'Failed password' lab_logs/auth.log)"
echo "Disk: $(grep -c ERROR lab_logs/disk.log)"
```

---

## Nível 4 – Automação

**(a) Detectar erro na aplicação:**

```bash
grep "ERROR" lab_logs/app.log && echo "[ALERTA] Aplicação com erro!"
```

**(b) Detectar tentativas de ataque SSH:**

```bash
grep "Failed password" lab_logs/auth.log | \
  grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | \
  sort | uniq -c | sort -rn
```

**(c) Monitorar todos os logs em tempo real:**

```bash
tail -f lab_logs/*.log
```

---

## Nível 5 – Resposta a Incidentes

**(a) Ação para cada evento:**

| Evento | Ação |
|--------|------|
| Falha na aplicação | `systemctl restart node.service` |
| Falha no banco de dados | `systemctl restart mysql.service` |
| Disco cheio | Verificar com `df -h`; localizar maior consumo com `du -sh /* \| sort -rh \| head -10`; limpar logs antigos |
| Ataque SSH | Bloquear o IP com `iptables -A INPUT -s <IP> -j DROP` |

**(b) Identificar IPs suspeitos:**

```bash
grep "Failed password" lab_logs/auth.log | \
  grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | \
  sort | uniq -c | sort -rn
```

---
