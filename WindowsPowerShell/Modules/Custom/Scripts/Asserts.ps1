filter Assert-FolderExists {
    $exists = Test-Path -Path $_ -PathType Container
    if (!$exists) { 
        Write-Error "$_ does not exist."
        # Write-Warning "$_ did not exist. Folder created."
        # $null = New-Item -Path $_ -ItemType Directory 
    }
}
#Export-ModuleMember -Function Assert-FolderExists

filter Assert-FileExists {
    $exists = Test-Path -Path $_ -PathType Leaf
    if (!$exists) { 
        Write-Error "$_ does not exist."
    }
}
Export-ModuleMember -Function Assert-FileExists

filter Assert-NotNull {
    if ($_ -eq $null) {
        Write-Error "Variable is null."
    }
}
Export-ModuleMember -Function Assert-NotNull
