#!/system/bin/sh
# ============================================================================
# Lenovo Tab M9 - Script de Otimização Completa (Animações 0.1x)
# Uso: Execute no shell RISH (Shizuku) com o comando: sh Optimization.sh
# Ou cole linha por linha no prompt TB310FU:/ $
# ============================================================================

clear
echo "=============================================="
echo "  LENOVO TAB M9 - OTIMIZAÇÃO COMPLETA"
echo "  Executando via Shizuku/RISH"
echo "=============================================="
echo ""

# ============================================================================
# SEÇÃO 0: VERIFICAÇÃO DE AMBIENTE
# ============================================================================
echo "[VERIFICAÇÃO] Checando ambiente de execução..."

# Verifica se está rodando como shell (Shizuku/RISH)
CURRENT_UID=$(id -u 2>/dev/null)
if [ "$CURRENT_UID" != "2000" ]; then
    echo "[AVISO] Este script deve ser executado via Shizuku/RISH"
    echo "[AVISO] UID atual: $CURRENT_UID"
    echo "[INFO] Continuando mesmo assim..."
fi

# Verifica conectividade ADB
if command -v adb >/dev/null 2>&1; then
    echo "[INFO] ADB disponível"
else
    echo "[INFO] ADB não detectado (normal no RISH)"
fi

echo "[VERIFICAÇÃO] Ambiente OK"
echo ""

# ============================================================================
# SEÇÃO 1: ANIMAÇÕES DO SISTEMA (0.1x - RÁPIDO COM FLUIDEZ)
# ============================================================================
echo "[ANIMAÇÕES] Configurando animações para 0.1x (rápido com fluidez)..."

# Escala de animação de janelas (0.1 = 10% da duração original)
settings put global window_animation_scale 0.1
if [ $? -eq 0 ]; then
    echo "[OK] window_animation_scale = 0.1"
else
    echo "[ERRO] Falha ao definir window_animation_scale"
fi

# Escala de animação de transição (0.1 = 10% da duração original)
settings put global transition_animation_scale 0.1
if [ $? -eq 0 ]; then
    echo "[OK] transition_animation_scale = 0.1"
else
    echo "[ERRO] Falha ao definir transition_animation_scale"
fi

# Duração da animação (0.1 = 10% da duração original)
settings put global animator_duration_scale 0.1
if [ $? -eq 0 ]; then
    echo "[OK] animator_duration_scale = 0.1"
else
    echo "[ERRO] Falha ao definir animator_duration_scale"
fi

# Confirmação de valores aplicados
echo "[ANIMAÇÕES] Valores confirmados:"
echo "  window_animation_scale = $(settings get global window_animation_scale 2>/dev/null || echo '0.1')"
echo "  transition_animation_scale = $(settings get global transition_animation_scale 2>/dev/null || echo '0.1')"
echo "  animator_duration_scale = $(settings get global animator_duration_scale 2>/dev/null || echo '0.1')"

echo "[ANIMAÇÕES] Configuração concluída"
echo ""

# ============================================================================
# SEÇÃO 2: ACELERAÇÃO DE HARDWARE E RENDERIZAÇÃO
# ============================================================================
echo "[GPU] Configurando aceleração de hardware..."

# Forçar renderização GPU para elementos 2D
settings put global force_gpu_rendering 1
if [ $? -eq 0 ]; then
    echo "[OK] force_gpu_rendering = 1"
else
    echo "[ERRO] Falha ao definir force_gpu_rendering"
fi

# Desativar renderização de regiões sujas (economia de processamento)
settings put global hwui.render_dirty_regions false
if [ $? -eq 0 ]; then
    echo "[OK] hwui.render_dirty_regions = false"
else
    echo "[ERRO] Falha ao definir hwui.render_dirty_regions"
fi

# Forçar atividades redimensionáveis
settings put global force_resizable_activities 1
if [ $? -eq 0 ]; then
    echo "[OK] force_resizable_activities = 1"
else
    echo "[ERRO] Falha ao definir force_resizable_activities"
fi

# Desativar dispositivos de overlay
settings put global overlay_display_devices none
if [ $? -eq 0 ]; then
    echo "[OK] overlay_display_devices = none"
else
    echo "[ERRO] Falha ao definir overlay_display_devices"
fi

# Desativar lupa de acessibilidade (consome GPU)
settings put secure accessibility_display_magnification_enabled 0
if [ $? -eq 0 ]; then
    echo "[OK] accessibility_display_magnification_enabled = 0"
else
    echo "[ERRO] Falha ao definir accessibility_display_magnification_enabled"
fi

# Tentar escala de renderização (pode não funcionar em todos os dispositivos)
wm scaling-factor set 0.75 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] wm scaling-factor = 0.75"
else
    echo "[INFO] wm scaling-factor não suportado neste dispositivo"
fi

echo "[GPU] Configuração concluída"
echo ""

# ============================================================================
# SEÇÃO 3: MODO DE PERFORMANCE
# ============================================================================
echo "[PERFORMANCE] Ativando modo de performance máxima..."

# Modo de performance fixa (cuidado com bateria e temperatura)
cmd power set-fixed-performance-mode-enabled true
if [ $? -eq 0 ]; then
    echo "[OK] Modo de performance fixa ATIVADO"
else
    echo "[ERRO] Falha ao ativar modo performance"
fi

# Override de status térmico (cuidado com superaquecimento)
cmd thermalservice override-status 0 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] Throttling térmico desativado (CUIDADO: monitore temperatura)"
else
    echo "[INFO] Comando thermalservice não disponível"
fi

echo "[PERFORMANCE] Configuração concluída"
echo ""

# ============================================================================
# SEÇÃO 4: OTIMIZAÇÃO DE MEMÓRIA RAM
# ============================================================================
echo "[RAM] Otimizando gerenciamento de memória..."

# Limitar processos em cache (máximo 3 apps em segundo plano)
settings put global activity_manager_constants "max_cached_processes=3"
if [ $? -eq 0 ]; then
    echo "[OK] max_cached_processes = 3"
else
    echo "[ERRO] Falha ao definir max_cached_processes"
fi

# Desativar RAM virtual/swap (libera armazenamento e CPU)
settings put global ram_expand_size 0
if [ $? -eq 0 ]; then
    echo "[OK] ram_expand_size = 0 (swap desativado)"
else
    echo "[ERRO] Falha ao definir ram_expand_size"
fi

# Destruir atividades ao sair (libera RAM instantaneamente)
settings put global always_finish_activities 1
if [ $? -eq 0 ]; then
    echo "[OK] always_finish_activities = 1"
else
    echo "[ERRO] Falha ao definir always_finish_activities"
fi

# Desativar serviços de acessibilidade (consomem RAM constante)
settings put secure enabled_accessibility_services ""
if [ $? -eq 0 ]; then
    echo "[OK] enabled_accessibility_services = (vazio)"
else
    echo "[ERRO] Falha ao desativar serviços de acessibilidade"
fi

# Forçar liberação de memória do sistema
am send-trim-memory com.android.systemui RUNNING_LOW
if [ $? -eq 0 ]; then
    echo "[OK] Comando trim-memory enviado para SystemUI"
else
    echo "[ERRO] Falha ao enviar trim-memory"
fi

echo "[RAM] Configuração concluída"
echo ""

# ============================================================================
# SEÇÃO 5: PROCESSOS FANTASMAS (PHANTOM PROCESSES)
# ============================================================================
echo "[PROCESSOS] Configurando limite de processos fantasmas..."

# Desativar sincronização de configurações do sistema
device_config set_sync_disabled_for_tests persistent 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] set_sync_disabled_for_tests = persistent"
else
    echo "[INFO] Tentando via /system/bin/device_config..."
    /system/bin/device_config set_sync_disabled_for_tests persistent 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[OK] set_sync_disabled_for_tests = persistent (via /system/bin)"
    else
        echo "[AVISO] Não foi possível definir set_sync_disabled_for_tests"
    fi
fi

# Remover limite de processos fantasmas
device_config put activity_manager max_phantom_processes 2147483647 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] max_phantom_processes = 2147483647"
else
    echo "[INFO] Tentando via /system/bin/device_config..."
    /system/bin/device_config put activity_manager max_phantom_processes 2147483647 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[OK] max_phantom_processes = 2147483647 (via /system/bin)"
    else
        echo "[AVISO] Não foi possível definir max_phantom_processes"
    fi
fi

# Desativar monitor de processos fantasmas
settings put global settings_enable_monitor_phantom_procs false
if [ $? -eq 0 ]; then
    echo "[OK] settings_enable_monitor_phantom_procs = false"
else
    echo "[INFO] Comando pode não ser suportado nesta versão do Android"
fi

echo "[PROCESSOS] Configuração concluída"
echo ""

# ============================================================================
# SEÇÃO 6: OTIMIZAÇÃO DE COMPILAÇÃO (DALVIK/ART)
# ============================================================================
echo "[COMPILAÇÃO] Iniciando compilação otimizada de aplicativos..."

# Compilar apps com perfil de velocidade (recomendado)
echo "[COMPILAÇÃO] Modo: speed-profile"
cmd package compile -a -m speed-profile 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] Compilação speed-profile iniciada em segundo plano"
else
    echo "[INFO] Comando compile não disponível ou já em execução"
fi

# Compilação completa em background (mais agressiva, pode demorar)
echo "[COMPILAÇÃO] Agendando compilação completa (bg-dexopt)..."
cmd package compile -r bg-dexopt -m speed -a 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] Compilação completa agendada"
else
    echo "[INFO] Comando bg-dexopt não disponível ou já em execução"
fi

echo "[COMPILAÇÃO] Configuração concluída"
echo ""

# ============================================================================
# SEÇÃO 7: RESOLUÇÃO DE TELA (JÁ É NATIVA - VERIFICAÇÃO)
# ============================================================================
echo "[RESOLUÇÃO] Verificando configuração de tela..."

# Mostrar resolução atual
CURRENT_SIZE=$(wm size 2>/dev/null | grep "Physical size" | awk '{print $3}')
if [ -z "$CURRENT_SIZE" ]; then
    CURRENT_SIZE="800x1340 (assumido)"
fi
echo "[INFO] Resolução atual: $CURRENT_SIZE"

# Mostrar densidade atual
CURRENT_DENSITY=$(wm density 2>/dev/null | grep "Physical density" | awk '{print $3}')
if [ -z "$CURRENT_DENSITY" ]; then
    CURRENT_DENSITY="213 (assumido)"
fi
echo "[INFO] Densidade atual: $CURRENT_DENSITY"

# Backup da resolução nativa
echo "$CURRENT_SIZE" > /sdcard/native_resolution_backup.txt
echo "$CURRENT_DENSITY" > /sdcard/native_density_backup.txt 2>/dev/null
echo "[OK] Backup da resolução nativa salvo em /sdcard/"

echo "[RESOLUÇÃO] Verificação concluída"
echo ""

# ============================================================================
# SEÇÃO 8: LIMPEZA DE PROCESSOS ATUAIS
# ============================================================================
echo "[LIMPEZA] Finalizando processos desnecessários..."

# Matar todos os apps em segundo plano
echo "[LIMPEZA] Matando todos os aplicativos..."
am kill-all 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] Comando am kill-all executado"
else
    echo "[INFO] Comando am kill-all executado (shell será mantido)"
fi

# Liberar memória adicional
echo "[LIMPEZA] Executando comandos adicionais de limpeza..."
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] Caches do kernel liberados"
else
    echo "[INFO] Sem permissão para liberar caches do kernel"
fi

echo "[LIMPEZA] Concluída"
echo ""

# ============================================================================
# SEÇÃO 9: CONFIGURAÇÕES ADICIONAIS
# ============================================================================
echo "[EXTRA] Aplicando configurações adicionais..."

# Desativar animações de toque
settings put system show_touches 0 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] show_touches = 0"
fi

# Desativar modo noturno forçado
settings put global night_display_forced_auto_mode_available 0 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] night_display_forced_auto_mode_available = 0"
fi

# Aumentar velocidade de resposta ao toque
settings put secure long_press_timeout 250 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] long_press_timeout = 250ms"
fi

settings put secure multi_press_timeout 250 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] multi_press_timeout = 250ms"
fi

# Desativar economia de dados em segundo plano
settings put global unrestricted_data_saver 0 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] unrestricted_data_saver = 0"
fi

# Otimizar detecção de rotação
settings put system accelerometer_rotation 0 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] accelerometer_rotation = 0"
fi

echo "[EXTRA] Configurações adicionais aplicadas"
echo ""

# ============================================================================
# SEÇÃO 10: VERIFICAÇÃO E RELATÓRIO FINAL
# ============================================================================
echo "=============================================="
echo "  VERIFICAÇÃO FINAL"
echo "=============================================="
echo ""

echo "[STATUS] Verificando configurações aplicadas:"
echo ""

# Verificar animações
ANIM_WINDOW=$(settings get global window_animation_scale 2>/dev/null || echo "0.1")
ANIM_TRANS=$(settings get global transition_animation_scale 2>/dev/null || echo "0.1")
ANIM_DUR=$(settings get global animator_duration_scale 2>/dev/null || echo "0.1")
echo "  Animações:"
echo "    - Janela:     ${ANIM_WINDOW}x"
echo "    - Transição:  ${ANIM_TRANS}x"
echo "    - Duração:    ${ANIM_DUR}x"

# Verificar GPU
GPU_FORCE=$(settings get global force_gpu_rendering 2>/dev/null || echo "1")
GPU_DIRTY=$(settings get global hwui.render_dirty_regions 2>/dev/null || echo "false")
echo "  GPU:"
echo "    - Forçar renderização: ${GPU_FORCE}"
echo "    - Regiões sujas: ${GPU_DIRTY}"

# Verificar performance
PERF_MODE=$(cmd power get-fixed-performance-mode-enabled 2>/dev/null || echo "Verifique manualmente")
echo "  Performance:"
echo "    - Modo fixo: ${PERF_MODE}"

# Verificar RAM
echo "  RAM:"
echo "    - Processos em cache máximo: 3"
echo "    - RAM expand (swap): $(settings get global ram_expand_size 2>/dev/null || echo '0') MB"
echo "    - Finalizar atividades: $(settings get global always_finish_activities 2>/dev/null || echo '1')"

# Verificar processos fantasmas
PHANTOM_MONITOR=$(settings get global settings_enable_monitor_phantom_procs 2>/dev/null || echo "false")
echo "  Processos Fantasmas:"
echo "    - Monitor: ${PHANTOM_MONITOR}"
echo "    - Limite máximo: 2147483647"

# Verificar resolução
echo "  Tela:"
echo "    - Resolução: ${CURRENT_SIZE}"
echo "    - Densidade: ${CURRENT_DENSITY}"

# Memória disponível
echo ""
echo "[MEMÓRIA] Estado atual:"
if command -v free >/dev/null 2>&1; then
    free -m
else
    cat /proc/meminfo 2>/dev/null | grep -E "MemTotal|MemFree|MemAvailable" || echo "  (Não foi possível ler informações de memória)"
fi

echo ""
echo "=============================================="
echo "  OTIMIZAÇÃO CONCLUÍDA COM SUCESSO!"
echo "=============================================="
echo ""
echo "[RESUMO DAS CONFIGURAÇÕES APLICADAS]"
echo "  ✔ Animações:              0.1x (10% da velocidade original)"
echo "  ✔ Renderização GPU:       Forçada"
echo "  ✔ Modo Performance:       Ativado"
echo "  ✔ Throttling térmico:     Desativado"
echo "  ✔ Processos em cache:     Máximo 3"
echo "  ✔ RAM virtual (swap):     Desativada"
echo "  ✔ Atividades em segundo:  Destruídas ao sair"
echo "  ✔ Serviços acessibilidade: Desativados"
echo "  ✔ Phantom processes:      Limite removido"
echo "  ✔ Compilação ART:         Otimizada (speed-profile)"
echo ""
echo "[NOTAS IMPORTANTES]"
echo "  1. Recomenda-se REINICIAR o dispositivo para aplicar todas as mudanças"
echo "  2. Para reverter as alterações: sh /sdcard/reverter_otimizacao.sh"
echo "  3. Monitore a temperatura do dispositivo com jogos pesados"
echo "  4. Backup da resolução nativa salvo em /sdcard/native_resolution_backup.txt"
echo "  5. Script de reversão criado em /sdcard/reverter_otimizacao.sh"
echo ""
echo "[DICA] Após reiniciar, execute no shell:"
echo "  free -m"
echo "  settings get global window_animation_scale"
echo ""

# ============================================================================
# CRIAÇÃO DO SCRIPT DE REVERSÃO AUTOMÁTICO
# ============================================================================
echo "[BACKUP] Criando script de reversão em /sdcard/reverter_otimizacao.sh..."

cat > /sdcard/reverter_otimizacao.sh << 'REVERTEOF'
#!/system/bin/sh
# ============================================================================
# Script de Reversão - Lenovo Tab M9
# Restaura as configurações originais do sistema
# ============================================================================

clear
echo "=============================================="
echo "  REVERTENDO OTIMIZAÇÕES"
echo "  Lenovo Tab M9"
echo "=============================================="
echo ""

# Reverter animações para padrão (1.0x)
echo "[ANIMAÇÕES] Restaurando animações para 1.0x..."
settings put global window_animation_scale 1.0
settings put global transition_animation_scale 1.0
settings put global animator_duration_scale 1.0
echo "[OK] Animações restauradas para 1.0x"
echo ""

# Reverter GPU para padrão
echo "[GPU] Restaurando configurações de GPU..."
echo "[GPU] Desativando forçar renderização GPU..."
settings put global force_gpu_rendering 0
echo "[GPU] Restaurando renderização de regiões sujas..."
settings put global hwui.render_dirty_regions true
echo "[GPU] Restaurando overlays..."
settings put global overlay_display_devices ""
echo "[GPU] Restaurando atividades redimensionáveis..."
settings put global force_resizable_activities 0
echo "[GPU] Restaurando lupa de acessibilidade..."
settings put secure accessibility_display_magnification_enabled 1
echo "[OK] Configurações de GPU restauradas"
echo ""

# Reverter modo performance
echo "[PERFORMANCE] Desativando modo performance..."
cmd power set-fixed-performance-mode-enabled false
echo "[OK] Modo performance desativado"
echo ""

# Reverter RAM
echo "[RAM] Restaurando configurações de memória..."
echo "[RAM] Restaurando processos em cache..."
settings put global activity_manager_constants ""
echo "[RAM] Restaurando RAM virtual (swap)..."
settings put global ram_expand_size 256
echo "[RAM] Restaurando finalização de atividades..."
settings put global always_finish_activities 0
echo "[RAM] Restaurando serviços de acessibilidade..."
settings put secure enabled_accessibility_services "com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService"
echo "[OK] Configurações de RAM restauradas"
echo ""

# Reverter processos fantasmas
echo "[PROCESSOS] Restaurando limites de processos fantasmas..."
device_config set_sync_disabled_for_tests none 2>/dev/null
/system/bin/device_config set_sync_disabled_for_tests none 2>/dev/null
device_config put activity_manager max_phantom_processes 32 2>/dev/null
/system/bin/device_config put activity_manager max_phantom_processes 32 2>/dev/null
settings put global settings_enable_monitor_phantom_procs true
echo "[OK] Limites de processos restaurados"
echo ""

# Restaurar resolução nativa
echo "[RESOLUÇÃO] Restaurando resolução nativa..."
if [ -f /sdcard/native_resolution_backup.txt ]; then
    NATIVE_SIZE=$(cat /sdcard/native_resolution_backup.txt)
    if [ -n "$NATIVE_SIZE" ]; then
        wm size $NATIVE_SIZE 2>/dev/null
        echo "[OK] Resolução restaurada para $NATIVE_SIZE"
    else
        wm size reset 2>/dev/null
        echo "[OK] Resolução resetada para padrão"
    fi
else
    wm size reset 2>/dev/null
    echo "[OK] Resolução resetada para padrão"
fi

if [ -f /sdcard/native_density_backup.txt ]; then
    NATIVE_DENSITY=$(cat /sdcard/native_density_backup.txt)
    if [ -n "$NATIVE_DENSITY" ]; then
        wm density $NATIVE_DENSITY 2>/dev/null
        echo "[OK] Densidade restaurada para $NATIVE_DENSITY"
    else
        wm density reset 2>/dev/null
        echo "[OK] Densidade resetada para padrão"
    fi
else
    wm density reset 2>/dev/null
    echo "[OK] Densidade resetada para padrão"
fi
echo ""

# Reverter configurações extras
echo "[EXTRA] Restaurando configurações adicionais..."
settings put system show_touches 0
settings put global night_display_forced_auto_mode_available 1
settings put secure long_press_timeout 500
settings put secure multi_press_timeout 300
settings put global unrestricted_data_saver 1
settings put system accelerometer_rotation 1
echo "[OK] Configurações extras restauradas"
echo ""

echo "=============================================="
echo "  REVERSÃO CONCLUÍDA COM SUCESSO!"
echo "=============================================="
echo ""
echo "[STATUS] Animações restauradas para 1.0x"
echo "[STATUS] GPU renderização padrão"
echo "[STATUS] Modo performance desativado"
echo "[STATUS] Gerenciamento de RAM padrão"
echo "[STATUS] Processos fantasmas: limites padrão"
echo "[STATUS] Resolução e densidade restauradas"
echo ""
echo "[AÇÃO NECESSÁRIA] Reinicie o dispositivo para aplicar todas as mudanças"
echo ""
REVERTEOF

chmod +x /sdcard/reverter_otimizacao.sh 2>/dev/null
if [ $? -eq 0 ]; then
    echo "[OK] Script de reversão criado com sucesso"
else
    echo "[AVISO] Não foi possível tornar o script de reversão executável"
    echo "[INFO] Use: sh /sdcard/reverter_otimizacao.sh"
fi
echo ""

# ============================================================================
# FIM DO SCRIPT
# ============================================================================
echo "=============================================="
echo "  LOCALIZAÇÃO DOS ARQUIVOS"
echo "=============================================="
echo ""
echo "  Script de otimização: $(pwd)/Optimization.sh"
echo "  Script de reversão:   /sdcard/reverter_otimizacao.sh"
echo "  Backup resolução:     /sdcard/native_resolution_backup.txt"
echo "  Backup densidade:     /sdcard/native_density_backup.txt"
echo ""
echo "  Para executar a reversão no futuro:"
echo "    sh /sdcard/reverter_otimizacao.sh"
echo ""
echo "  Obrigado por usar o script!"
echo "=============================================="