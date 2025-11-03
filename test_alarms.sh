#!/bin/bash
# ============================================================================
# Script para Probar Alarmas de CloudWatch
# ============================================================================
# Este script te ayuda a probar que las alarmas funcionan correctamente
# generando diferentes tipos de eventos que deberían activarlas.
#
# Uso: ./test_alarms.sh [tipo_prueba]
# Tipos de prueba: 5xx, latency, cpu, all
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Obtener la URL del ambiente desde Terraform
print_info "Obteniendo URL del ambiente..."
EB_URL=$(terraform output -raw eb_environment_cname 2>/dev/null)

if [ -z "$EB_URL" ]; then
    print_error "No se pudo obtener la URL del ambiente. ¿Ejecutaste 'terraform apply'?"
    exit 1
fi

print_success "URL del ambiente: https://$EB_URL"

# ============================================================================
# Prueba 1: Generar Errores 5xx
# ============================================================================
test_5xx_errors() {
    print_info "Iniciando prueba de errores 5xx..."
    print_warning "Esta prueba intentará generar errores 5xx"
    
    echo ""
    echo "Para activar la alarma de 5xx, necesitas:"
    echo "1. Introducir un bug en tu código que cause errores 500"
    echo "2. O sobrecargar la aplicación con muchas peticiones"
    echo ""
    
    print_info "Enviando 50 peticiones a un endpoint inexistente..."
    
    for i in {1..50}; do
        curl -s -o /dev/null -w "%{http_code}\n" "https://$EB_URL/endpoint-que-no-existe" &
        
        if [ $((i % 10)) -eq 0 ]; then
            print_info "Enviadas $i peticiones..."
        fi
    done
    
    wait
    
    print_success "Prueba completada. Revisa CloudWatch en 5-10 minutos"
    print_info "Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards"
}

# ============================================================================
# Prueba 2: Generar Alta Latencia
# ============================================================================
test_latency() {
    print_info "Iniciando prueba de latencia..."
    
    echo ""
    echo "Para probar latencia alta, puedes:"
    echo "1. Añadir un delay artificial en tu código"
    echo "2. Realizar consultas pesadas a DynamoDB"
    echo "3. Enviar muchas peticiones concurrentes"
    echo ""
    
    print_info "Enviando 100 peticiones concurrentes..."
    
    for i in {1..100}; do
        curl -s -w "@curl-format.txt" -o /dev/null "https://$EB_URL/" &
        
        if [ $((i % 20)) -eq 0 ]; then
            print_info "Enviadas $i peticiones..."
        fi
    done
    
    wait
    
    print_success "Prueba completada. Revisa las métricas de latencia en CloudWatch"
}

# ============================================================================
# Prueba 3: Simular Alto Uso de CPU
# ============================================================================
test_cpu() {
    print_info "Iniciando prueba de CPU..."
    
    echo ""
    print_warning "Para probar la alarma de CPU, necesitas acceso SSH a la instancia EC2"
    echo ""
    echo "Pasos para conectarte:"
    echo "1. Habilita SSH en Elastic Beanstalk:"
    echo "   - Ve a la consola de EB"
    echo "   - Configuration > Security"
    echo "   - Añade un key pair"
    echo ""
    echo "2. Conéctate a la instancia:"
    echo "   ssh -i tu-key.pem ec2-user@INSTANCIA_IP"
    echo ""
    echo "3. Ejecuta stress test:"
    echo "   sudo yum install -y stress"
    echo "   stress --cpu 8 --timeout 600s"
    echo ""
    
    print_info "Alternativamente, genera mucha carga en la aplicación"
}

# ============================================================================
# Prueba 4: Ver Estado Actual de Alarmas
# ============================================================================
check_alarms_status() {
    print_info "Consultando estado actual de las alarmas..."
    
    APP_NAME=$(terraform output -raw alarm_name_prefix 2>/dev/null || terraform output -json | jq -r '.alarms_created.value.high_cpu' | cut -d'-' -f1-2)
    echo ""
    print_info "Estado de las alarmas:"
    
    aws cloudwatch describe-alarms \
        --alarm-name-prefix "$APP_NAME" \
        --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' \
        --output table
    
    echo ""
    print_info "Para ver detalles de una alarma específica:"
    echo "aws cloudwatch describe-alarms --alarm-names NOMBRE_ALARMA"
}

# ============================================================================
# Prueba 5: Generar Errores en Logs
# ============================================================================
test_log_errors() {
    print_info "Para probar la alarma de errores en logs..."
    
    echo ""
    echo "Modifica temporalmente tu código para que loguee errores:"
    echo ""
    echo "// En server.js"
    echo "setInterval(() => {"
    echo "  console.error('[ERROR] Test error for CloudWatch alarm');"
    echo "}, 5000);"
    echo ""
    
    print_warning "No olvides revertir este cambio después de la prueba"
}

# ============================================================================
# Menú Principal
# ============================================================================
show_menu() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║  🔔 Herramienta de Prueba de Alarmas      ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    echo "Selecciona el tipo de prueba:"
    echo ""
    echo "  1) Errores 5xx"
    echo "  2) Alta Latencia"
    echo "  3) Alto Uso de CPU (requiere SSH)"
    echo "  4) Errores en Logs"
    echo "  5) Ver estado actual de alarmas"
    echo "  6) Ejecutar todas las pruebas automatizadas"
    echo "  7) Salir"
    echo ""
    read -p "Opción [1-7]: " option
    
    case $option in
        1) test_5xx_errors ;;
        2) test_latency ;;
        3) test_cpu ;;
        4) test_log_errors ;;
        5) check_alarms_status ;;
        6) 
            test_5xx_errors
            echo ""
            test_latency
            ;;
        7) 
            print_success "¡Hasta luego!"
            exit 0 
            ;;
        *)
            print_error "Opción inválida"
            show_menu
            ;;
    esac
    
    echo ""
    read -p "Presiona Enter para volver al menú..."
    show_menu
}

# ============================================================================
# Crear archivo de formato para curl
# ============================================================================
create_curl_format() {
    cat > curl-format.txt << 'EOF'
time_namelookup:  %{time_namelookup}\n
time_connect:  %{time_connect}\n
time_appconnect:  %{time_appconnect}\n
time_pretransfer:  %{time_pretransfer}\n
time_redirect:  %{time_redirect}\n
time_starttransfer:  %{time_starttransfer}\n
----------\n
time_total:  %{time_total}\n
EOF
}

# ============================================================================
# Función Principal
# ============================================================================
main() {
    clear
    
    print_info "Verificando prerequisitos..."
    
    # Verificar que terraform esté instalado
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform no está instalado"
        exit 1
    fi
    
    # Verificar que AWS CLI esté instalado
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI no está instalado"
        exit 1
    fi
    
    # Verificar que curl esté instalado
    if ! command -v curl &> /dev/null; then
        print_error "curl no está instalado"
        exit 1
    fi
    
    create_curl_format
    
    print_success "Todos los prerequisitos están listos"
    
    # Si se pasó un argumento, ejecutar prueba específica
    if [ $# -eq 1 ]; then
        case $1 in
            5xx) test_5xx_errors ;;
            latency) test_latency ;;
            cpu) test_cpu ;;
            logs) test_log_errors ;;
            status) check_alarms_status ;;
            all)
                test_5xx_errors
                echo ""
                test_latency
                ;;
            *)
                print_error "Tipo de prueba desconocido: $1"
                echo "Tipos válidos: 5xx, latency, cpu, logs, status, all"
                exit 1
                ;;
        esac
    else
        show_menu
    fi
    
    # Limpiar archivo temporal
    rm -f curl-format.txt
}

# Ejecutar
main "$@"
