function Get-Version() {
    return '0.0.1'
}
function Get-NextVersion() {
    return '0.0.2'
}

function Build ($version) {
    Write-Host "A build was run for version: $version"
}
  
function BuildIfChanged {
    $thisVersion = Get-Version
    $nextVersion = Get-NextVersion
    if ($thisVersion -ne $nextVersion) { 
        Build $nextVersion 
    }
    return $nextVersion
}
