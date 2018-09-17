'Public','Private' | ForEach-Object {

    If (Test-Path "$PSScriptRoot\$_\"){

        #Load functions
        @( Get-ChildItem -Path "$PSScriptRoot\$_\*.ps1" ) | ForEach-Object {
            . $_.FullName
        }
    }

}