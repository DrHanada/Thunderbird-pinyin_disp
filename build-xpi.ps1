$ErrorActionPreference = "Stop"

# Build from the directory containing this script, independent of the shell's cwd.
$root = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($root)) {
  $root = (Get-Location).Path
}

Add-Type -AssemblyName System.IO.Compression

$manifestPath = Join-Path $root "manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
  throw "manifest.json was not found. Run this script from the add-on folder."
}

try {
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
}
catch {
  throw "manifest.json is not valid JSON. Save it as UTF-8 and check its syntax. $($_.Exception.Message)"
}

$version = [string]$manifest.version
if ([string]::IsNullOrWhiteSpace($version)) {
  throw "The version field is missing from manifest.json."
}
if (@($manifest.permissions) -notcontains "messagesModify") {
  throw 'manifest.json must include the "messagesModify" permission for Thunderbird.'
}
if ($null -eq $manifest.browser_specific_settings.gecko.data_collection_permissions -or
    @($manifest.browser_specific_settings.gecko.data_collection_permissions.required) -notcontains "none") {
  throw 'Declare data_collection_permissions.required as ["none"] if the add-on does not collect data.'
}

# Download the pinned browser build and upstream license notices when absent.
$vendorPath = Join-Path $root "vendor"
if (-not (Test-Path -LiteralPath $vendorPath -PathType Container)) {
  New-Item -ItemType Directory -Path $vendorPath -Force | Out-Null
}

$downloads = @(
  @{
    Path = Join-Path $vendorPath "pinyin-pro.js"
    Url = "https://cdn.jsdelivr.net/npm/pinyin-pro@3.29.5/dist/index.js"
  },
  @{
    Path = Join-Path $vendorPath "PINYIN-PRO-LICENSE.txt"
    Url = "https://raw.githubusercontent.com/zh-lx/pinyin-pro/0785234b4dc0fa3ea9f244e3d77703b2df6a9db4/LICENSE"
  },
  @{
    Path = Join-Path $vendorPath "PINYIN-PRO-DATA-LICENSE.txt"
    Url = "https://raw.githubusercontent.com/zh-lx/pinyin-pro/0785234b4dc0fa3ea9f244e3d77703b2df6a9db4/packages/data/LICENSE"
  }
)

# Windows PowerShell may otherwise use an older TLS default.
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}
catch {
  # Continue with the platform default if the TLS setting is unavailable.
}

foreach ($download in $downloads) {
  if (-not (Test-Path -LiteralPath $download.Path -PathType Leaf)) {
    Write-Host "Downloading $([System.IO.Path]::GetFileName($download.Path))"
    Invoke-WebRequest -Uri $download.Url -OutFile $download.Path -UseBasicParsing
  }
}

$relativePaths = @(
  "manifest.json",
  "background.js",
  "content.js",
  "LICENSE"
)

$vendorFiles = @(Get-ChildItem -LiteralPath $vendorPath -File -Recurse)
foreach ($file in $vendorFiles) {
  $relativePaths += $file.FullName.Substring($root.Length + 1)
}

# Include icon files only when declared in the manifest.
if ($null -ne $manifest.icons) {
  foreach ($icon in $manifest.icons.PSObject.Properties) {
    $iconPath = [string]$icon.Value
    if ([string]::IsNullOrWhiteSpace($iconPath)) {
      throw "An icon path in manifest.json is empty."
    }
    $filesystemIconPath = $iconPath.Replace("/", [string][char]92)
    if ([System.IO.Path]::IsPathRooted($filesystemIconPath) -or
        $filesystemIconPath -match '(^|\\)\.\.(\\|$)') {
      throw "Icon paths must be relative paths inside the add-on."
    }
    $fullIconPath = Join-Path $root $filesystemIconPath
    if (-not (Test-Path -LiteralPath $fullIconPath -PathType Leaf)) {
      throw "An icon referenced in manifest.json was not found: $iconPath"
    }
    $relativePaths += $filesystemIconPath
  }
}

foreach ($relative in $relativePaths) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) {
    throw "Required package file not found: $relative"
  }
}

$outputPath = Join-Path $root "thunderbird-pinyin-display-$version.xpi"
if (Test-Path -LiteralPath $outputPath) {
  Remove-Item -LiteralPath $outputPath -Force
}

$fileStream = $null
$archive = $null
$buildSucceeded = $false
$addedEntries = @{}
$backslash = [string][char]92

try {
  $fileStream = [System.IO.File]::Open(
    $outputPath,
    [System.IO.FileMode]::CreateNew,
    [System.IO.FileAccess]::ReadWrite,
    [System.IO.FileShare]::None
  )
  $archive = [System.IO.Compression.ZipArchive]::new(
    $fileStream,
    [System.IO.Compression.ZipArchiveMode]::Create
  )

  foreach ($relative in $relativePaths) {
    $entryName = $relative.Replace($backslash, "/")
    if ($addedEntries.ContainsKey($entryName)) {
      continue
    }
    $addedEntries[$entryName] = $true

    $entry = $archive.CreateEntry(
      $entryName,
      [System.IO.Compression.CompressionLevel]::Optimal
    )
    $sourceStream = [System.IO.File]::OpenRead((Join-Path $root $relative))
    $destinationStream = $entry.Open()
    try {
      $sourceStream.CopyTo($destinationStream)
    }
    finally {
      $destinationStream.Dispose()
      $sourceStream.Dispose()
    }
  }
  $buildSucceeded = $true
}
finally {
  if ($null -ne $archive) {
    $archive.Dispose()
  }
  elseif ($null -ne $fileStream) {
    $fileStream.Dispose()
  }
  if (-not $buildSucceeded -and (Test-Path -LiteralPath $outputPath)) {
    Remove-Item -LiteralPath $outputPath -Force
  }
}

# Validate using ZipArchive, not ZipFile, for Windows PowerShell compatibility.
$checkStream = $null
$checkArchive = $null
try {
  $checkStream = [System.IO.File]::Open(
    $outputPath,
    [System.IO.FileMode]::Open,
    [System.IO.FileAccess]::Read,
    [System.IO.FileShare]::Read
  )
  $checkArchive = [System.IO.Compression.ZipArchive]::new(
    $checkStream,
    [System.IO.Compression.ZipArchiveMode]::Read
  )
  $entryNames = @($checkArchive.Entries | ForEach-Object { $_.FullName })

  foreach ($entryName in $entryNames) {
    if ($entryName.Contains($backslash)) {
      throw "A ZIP entry contains an invalid backslash: $entryName"
    }
  }

  foreach ($requiredEntry in @(
    "manifest.json",
    "background.js",
    "content.js",
    "vendor/pinyin-pro.js",
    "vendor/PINYIN-PRO-LICENSE.txt",
    "vendor/PINYIN-PRO-DATA-LICENSE.txt"
  )) {
    if ($entryNames -notcontains $requiredEntry) {
      throw "Required file is missing from the XPI: $requiredEntry"
    }
  }

  Write-Host "XPI entries:"
  $entryNames | ForEach-Object { Write-Host "  $_" }
}
catch {
  if (Test-Path -LiteralPath $outputPath) {
    Remove-Item -LiteralPath $outputPath -Force
  }
  throw
}
finally {
  if ($null -ne $checkArchive) {
    $checkArchive.Dispose()
  }
  elseif ($null -ne $checkStream) {
    $checkStream.Dispose()
  }
}

Write-Host ""
Write-Host "XPI created and validated: $outputPath"
Write-Host "Version: $version"
