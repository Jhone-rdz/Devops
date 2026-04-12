#!/bin/bash

# ============================================
# auto-heal.sh - Script de Monitoramento
# ============================================

LOG_DIR="./lab_logs"
APPLOG="$LOG_DIR/app.log"
DBLOG="$LOG_DIR/db.log"
DISKLOG="$LOG_DIR/disk.log"
AUTHLOG="$LOG_DIR/auth.log"

echo "========================================"
echo "  AUTO-HEAL - Monitor de Incidentes"
echo "  $(date '+%d/%m/%Y %H:%M:%S')"
echo "========================================"
echo ""

# ============================================
# 1. FALHA NA APLICAÇÃO NODE.JS
# ============================================
echo "[ Verificando aplicação Node.js... ]"
if grep -q "ERROR" "$APPLOG" 2>/dev/null; then
    TOTAL_ERROS=$(grep -c "ERROR" "$APPLOG")
    ULTIMO_ERRO=$(grep "ERROR" "$APPLOG" | tail -1)
    echo "[ALERTA] Aplicação com erro!"
    echo "         Total de erros encontrados: $TOTAL_ERROS"
    echo "         Último erro: $ULTIMO_ERRO"
    echo "         Ação sugerida: reiniciar o serviço com 'systemctl restart node.service'"
else
    echo "[OK] Aplicação Node.js sem erros."
fi
echo ""

# ============================================
# 2. FALHA NO BANCO DE DADOS
# ============================================
echo "[ Verificando banco de dados MySQL... ]"
if grep -q "ERROR" "$DBLOG" 2>/dev/null; then
    TOTAL_DB=$(grep -c "ERROR" "$DBLOG")
    ULTIMO_DB=$(grep "ERROR" "$DBLOG" | tail -1)
    echo "[ALERTA] Banco de dados com problema!"
    echo "         Total de erros encontrados: $TOTAL_DB"
    echo "         Último erro: $ULTIMO_DB"
    echo "         Ação sugerida: reiniciar o serviço com 'systemctl restart mysql.service'"
else
    echo "[OK] MySQL sem falhas detectadas."
fi
echo ""

# ============================================
# 3. DISCO CHEIO
# ============================================
echo "[ Verificando uso de disco... ]"
if grep -q "ERROR\|WARNING" "$DISKLOG" 2>/dev/null; then
    echo "[ALERTA] Problema de disco detectado!"
    grep "ERROR\|WARNING" "$DISKLOG" | tail -3 | while read linha; do
        echo "         >> $linha"
    done
    echo "         Ação sugerida: executar 'df -h' e liberar espaço com 'du -sh /* | sort -rh | head -10'"
else
    echo "[OK] Disco sem alertas."
fi
echo ""

# ============================================
# 4. ATAQUES SSH
# ============================================
echo "[ Verificando tentativas de acesso SSH... ]"
if grep -q "Failed password" "$AUTHLOG" 2>/dev/null; then
    TOTAL_SSH=$(grep -c "Failed password" "$AUTHLOG")
    echo "[ALERTA] Tentativas de ataque SSH detectadas!"
    echo "         Total de tentativas: $TOTAL_SSH"
    echo ""
    echo "         IPs suspeitos:"
    grep "Failed password" "$AUTHLOG" \
        | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
        | sort | uniq -c | sort -rn \
        | while read count ip; do
            echo "           $ip — $count tentativa(s)"
        done
    echo ""
    echo "         Ação sugerida: bloquear IPs com 'iptables -A INPUT -s <IP> -j DROP'"
else
    echo "[OK] Nenhuma tentativa de ataque SSH detectada."
fi

echo ""
echo "========================================"
echo "  Verificação concluída."
echo "========================================"
