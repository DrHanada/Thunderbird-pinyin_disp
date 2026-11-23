# Build wrapper. Run from the repository root with Node.js and npm installed.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Push-Location $root
try {
  npm install
  if ($LASTEXITCODE -ne 0) {
    throw "npm install failed with exit code $LASTEXITCODE"
  }
  npm run build
  if ($LASTEXITCODE -ne 0) {
    throw "npm run build failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}
