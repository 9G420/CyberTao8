param(
    [string]$ListenPrefix = "http://127.0.0.1:8765/"
)

$RepoRoot = $PSScriptRoot
$SignalDir = Join-Path $RepoRoot "CyberTao_Dice_Beast_Protocol\Signals"
$SignalFile = Join-Path $SignalDir "done_signal.json"

function Write-JsonFile {
    param(
        [hashtable]$Data,
        [string]$Path
    )

    $json = $Data | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.Encoding]::UTF8)
}

if (-not (Test-Path -LiteralPath $SignalDir)) {
    New-Item -ItemType Directory -Path $SignalDir -Force | Out-Null
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($ListenPrefix)

try {
    $listener.Start()
    Write-Host "Mulerun listener started at $ListenPrefix"
    Write-Host "Signal file: $SignalFile"
    Write-Host "Press Ctrl+C to stop."

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "POST, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
            $response.ContentType = "application/json; charset=utf-8"

            if ($request.HttpMethod -eq "OPTIONS") {
                $response.StatusCode = 200
                $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true,"preflight":true}')
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            elseif ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/notify") {
                $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
                $body = $reader.ReadToEnd()
                $reader.Close()

                if ([string]::IsNullOrWhiteSpace($body)) {
                    throw "Empty request body."
                }

                $data = $body | ConvertFrom-Json

                $payload = @{
                    source      = [string]$data.source
                    status      = [string]$data.status
                    message     = [string]$data.message
                    detected_at = [string]$data.detected_at
                    url         = [string]$data.url
                    title       = [string]$data.title
                    saved_at    = (Get-Date).ToString("o")
                }

                Write-JsonFile -Data $payload -Path $SignalFile

                $logPath = Join-Path $SignalDir "done_signal.log"
                $logLine = "[{0}] {1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $payload.message
                [System.IO.File]::AppendAllText($logPath, $logLine + [Environment]::NewLine, [System.Text.Encoding]::UTF8)

                Write-Host ("Received completion signal: " + $payload.message)

                $response.StatusCode = 200
                $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}')
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            else {
                $response.StatusCode = 404
                $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"ok":false,"error":"not found"}')
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        catch {
            $response.StatusCode = 500
            $msg = '{"ok":false,"error":"' + ($_.Exception.Message.Replace('"','\"')) + '"}'
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            Write-Warning $_.Exception.Message
        }
        finally {
            $response.OutputStream.Close()
        }
    }
}
finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
}
