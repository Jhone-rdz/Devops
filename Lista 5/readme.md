Nível 1
1. Listar arquivos de log gerados:
ls lab_logs/
Arquivos gerados: syslog.log, auth.log, app.log, db.log, disk.log
2. Acompanhar logs em tempo real:
tail -f lab_logs/*.log
3. Papel dos serviços:
systemd — gerenciador de serviços do Linux; inicia, para e monitora todos os outros processos do sistema
node — executa a aplicação backend em Node.js
mysql — serviço do banco de dados relacional
sshd — daemon de acesso remoto seguro (SSH)

Nível 2
4. Identificar erros da aplicação:
grep "ERROR" lab_logs/app.log
5. Identificar falhas no banco:
grep "ERROR" lab_logs/db.log
6. Detectar ataques SSH:
grep "Failed password" lab_logs/auth.log
7. Verificar problemas de disco:
grep -E "ERROR|WARNING" lab_logs/disk.log

Nível 3
(a) Relacionar falhas da aplicação com logs do sistema:
Toda vez que o app.log registra ERROR: UnhandledPromiseRejectionWarning, 
o syslog.log registra node.service: Failed. — o systemd percebe a queda do 
processo e também loga. O mesmo vale para o MySQL: o db.log mostra o erro de 
conexão e o syslog.log confirma mysql.service: Failed.
(b) Existe padrão entre as falhas?
R: Sim. As falhas são periódicas e independentes entre si, pois são geradas
aleatoriamente (evento 0 a 4). Porém, em sistemas reais, falha no banco 
geralmente causa falha na aplicação logo em seguida, pois a API depende do MySQL.
(c) Qual falha ocorre com maior frequência? 
R: Com 5 eventos possíveis (0 a 4), cada um tem ~20% de probabilidade.
Em uma amostra grande, tenderão a ocorrer com frequência equivalente.

Nível 4
(a) Detectar erro na aplicação:
grep "ERROR" lab_logs/app.log && echo "[ALERTA] Aplicação com erro!"
(b) Detectar tentativas de ataque SSH:
grep "Failed password" lab_logs/auth.log | \
  grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | \
  sort | uniq -c | sort -rn
(c) Monitorar todos os logs em tempo real:
tail -f lab_logs/*.log

Nível 5
(a) Ação para cada evento:
EventoAçãoFalha na aplicação: systemctl restart node.service
Falha  no banco de dados: systemctl restart mysql.service
Disco cheio: df -h para verificar; du -sh /* | sort -rh | head -10 para localizar o maior consumo; limpar logs antigos
Ataque SSH: Bloquear o IP com  iptables -A INPUT -s <IP> -j DROP
(b) Identificar IPs suspeitos:
grep "Failed password" lab_logs/auth.log | \
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | \
sort | uniq -c | sort -rn~



