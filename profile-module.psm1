
function Split-String{
	param(
		[parameter(ValueFromPipeline)] [string]$String,
		[parameter(position=0)] [string]$SplitOn = "\r?\n",
        [switch]$NoRegex
    )

    if ($noregex){
        $spliton = [regex]::escape($spliton)
    }
    $string -split $splitOn
}

function trim{
	param(
		[parameter(position=0,mandatory=$true,ValueFromPipeline=$true)] $String,
		[switch] $RemoveEmptyLines
    )

    begin{
    }
    process{
        if ($string -and $string -is [string]){
            $string.trim()
        }else{
            if (-not $removeemptylines){
                ""
            }
        }
    }
    end{
    }
}

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

#function set-clipboard{
#    param(
#       [parameter(position=0,mandatory=$true,ValueFromPipeline=$true)]$Text,
#       [switch]$NoTrim
#    )
#    begin{
#        $data = [system.text.stringbuilder]::new()
#    }
#
#    process{
#        if ($text){
#            [void]$data.appendline($text)
#        }
#    }
#
#    end{
#        if ($data){
#            
#            if ($notrim){
#                $toclip = ($data.tostring() -replace "$([environment]::newline)$") + [convert]::tochar(0) 
#            }else{
#                $toclip = $data.tostring().trimend([environment]::newline) + [convert]::tochar(0)
#            }
#            #default of utf8 is putting byte order mark in clipboard. this is a hack to avoid that
#            $savencoding = $outputencoding
#            try{
#                $outputencoding = [System.Text.Encoding]::GetEncoding('iso-8859-1')
#                $toclip | clip.exe
#            }finally{
#                $outputencoding = $savencoding
#            }
#        }
#    }
#}

function amp{
    param(
        [parameter(valuefrompipeline)]$file
    )

    process{
        $file = convert-path $file
        & $file
    }
}


function set-queryhubprofile{
    $queryhubparams = get-queryhubparams
    $queryhubparams.timeoutMinutes = 0 #forever
    $queryhubparams.oraclescriptdirectory = 'onedrive:\scripts\sql-scripts\oracle'
    $queryhubparams.sqlserverscriptdirectory = 'onedrive:\scripts\sql-scripts\sqlserver'
    $queryhubparams.texteditorcommand = 'NZ\start-vim'
    $queryhubparams.OracleTnsNamesCommand = "NZ\get-oracleconnectioninfo"
    $queryhubparams.OracleSessionDateFormat = "yyyy-mm-dd hh24:mi:ss"
    $queryhubparams.Sqlclpath = 'onedrive:\tools\sqlcl\bin\sql.exe'
    $queryhubparams | set-queryhubparams
}


function fls{
    [CmdletBinding()] 
    param( 
       [parameter(position=0,mandatory=$false,ValueFromPipeline=$true)] $x
    )
    begin{}
    process{
        $x | select-object ([string[]]($x | get-member -membertype property,noteproperty | %{$_.name}| sort-object))
    }
    end{}
}

function replace{
    [CmdletBinding()] 
    param( 
       [parameter(mandatory=$true,ValueFromPipeline=$true)] $Text,
       [parameter(position=1,mandatory=$true,ValueFromPipeline=$false)] [string]$Find,
       [parameter(position=2,ValueFromPipeline=$false)] [string]$ReplaceWith = $null
    )
    begin{}
    process{
        $text -replace $find,$replacewith
    }
    end{}
}

function Update-Pwsh{
    if ($psversiontable.platform -match '^win'){
        Invoke-Expression "& { $(Invoke-Restmethod https://aka.ms/install-powershell.ps1) } -UseMSI -Preview"
    }else{
        write-host 'not implemented'
    }
}
