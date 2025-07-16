param (
    [int]$Port = 5175
)

# Obtenir l'IP de WSL
$wslIp = wsl hostname -I | ForEach-Object { ($_ -split '\s+')[0] }

if (-not $wslIp) {
    Write-Host "❌ Impossible de récupérer l'IP de WSL." -ForegroundColor Red
    exit 1
}

# Vérifie si une règle existe déjà
$existingRule = netsh interface portproxy show v4tov4 | Select-String "0.0.0.0:$Port"

if ($existingRule) {
    Write-Host "ℹ️ Une règle de portproxy existe déjà pour le port $Port. Suppression..."
    netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=0.0.0.0
}

# Ajouter la nouvelle règle
netsh interface portproxy add v4tov4 listenport=$Port listenaddress=0.0.0.0 connectport=$Port connectaddress=$wslIp

# Ajouter une règle firewall si elle n'existe pas
$ruleName = "WSL Proxy $Port"
$firewallRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if (-not $firewallRule) {
    Write-Host "🛡️ Ajout de la règle firewall '$ruleName'..."
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow
} else {
    Write-Host "🛡️ La règle firewall existe déjà."
}

Write-Host "✅ Port $Port exposé depuis Windows (accessible via http://<IP-Windows>:$Port)" -ForegroundColor Green
