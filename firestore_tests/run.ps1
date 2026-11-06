# Prueba firestore.rules en un emulador local. El proyecto "demo-" no puede tocar datos reales.
# Uso, desde la carpeta Asistly:  powershell -ExecutionPolicy Bypass -File firestore_tests\run.ps1

# El emulador necesita Java 21: se usa el que trae Android Studio.
$studioJava = 'C:\Program Files\Android\Android Studio\jbr'
if (Test-Path $studioJava) {
  $env:JAVA_HOME = $studioJava
  $env:Path = "$studioJava\bin;$env:Path"
}

Set-Location $PSScriptRoot
if (-not (Test-Path 'node_modules')) { npm.cmd install --no-audit --no-fund }
firebase.cmd emulators:exec --only firestore --project demo-asistly "node rules.test.js"
Write-Host "FIN-DE-PRUEBA"
