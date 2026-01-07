
$PSDefaultParameterValues.("Format-Table:Autosize") = $true
$PSDefaultParameterValues.("Format-Table:Property") = "*"

#new-pssession servername -Credential $cred | t servername | Set-RemoteProfile | Enter-PSSession


#function prompt {
#
#    Write-Host (get-date).tostring("HH:mm:ss ") -nonewline -foregroundcolor darkgray
#    $string = "$($env:USERNAME)@$($env:COMPUTERNAME)".tolower()
#    $colors = [enum]::getvalues([consolecolor]) | where {$_ -ne [console]::BackgroundColor}
#
#    foreach($character in $string.tochararray()){
#        $colorIndex = get-random -minimum 0 -maximum ($colors.count - 1)
#        Write-Host $character -nonewline -foregroundcolor $colors[$colorindex]
#    }
#
#	Write-Host "" -nonewline
#	Write-Host ("$((get-location).path)") -nonewline -foregroundcolor White
#
#
#    if ($psversiontable.platform -eq 'unix'){
#        $id = id
#        if ($id -match '\(sudo\)'){
#            Write-Host '#' -nonewline -foregroundcolor $theColor
#        }else{
#            Write-Host '$' -nonewline -foregroundcolor $theColor
#        }
#    }else{
#        if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
#            Write-Host '#' -nonewline -foregroundcolor $theColor
#        }else{
#            Write-Host '$' -nonewline -foregroundcolor $theColor
#        }
#    }
#    write-output " "
#}


$cmdletAliases = @{
    cat = 'get-content'
    grep = 'select-string'
    ls = 'get-childitem'
    ps = 'get-process'
    rm = 'remove-item'
    rmdir = 'remove-item'
    sort = 'sort-object'
}

foreach ($key in $cmdletaliases.keys){
    if (test-path "alias:$key"){
        remove-item "alias:$key" -confirm:$false -force
    }
    new-alias -name $key -value $cmdletAliases[$key] -confirm:$false
}

new-alias -name s -value select-object

function lsod{
    param(
        [argumentcompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            get-psdrive -psprovider filesystem | select -expand name |% {"$($_):\"}| where-object {$_ -ilike "$wordToComplete*"}
        })]
        [parameter(position=0)][string]$Filter = "*",
        [parameter(position=1)][int]$Last = 1,
        [parameter(position=2)][int]$Skip = 0
    )

    begin{
    }
    process{
        ls $filter | sort lastwritetime | select -last $last -skip $skip
    }
    end{
    }
}
function od{
    param(
        [parameter(valuefrompipeline)][io.filesysteminfo]$Value,
        [parameter(position=0)][int]$Last
    )

    begin{
        $values=@()
    }
    process{
        $values += $value
    }
    end{
        $result = $values | sort-object lastwritetime 
        if ($last){
            $result = $result | select-object -last $last
        }
        $result
    }
}


if (-not ("system.io.compression" -as [type])) {
    add-type -assemblyname system.io.compression
}

if (-not ("system.io.compression.filesystem" -as [type])) {
    add-type -assemblyname system.io.compression.filesystem
}


function zcat{

    Param(
        [parameter(valuefrompipeline)]$ZippedFile,
        [validateset('Zip','GZip')]$CompressionType = 'Zip',
        [switch]$InferObjectTypeFromFileExtension,
        [switch]$AsHashTable,
        [switch]$Raw,
        [switch]$ListingOnly
    )


    if (-not (test-path $zippedfile -pathtype leaf)){
        write-output "$zippedfile not found"
        return
    }

    $zippedfile = (convert-path $zippedfile)

    if ($compressiontype -eq 'zip'){

        try{

            $zipfile = [System.IO.Compression.zipfile]::open($zippedfile,[system.io.compression.ziparchivemode]::read)
            $hashtable = @{}

            foreach ($entry in $zipfile.entries){
                $text = $null
                $result = [pscustomobject]@{
                    Name = $entry.fullname
                    Contents = $null
                }
                if ($listingonly){
                    $result
                }else{
                    try{
                        $stream = $entry.open()
                        $reader = [system.io.streamreader]::new($stream)
                        $text = $reader.readtoend()

                        if ($inferobjecttypefromfileextension){
                            if ($entry.name -match '\.xml$'){
                                $contents = [xml]$text
                            }elseif ($entry.name -match '\.csv$'){
                                $contents = $text | convertfrom-csv
                            }else{
                                if ($raw){
                                    $contents = $text
                                }else{
                                    $contents = $text -split "`r?`n"
                                }
                            }
                        }else{
                            if ($raw){
                                $contents = $text
                            }else{
                                $contents = $text -split "`r?`n"
                            }
                        }

                        $result.contents = $contents

                        if ($ashashtable){
                            $hashtable.add($result.name,$result.contents)
                        }else{
                            $result
                        }
                    }finally{
                        if ($reader){
                            $reader.close()
                        }
                        if ($stream){
                            $stream.close()
                        }
                    }
                }

            }
            
            if ($ashashtable){
                $hashtable
            }
        }finally{
            if ($zipfile){
                $zipfile.dispose()
            }
        }
    }elseif ($compressiontype -eq 'gzip'){
        try{
            $stream = [system.io.filestream]::new($zippedfile,[system.io.filemode]::open)
            $data = [System.IO.Compression.GZipStream]::new($stream,[system.io.compression.compressionmode]::decompress)
            $reader = [system.io.streamreader]::new($data)

            $text = $reader.readtoend()

            if ($raw){
                $contents = $text
            }else{
                $contents = $text -split "`r?`n"
            }
            $contents
        }finally{
            if ($reader){
                $reader.close()
            }
            if ($data){
                $data.close()
            }
            if ($stream){
                $stream.close()
            }
        }
    }
}

function t {
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true, position=0)]
        [string[]]$Name,

        [parameter(position=1, valuefrompipeline)]
        [System.Object]$Value,

        [switch]$NoOutput
    )

    begin {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
            $PSBoundParameters['OutBuffer'] = 1
        }

        #don't prompt for confirmation - personal preference
        $PSBoundParameters['Confirm'] = $false

        #lift up to calling scope
        $PSBoundParameters['Scope'] = 1

        Remove-Variable -name $name -scope $psboundparameters['Scope'] -erroraction silentlycontinue -confirm:$false

        $outNoOutput = $null
        if ($PSBoundParameters.TryGetValue('NoOutput', [ref]$outBuffer)) {
            $null = $PSBoundParameters.remove('NoOutput')
        }


        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Set-Variable', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process {
        $steppablePipeline.Process($_)
    }

    end {
        $steppablePipeline.End()
        if (-not $nooutput){
            Get-Variable -name $name -scope $psboundparameters['Scope']| Select-Object -Expand Value
        }
    }

#support introduced in 7.3
#
#    clean {
#        if ($null -ne $steppablePipeline) {
#            $steppablePipeline.Clean()
#        }
#    }
}


#function get-lastboottime{
#    Get-CimInstance -ClassName Win32_OperatingSystem | Select LastBootUpTime
#}
