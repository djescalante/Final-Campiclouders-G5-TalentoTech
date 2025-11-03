# ============================================================================
# Script para Probar Alarmas de CloudWatch (Versión PowerShell)
# ============================================================================
# Este script te ayuda a probar que las alarmas funcionan correctamente
# generando diferentes tipos de eventos que deberían activarlas.
#
# Uso: .\test_alarms.ps1 [tipo_prueba]
# Tipos de prueba: 5xx, latency, cpu, all
# ============================================================================

# --- Funciones de Utilidad para Imprimir con Color ---
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# --- Obtener la URL del ambiente desde Terraform ---
Write-Info "Obteniendo URL del ambiente..."
try {
    $global:EB_URL = terraform output -raw eb_environment_cname
    if (-not $global:EB_URL) { throw }
    Write-Success "URL del ambiente: https://$($global:EB_URL)"
}
catch {
    Write-Error "No se pudo obtener la URL del ambiente. ¿Ejecutaste 'terraform apply'?"
    exit 1
}

# ============================================================================
# Prueba 1: Generar Errores 5xx
# ============================================================================
function Test-5xxErrors {
    Write-Info "Iniciando prueba de errores 5xx..."
    Write-Warning "Esta prueba intentará generar errores 5xx"
    
    Write-Host ""
    Write-Host "Para activar la alarma de 5xx, necesitas:"
    Write-Host "1. Introducir un bug en tu código que cause errores 500"
    Write-Host "2. O sobrecargar la aplicación con muchas peticiones"
    Write-Host ""
    
    Write-Info "Enviando 50 peticiones a un endpoint inexistente..."
    
    $jobs = 1..50 | ForEach-Object {
        $i = $_
        Start-Job -ScriptBlock {
            param($url, $i)
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing
                return "$i -> $($response.StatusCode)"
            }
            catch {
                return "$i -> $($_.Exception.Response.StatusCode.Value__)"
            }
        } -ArgumentList "https://$($global:EB_URL)/endpoint-que-no-existe", $i

        if (($i % 10) -eq 0) {
            Write-Info "Iniciadas $i peticiones..."
        }
    }
    
    $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    Write-Success "Prueba completada. Revisa CloudWatch en 5-10 minutos"
    Write-Info "Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards"
}

# ============================================================================
# Prueba 2: Generar Alta Latencia
# ============================================================================
function Test-Latency {
    Write-Info "Iniciando prueba de latencia..."
    
    Write-Host ""
    Write-Host "Para probar latencia alta, puedes:"
    Write-Host "1. Añadir un delay artificial en tu código"
    Write-Host "2. Realizar consultas pesadas a DynamoDB"
    Write-Host "3. Enviar muchas peticiones concurrentes"
    Write-Host ""
    
    Write-Info "Enviando 100 peticiones concurrentes..."
    
    $jobs = 1..100 | ForEach-Object {
        $i = $_
        Start-Job -ScriptBlock {
            param($url, $i)
            $medida = Measure-Command { Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction SilentlyContinue }
            return "Petición $i completada en $($medida.TotalSeconds) segundos"
        } -ArgumentList "https://$($global:EB_URL)/", $i

        if (($i % 20) -eq 0) {
            Write-Info "Iniciadas $i peticiones..."
        }
    }
    
    $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    Write-Success "Prueba completada. Revisa las métricas de latencia en CloudWatch"
}

# ============================================================================
# Prueba 3: Simular Alto Uso de CPU
# ============================================================================
function Test-Cpu {
    Write-Info "Iniciando prueba de CPU..."
    
    Write-Host ""
    Write-Warning "Para probar la alarma de CPU, necesitas acceso SSH a la instancia EC2"
    Write-Host ""
    Write-Host "Pasos para conectarte:"
    Write-Host "1. Habilita SSH en Elastic Beanstalk:"
    Write-Host "   - Ve a la consola de EB"
    Write-Host "   - Configuration > Security"
    Write-Host "   - Añade un key pair"
    Write-Host ""
    Write-Host "2. Conéctate a la instancia:"
    Write-Host "   ssh -i tu-key.pem ec2-user@INSTANCIA_IP"
    Write-Host ""
    Write-Host "3. Ejecuta stress test:"
    Write-Host "   sudo yum install -y stress"
    Write-Host "   stress --cpu 8 --timeout 600s"
    Write-Host ""
    
    Write-Info "Alternativamente, genera mucha carga en la aplicación"
}

# ============================================================================
# Prueba 4: Ver Estado Actual de Alarmas
# ============================================================================
function Check-AlarmsStatus {
    Write-Info "Consultando estado actual de las alarmas..."
    
    try {
        $appName = (terraform output -json | ConvertFrom-Json).alarms_created.value.high_cpu.Split('-')[0..1] -join '-'
    } catch {
        Write-Error "No se pudo obtener el nombre de la aplicación desde Terraform. ¿El output 'alarms_created' existe?"
        return
    }
    
    Write-Host ""
    Write-Info "Estado de las alarmas:"
    
    aws cloudwatch describe-alarms `
        --alarm-name-prefix "$appName" `
        --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' `
        --output table
    
    Write-Host ""
    Write-Info "Para ver detalles de una alarma específica:"
    Write-Host "aws cloudwatch describe-alarms --alarm-names NOMBRE_ALARMA"
}

# ============================================================================
# Prueba 5: Generar Errores en Logs
# =_==========================================================================
function Test-LogErrors {
    Write-Info "Para probar la alarma de errores en logs..."
    
    Write-Host ""
    Write-Host "Modifica temporalmente tu código para que loguee errores:"
    Write-Host ""
    Write-Host "// En server.js"
    Write-Host "setInterval(() => {"
    Write-Host "  console.error('[ERROR] Test error for CloudWatch alarm');"
    Write-Host "}, 5000);"
    Write-Host ""
    
    Write-Warning "No olvides revertir este cambio después de la prueba"
}

# ============================================================================
# Menú Principal
# ============================================================================
function Show-Menu {
    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║  🔔 Herramienta de Prueba de Alarmas      ║" -ForegroundColor Yellow
        Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Selecciona el tipo de prueba:"
        Write-Host ""
        Write-Host "  1) Errores 5xx"
        Write-Host "  2) Alta Latencia"
        Write-Host "  3) Alto Uso de CPU (requiere SSH)"
        Write-Host "  4) Errores en Logs"
        Write-Host "  5) Ver estado actual de alarmas"
        Write-Host "  6) Ejecutar todas las pruebas automatizadas"
        Write-Host "  7) Salir"
        Write-Host ""
        
        $option = Read-Host "Opción [1-7]"
        
        switch ($option) {
            "1" { Test-5xxErrors }
            "2" { Test-Latency }
            "3" { Test-Cpu }
            "4" { Test-LogErrors }
            "5" { Check-AlarmsStatus }
            "6" {
                Test-5xxErrors
                Write-Host ""
                Test-Latency
            }
            "7" {
                Write-Success "¡Hasta luego!"
                return
            }
            default {
                Write-Error "Opción inválida"
            }
        }
        
        Write-Host ""
        Read-Host "Presiona Enter para volver al menú..."
    }
}

# ============================================================================
# Función Principal
# ============================================================================
function Main {
    param($prueba)

    Clear-Host
    Write-Info "Verificando prerequisitos..."
    
    # Verificar que las herramientas estén instaladas
    $tools = @("terraform", "aws", "curl")
    foreach ($tool in $tools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Error "$tool no está instalado o no se encuentra en el PATH."
            exit 1
        }
    }
    
    Write-Success "Todos los prerequisitos están listos"
    
    # Si se pasó un argumento, ejecutar prueba específica
    if ($prueba) {
        switch ($prueba.ToLower()) {
            "5xx"     { Test-5xxErrors }
            "latency" { Test-Latency }
            "cpu"     { Test-Cpu }
            "logs"    { Test-LogErrors }
            "status"  { Check-AlarmsStatus }
            "all"     {
                Test-5xxErrors
                Write-Host ""
                Test-Latency
            }
            default {
                Write-Error "Tipo de prueba desconocido: $prueba"
                Write-Host "Tipos válidos: 5xx, latency, cpu, logs, status, all"
                exit 1
            }
        }
    }
    else {
        Show-Menu
    }
}

# Ejecutar
Main $args[0]
