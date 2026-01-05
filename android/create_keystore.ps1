# PowerShell script to create Android keystore for release signing
# Run this script from the android directory

Write-Host "Creating Android Keystore for Release Signing..." -ForegroundColor Green
Write-Host ""

# Prompt for keystore details
$keystoreName = Read-Host "Enter keystore name (default: upload-keystore.jks)"
if ([string]::IsNullOrWhiteSpace($keystoreName)) {
    $keystoreName = "upload-keystore.jks"
}

$keyAlias = Read-Host "Enter key alias (default: upload)"
if ([string]::IsNullOrWhiteSpace($keyAlias)) {
    $keyAlias = "upload"
}

$validityYears = Read-Host "Enter validity in years (default: 25)"
if ([string]::IsNullOrWhiteSpace($validityYears)) {
    $validityYears = "25"
}

Write-Host ""
Write-Host "You will be prompted to enter passwords. Please remember them!" -ForegroundColor Yellow
Write-Host "Store password: Used to protect the keystore file" -ForegroundColor Yellow
Write-Host "Key password: Used to protect the key (can be same as store password)" -ForegroundColor Yellow
Write-Host ""

# Create keystore using keytool
$keytoolPath = "$env:JAVA_HOME\bin\keytool.exe"
if (-not (Test-Path $keytoolPath)) {
    # Try to find keytool in common locations
    $possiblePaths = @(
        "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
        "$env:ProgramFiles\Android\Android Studio\jre\bin\keytool.exe",
        "$env:LOCALAPPDATA\Android\Sdk\jbr\bin\keytool.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $keytoolPath = $path
            break
        }
    }
}

if (-not (Test-Path $keytoolPath)) {
    Write-Host "Error: keytool not found. Please ensure Java JDK is installed." -ForegroundColor Red
    Write-Host "You can also create the keystore manually using:" -ForegroundColor Yellow
    Write-Host "keytool -genkey -v -keystore $keystoreName -alias $keyAlias -keyalg RSA -keysize 2048 -validity $($validityYears * 365)" -ForegroundColor Cyan
    exit 1
}

Write-Host "Creating keystore: $keystoreName" -ForegroundColor Green
& $keytoolPath -genkey -v -keystore $keystoreName -alias $keyAlias -keyalg RSA -keysize 2048 -validity $($validityYears * 365)

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Keystore created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Create key.properties file in the android directory with:" -ForegroundColor Cyan
    Write-Host "   storePassword=YOUR_STORE_PASSWORD"
    Write-Host "   keyPassword=YOUR_KEY_PASSWORD"
    Write-Host "   keyAlias=$keyAlias"
    Write-Host "   storeFile=$keystoreName"
    Write-Host ""
    Write-Host "2. Build your release APK/AAB using:" -ForegroundColor Cyan
    Write-Host "   flutter build apk --release"
    Write-Host "   or"
    Write-Host "   flutter build appbundle --release"
} else {
    Write-Host "Error creating keystore. Please try again." -ForegroundColor Red
}

