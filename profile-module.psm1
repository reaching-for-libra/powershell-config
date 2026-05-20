$script:keepassCache = $null

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

function Invoke-Trim{
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

function Get-LastFromDirectory{
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

function Invoke-SortLastWriteTime{
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

function Invoke-Execute{
    param(
        [parameter(valuefrompipeline)]
        [psobject]$file
    )

    process{
        if ($file -is [System.IO.FileSystemInfo]){
            $file = $file.fullname
        }
        $file = convert-path $file
        & $file
    }
}


function Set-QueryHubProfile{
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


function Format-ListSorted{
    [CmdletBinding()] 
    param( 
       [parameter(position=0,mandatory=$false,ValueFromPipeline=$true)] $x
    )
    begin{}
    process{
#        $x | select-object ([string[]]($x | get-member -membertype property,noteproperty | %{$_.name}| sort-object))
#        $x | select-object ([string[]]($x | get-member -membertype property,noteproperty | %{$_.name}| sort-object))
        $props = $x.psobject.properties.name | sort-object
        if ($props){
            $x | select-object $props
        }
    }
    end{}
}

function Invoke-ReplaceText{
    [CmdletBinding()] 
    param( 
       [parameter(mandatory=$true,ValueFromPipeline=$true)] $Text,
       [parameter(position=1,mandatory=$true,ValueFromPipeline=$false)] [string]$Find,
       [parameter(position=2,ValueFromPipeline=$false)] [string]$ReplaceWith = $null,
       [switch]$CaseSensitive
    )
    begin{}
    process{
        if ($casesensitive){
            $text -creplace $find,$replacewith
        }else{
            $text -replace $find,$replacewith
        }
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




function Get-BufferHistory{
    [CmdletBinding()] 
    param( 
		[switch] $Full
    )

    begin{}
    process{
        # Check the host name and exit if the host is not the Windows PowerShell console host.
        if ($host.Name -ne 'ConsoleHost') { 
          write-host -ForegroundColor Red "This script runs only in the console host. You cannot run this script in $($host.Name)." 
          exit -1 
        } 

        # Grab the console screen buffer contents using the Host console API. 
        $bufferWidth = $host.ui.rawui.BufferSize.Width 
        $bufferHeight = $host.ui.rawui.CursorPosition.Y 
        $rec = new-object System.Management.Automation.Host.Rectangle 0,0,($bufferWidth - 1),$bufferHeight 
        $buffer = $host.ui.rawui.GetBufferContents($rec) 
        $lines = @()

        # Iterate through the lines in the console buffer. 
        for($i = 0; $i -lt $bufferHeight - 1; $i++) { 
            $textBuilder = new-object system.text.stringbuilder 


            for($j = 0; $j -lt $bufferWidth; $j++) { 
                $cell = $buffer[$i,$j] 
                $null = $textBuilder.Append($cell.Character) 
            } 

            $isPrompt = $textBuilder.ToString().trim() -match '^\d\d:\d\d:\d\d nzeleski@'

            if ($isPrompt -and (-not $full)){
                if ($textBuilder.ToString().trim() -match 'gbh|get-bufferhistory'){
                    $skip = $true
                }else{
                    $skip = $false
                }
            }

            if (-not $skip){
                $lines += $textBuilder.ToString().trim()

                if ($isPrompt){
                    $lastPrompt = $lines.count - 1
                }
            }

        } 

        if ($Full){
            $lines
        }else{
            $lastPrompt .. ($lines.count - 1) | % {$lines[$_]}
        }
    }
    end{}
}

function Format-Xml() { 
    [CmdletBinding()]
	param(
		[parameter(parametersetname='xml',mandatory,ValueFromPipeline)] [xml]$xml,
		[parameter(parametersetname='xmlstring',mandatory,ValueFromPipeline)] [string]$xmlstring,
		[parameter(mandatory=$false,ValueFromPipeline=$false)] $indent = 4,
        [switch]$Raw
	)

	begin {
		$StringWriter = New-Object System.IO.StringWriter 
		$XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
		$xmlWriter.Formatting = "indented" 
		$xmlWriter.Indentation = $indent 
        $rawoutput = [system.text.stringbuilder]::new()
	}

	process {
        if ($xmlstring){
#            if ($xmlstring.trim() -notmatch '^\<\?xml'){
#                $xmlstring = "$('<?xml version="1.0" encoding="UTF-8"?>')$xmlstring)"
#            }
            $xml = [xml]$xmlstring
        }
        $nodes = $xml.SelectNodes("//*[count(@*) = 0 and count(child::*) = 0 and not(string-length(text())) > 0]")
        $nodes | % {$_.isempty=$true}
		$xml.WriteContentTo($XmlWriter) 
		$XmlWriter.Flush() 
		$StringWriter.Flush() 
		$lines =  ((($StringWriter.ToString()) -split '\r\n') -split '\n')
        foreach($line in $lines){
            if ($raw){
                $null = $rawoutput.appendline($line)
            }else{
                write-output $line
            }
        }
	}
	end
	{
        if ($raw){
            $rawoutput.tostring()
        }
	}
}

function Get-OracleConnectionInfo{

    [outputtype('QueryHub.OracleConnectionInfo')]
    param(
        [parameter(position=0,mandatory=$false,ValueFromPipeline=$false)] $TnsNameRegex = "[^\s()]",
        [parameter(position=1,mandatory=$false,ValueFromPipeline=$false)] $TnsFile = "onedrive:/oracle/OracleTns/tnsnames.ora",
        [switch]$NoLowerCase,
        [switch]$ShowTnsNamesFile
    )

    #   IFILE=//racwdc01/creedrives/global/oracletns/tnsnames.ora
    $file = cat $tnsfile | where {$_ -notmatch '^\s*#'} |  grep '(?<=ifile=)(?<link>.*)' | select -expand matches | select -expand value
    if (-not $file){
        write-error "could not determine file to read"
        return
    }
    if ($showtnsnamesfile){
        $file
        return
    }

    if ($psversiontable.platform -eq 'unix'){
        if (-not (test-path $file)){
            $filecontents = read-netshareusinglinuxmount $file /mnt/tmpmount

            if (-not $filecontents){
                write-error "Could not determine file to read"
                return
            }
        }
    }else{
        if (-not (test-path $file)){
            write-error "Could not determine file to read"
            return
        }
        $filecontents = get-content $file
    }


    #get tns strings
    $tnswip = [system.text.stringbuilder]::new()
    $tnsstrings = [system.collections.generic.list[string]]::new()

    foreach($line in $filecontents){

        $thisline = $line.trim() -replace '#.*'
        
        if ($thisline.length -eq 0){
            continue
        }

        if ($tnswip.length -eq 0){
            $new = $true
        }else{
            $new = $false
        }

        $null = $tnswip.append($thisline)

        if (-not $new){
            $open = ($tnswip.tostring() -replace '[^\(]').length
            $closed = ($tnswip.tostring() -replace '[^\)]').length

            if ($open -eq $closed){
                $tnsstrings.add($tnswip.tostring())
                $null = $tnswip.clear()
            }
        }
    }

    foreach ($tnsstring in $tnsstrings){
        $tnsname = $tnsstring | select-string "^[^=\s]+" | select -expand matches | select -expand value
        if ($tnsname -notmatch $tnsnameregex){
            continue
        }
        $new = [PSCustomObject]@{
            TnsName = $tnsname
            Host = $tnsstring | select-string -allmatches "(?<=host\s*=\s*)[^\)\s]+" | select -expand matches | select -expand value
            Port = $tnsstring | select-string -allmatches "(?<=port\s*=\s*)[^\)\s]+" | select -expand matches | select -expand value
            ServiceName = $tnsstring | select-string -allmatches "(?<=service_name\s*=\s*)[^\)\s]+" | select -expand matches | select -expand value
            Sid = $tnsstring | select-string -allmatches "(?<=sid\s*=\s*)[^\)\s]+" | select -expand matches | select -expand value
            TnsString = $tnsstring -replace '^[^\(]+|\s' 
        }
        if (-not $nolowercase){
            $new.TnsName = $new.TnsName.ToLower()
            $new.Host = $new.Host.ToLower()
            $new.Port = $new.Port.ToLower()
            $new.ServiceName = if ($new.ServiceName){$new.servicename.ToLower()}else{$null}
            $new.Sid = if ($new.sid){$new.sid.ToLower()}else{$null}
            $new.TnsString = $new.TnsString.tolower()
        }

        $new
    }


#    $matched = $filecontents -replace '#.*\r|^\S{0,}\r' | select-string "(?ms)^(?<name>$tnsnameregex\S{0,})=?.*?host\s{0,}=\s{0,}(?<host>[^\)]+).*?port\s{0,}=\s{0,}(?<port>[^\)]+).*?(sid|service_name)\s{0,}=\s{0,}(?<sid>[^\)]+)" -allmatches
#
#    $allresults = @()
#
#    foreach ($match in $matched.matches){
#        $match.value -match "(?ms)^(?<name>$tnsnameregex\S{0,})=?.*?host\s{0,}=\s{0,}(?<host>[^\)]+).*?port\s{0,}=\s{0,}(?<port>[^\)]+).*?(?<type>sid|service_name)\s{0,}=\s{0,}(?<serviceOrSid>[^\)]+)" | out-null
#
##        $new = new-object PSCustomObject
##        $new | add-member -membertype NoteProperty -name "TnsName" -value $matches.name
##        $new | add-member -membertype NoteProperty -name "Host" -value $matches.host
##        $new | add-member -membertype NoteProperty -name "Port" -value $matches.port
##        $new | add-member -membertype NoteProperty -name "ServiceName" -value $matches.sid
##
#        $new = [PSCustomObject]@{
#            TnsName = $matches.name
#            Host = $matches.host
#            Port = $matches.port
#            ServiceName = if ($matches.type -eq 'service_name'){$matches.serviceorsid}else{$null}
#            Sid = if ($matches.type -eq 'sid'){$matches.serviceorsid}else{$null}
#        }
#
#        if (-not $nolowercase){
#            $new.TnsName = $new.TnsName.ToLower()
#            $new.Host = $new.Host.ToLower()
#            $new.Port = $new.Port.ToLower()
#            $new.ServiceName = if ($new.ServiceName){$new.servicename.ToLower()}else{$null}
#            $new.Sid = if ($new.sid){$new.sid.ToLower()}else{$null}
#        }
#
#
#        $allresults += $new
#        
#    }
#    $allresults
}

if (-not ([System.Management.Automation.PSTypeName]'MyAsyncTest').Type) {
    add-type -typedefinition  @'
    using System.Threading.Tasks; 
    using System.Collections.Generic; 
    using System.Diagnostics; 

    public class MyAsyncTest{

        static string Wait(int seconds,int divideBy){
            System.Threading.Thread.Sleep(seconds * 1000 / divideBy);
            return seconds.ToString();
        }

        static async Task<string> WaitAsync(int seconds,int divideBy){
            return await Task.Run(() => Wait(seconds,divideBy));
        }

        // Three things to note in the signature:
        //  - The method has an async modifier.
        //  - The return type is Task or Task<T>. (See "Return Types" section.)
        //    Here, it is Task<string> because the return statement returns an string.
        //  - The method name ends in "Async."
        //public static async Task<string> GoAsync(){
        public static async Task<string[]> GoAsync(bool forceError = false){

            List<Task<string>> tasks = new List<Task<string>>();
            tasks.Add(WaitAsync(3,1));
            tasks.Add(WaitAsync(1,1));
            tasks.Add(WaitAsync(5,1));
            tasks.Add(WaitAsync(2,1));

            if (forceError){
                tasks.Add(WaitAsync(2,0));
            }


            List<string> results = new List<string>();

            try{
                await Task.WhenAll(tasks).ConfigureAwait(false); //https://msdn.microsoft.com/en-us/magazine/jj991977.aspx

            //if not caught, then the task will return to client in faulted state
            }catch(System.Exception ex){

                //foreach(Task task in tasks) {
                    //if (task.IsFaulted){
                        //results.Add(ex.ToString());
                    //}
                //}

                Debug.WriteLine("task error: " + ex);
            }

            foreach(Task<string> task in tasks){
                if (!task.IsFaulted){
                    results.Add(task.Result);
                }else{
                    results.Add(task.Exception.InnerException.Message);
                }
            }

            return await Task.Run(() => {return results.ToArray();});
        }
    }
'@
}

function Test-AsyncMethod{
    param(
        [string]$waitmessage = 'waiting...'
    )

    $cursorPosition = $host.ui.rawui.cursorPosition


    $start = get-date

    $task = [myasynctest]::goasync()

    $completed = show-Asyncwaitmessage $waitmessage task @('iscompleted') 

    $end = (new-timespan $start (get-date))

    if ($completed){
        "done in $($end.totalseconds) seconds"
    }else{
        "cancelled after $($end.totalseconds) seconds"
    }

}

function Show-AsyncWaitMessage{

    param(
        [parameter(position=0,mandatory=$false,ValueFromPipeline=$true)][string]$Message = "Waiting",
        [parameter(position=1,mandatory=$true,ValueFromPipeline=$false)][string]$ConditionVariablename,
        [parameter(position=2,mandatory=$false,ValueFromPipeline=$false)][string[]]$ConditionMethodPropertyChain = @(),
        [parameter(position=3,mandatory=$false,ValueFromPipeline=$false)][object]$ConditionMatch = $true
    )

    $start = get-date
    $check = $start


    if ($host.name -eq 'consolehost'){
        $setControlC = $true
        $controlCSave = [console]::treatcontrolcasinput
    }else{
        $setControlC = $false
    }

    if ($setcontrolc){
        [console]::TreatControlCAsInput = $true
    }

    $completed = $true
    $progressbarcounter = 0

    $lasttimespancheck = (new-timespan $check (get-date))

    if ($host.name -eq 'consolehost'){

        $messageArray = ($message -split "`r`n") -split "`n"
        $messageOutput = ""
        
        for ($x=0;$x -lt $messagearray.count -and $x -lt 12;$x++){
            if ($x -eq 11){
                $messageoutput += "..."
                break
            }

            if ($messagearray[$x].trimend().length -gt ($host.ui.rawui.buffersize.width - 4)){
                $messageoutput += $messagearray[$x].trimend().substring(0, ($host.ui.rawui.buffersize.width - 4 - 3)) + "..."
            }else{
                $messageoutput += ($messagearray[$x].trimend() + (" " * ($host.ui.rawui.buffersize.width - $messagearray[$x].trimend().length - 4)))
            }
        }
    }else{
        $messageoutput = $message
    }

    while ($true){

        if ($setcontrolc -and [console]::KeyAvailable) {
            $key = [system.console]::readkey($true)
            if (($key.modifiers -band [consolemodifiers]"control") -and ($key.key -eq "C")) {
                $completed = $false
                break
            }
        }

        #get the scope of the variable based on whether it was called from this module or not
        if ((get-pscallstack)[1].scriptname -eq (get-pscallstack)[0].scriptname){
            $variablescope = 1
        }else{
            $variablescope = 2
        }
        
        #get the variable from the appropriate scope
        $checkVar = (get-variable -name $conditionVariablename -scope $variablescope).value

        #build the variable's property and method naming
        foreach ($methodproperty in $conditionmethodpropertychain){
            if ($methodproperty.trim() -match '^(?<name>[^(]{1,})(?<method>\(\)$){0,1}'){
                if ($matches.method){
                    $checkvar = $checkvar."$methodproperty"()
                }else{
                    $checkvar = $checkvar."$methodproperty"
                }
            }else{
                throw 'invalid condition method/property'
            }
        }
        
        #if the condition is met, exit 
        if ($checkvar -eq $conditionMatch){
            break
        }

        $timespan = (new-timespan $check (get-date))

        if ($timespan.totalmilliseconds - $lastTimeSpanCheck.totalmilliseconds -lt 5){
            continue
        }

        $lasttimespancheck = $timespan

        if ($progressbarcounter -ge 100){
            $directionup = $false
        }elseif($progressbarcounter -le 0){
            $directionup = $true
        }

        if ($directionup){
            $progressbarcounter++
        }else{
            $progressbarcounter--
        }

        $timespanstring = "$($timespan.seconds) seconds"

        if ($timespan.minutes -gt 0){
            $timespanstring = "$($timespan.minutes) minutes, " + $timespanstring
        }
        if ($timespan.hours -gt 0){
            $timespanstring = "$($timespan.hours) hours, " + $timespanstring
        }
        if ($timespan.days -gt 0){
            $timespanstring = "$($timespan.days) days, " + $timespanstring
        }


        write-progress -activity " " -status $messageoutput -PercentComplete $progressbarcounter -currentoperation "$timespanstring elapsed" 
    }
    
    write-progress -Activity " " -status $message -completed

    if ($setcontrolc){
        [console]::TreatControlCAsInput = $controlcsave
    }

#    $pos = [System.Management.Automation.Host.Coordinates]::new(0,$host.ui.rawui.cursorposition.y)
#    $newBuffer = $host.ui.rawui.newbuffercellarray((" " * $host.ui.rawui.buffersize.width),$host.ui.rawui.foregroundcolor,$host.ui.rawui.backgroundcolor)
#
#    $host.ui.rawui.SetBufferContents($pos,$newbuffer)

    $completed
    return 
}

function Invoke-InParallel{
    [CmdletBinding()]

#1..2 | % {
#        [pscustomobject]@{
#            input = @{
#                Number=$_
#            } 
#            passthruoutput = @{
#                Something = 'three'
#            }
#        }
#    } | Invoke-InParallel -command 'asdf' -supportingcommands @{'asdf'={param($number) write-output "hi$($number)"}} | % {
#        [pscustomobject]@{
#            hi1 = $_.result
#            hi2 = $_.passthruoutput['something']
#        }
#    }

    param(
        [parameter(valuefrompipeline,mandatory)][psobject]$CommandParameters,
        [parameter(position=0,mandatory)][string]$Command,
        [parameter(position=1)][hashtable]$SupportingCommands,
        [parameter(position=2)][int]$MaxRunspaces = 20
    )
    
    begin{
        $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

        foreach($commandName in $supportingCommands.keys){
            write-verbose "adding supporting function: $commandname"
            $sessionstate.commands.add([System.Management.Automation.Runspaces.SessionStateFunctionEntry]::new($commandName,$supportingCommands[$commandName].tostring()))
        }

        $runspacepool = [RunspaceFactory]::CreateRunspacePool(1, $maxrunspaces,$sessionstate,$host)
        $runspacepool.Open() 

        $threads = [system.collections.generic.list[object]]::new()
    }

    process{
        $ps = [powershell]::create()
        $ps.runspacepool = $runspacepool

            write-verbose "setting command to execute: $command"
            [void]$ps.addcommand($command)
            foreach($parameterName in $commandParameters.input.keys){
                write-verbose "setting parameter for command: $parameterName"
                [void]$ps.addparameter($parameterName,$commandParameters.input[$parameterName])
            }

        $asyncresult = $ps.begininvoke()
        $threads.add(
            [pscustomobject]@{
                ps=$ps
                asyncresult=$asyncresult
                PassthruOutput=$commandparameters.passthruoutput
            }
        )

    }

    end{

        try{
            $threadsDone = [system.collections.generic.list[int]]::new()

            do{
                for($x=0;$x -lt $threads.count;$x++){

                    write-progress -activity "Processing Threads" -status "$($threadsdone.count) of $($threads.count)" -percent ($threadsdone.count / $threads.count * 100)

                    if ($x -in $threadsdone){
                        continue
                    }

                    if ($threads[$x].asyncresult.iscompleted){
                        $threadsdone.add($x)
                    }
                }
            }while ($threadsDone.count -lt $threads.count)

            write-progress -activity "Processing Threads" -status "Done" -completed

            $results = [system.collections.generic.list[object]]::new()

            foreach($thread in $threads){

                $threaderror = $thread.ps.streams.error
                if ($threaderror){
#                    throw $thread.ps.streams.error
                    write-warning "Error in thread"
                }

                $result = $thread.ps.endinvoke($thread.asyncresult)



                $results.add(
                    [pscustomobject]@{
                        Error = $threaderror.getenumerator() | % {$_}
                        Result = $result.getenumerator() | % {$_}
                        PassthruOutput = $thread.PassthruOutput
                    }
                )
            }

            write-output $results
        }finally{
            foreach($thread in $threads){
                $thread.ps.dispose()
            }

            $runspacepool.close()
            $runspacepool.dispose()
        }

    }
}

function Get-SslCertificateFromServer {
    #https://serverfault.com/a/820698

    param(
        $hostname,
        $port=443,
        $SNIHeader,
        [switch]$FailWithoutTrust
    )

    if (!$SNIHeader) {
        $SNIHeader = $hostname
    }

    $cert = $null
    try {
        $tcpclient = [System.Net.Sockets.tcpclient]::new()
        $tcpclient.Connect($hostname,$port)

        #Authenticate with SSL
        if (!$FailWithoutTrust) {
            $sslstream = [System.Net.Security.SslStream]::new($tcpclient.GetStream(),$false, {$true})
        } else {
            $sslstream = [System.Net.Security.SslStream]::new($tcpclient.GetStream(),$false)
        }

        $sslstream.AuthenticateAsClient($SNIHeader)
        $cert =  [System.Security.Cryptography.X509Certificates.X509Certificate2]($sslstream.remotecertificate)

     } catch {
        throw "Failed to retrieve remote certificate from $hostname`:$port because $_"
     } finally {
        #cleanup
        if ($sslStream) {$sslstream.close()}
        if ($tcpclient) {$tcpclient.close()}        
     }    
    write-output $cert
}

function Stop-TcpConnection {
    param(
        [parameter(valuefrompipeline)]
        [object]$NetTcpConnection
    )

    begin{
    }

    process{
        if (-not ($nettcpconnection.localaddress -and $nettcpconnection.localport -and $nettcpconnection.remoteaddress -and $nettcpconnection.remoteport)){
            throw "invalid `$nettcpconnection provided"
        }

        if (-not ("NZ.TcpConnection" -as [type])) {
            $code = @"
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Net.Sockets;
    using System.Runtime.InteropServices;
    using System.Text;

    namespace NZ
    {
        public class TcpConnection
        {
            // Taken from https://github.com/yromen/repository/tree/master/DNProcessKiller
            // It part from the Disconnecter class. 
            // In case of nested class use "+" like that [ConnectionKiller.Program+Disconnecter]::Connections()

            /// <summary> 
            /// Enumeration of the states 
            /// </summary> 
            public enum State
            {
                /// <summary> All </summary> 
                All = 0,
                /// <summary> Closed </summary> 
                Closed = 1,
                /// <summary> Listen </summary> 
                Listen = 2,
                /// <summary> Syn_Sent </summary> 
                Syn_Sent = 3,
                /// <summary> Syn_Rcvd </summary> 
                Syn_Rcvd = 4,
                /// <summary> Established </summary> 
                Established = 5,
                /// <summary> Fin_Wait1 </summary> 
                Fin_Wait1 = 6,
                /// <summary> Fin_Wait2 </summary> 
                Fin_Wait2 = 7,
                /// <summary> Close_Wait </summary> 
                Close_Wait = 8,
                /// <summary> Closing </summary> 
                Closing = 9,
                /// <summary> Last_Ack </summary> 
                Last_Ack = 10,
                /// <summary> Time_Wait </summary> 
                Time_Wait = 11,
                /// <summary> Delete_TCB </summary> 
                Delete_TCB = 12
            }

            /// <summary> 
            /// Connection info 
            /// </summary> 
            private struct MIB_TCPROW
            {
                public int dwState;
                public int dwLocalAddr;
                public int dwLocalPort;
                public int dwRemoteAddr;
                public int dwRemotePort;
            }

            //API to change status of connection 
            [DllImport("iphlpapi.dll")]
            //private static extern int SetTcpEntry(MIB_TCPROW tcprow); 
            private static extern int SetTcpEntry(IntPtr pTcprow);

            //Convert 16-bit value from network to host byte order 
            [DllImport("wsock32.dll")]
            private static extern int ntohs(int netshort);

            //Convert 16-bit value back again 
            [DllImport("wsock32.dll")]
            private static extern int htons(int netshort);

            /// <summary> 
            /// Close a connection by returning the connectionstring 
            /// </summary> 
            /// <param name="connectionstring"></param> 
            public static void CloseConnection(string localAddress, int localPort, string remoteAddress, int remotePort)
            {
                try
                {
                    //if (parts.Length != 4) throw new Exception("Invalid connectionstring - use the one provided by Connections.");
                    string[] locaddr = localAddress.Split('.');
                    string[] remaddr = remoteAddress.Split('.');

                    //Fill structure with data 
                    MIB_TCPROW row = new MIB_TCPROW();
                    row.dwState = 12;
                    byte[] bLocAddr = new byte[] { byte.Parse(locaddr[0]), byte.Parse(locaddr[1]), byte.Parse(locaddr[2]), byte.Parse(locaddr[3]) };
                    byte[] bRemAddr = new byte[] { byte.Parse(remaddr[0]), byte.Parse(remaddr[1]), byte.Parse(remaddr[2]), byte.Parse(remaddr[3]) };
                    row.dwLocalAddr = BitConverter.ToInt32(bLocAddr, 0);
                    row.dwRemoteAddr = BitConverter.ToInt32(bRemAddr, 0);
                    row.dwLocalPort = htons(localPort);
                    row.dwRemotePort = htons(remotePort);

                    //Make copy of the structure into memory and use the pointer to call SetTcpEntry 
                    IntPtr ptr = GetPtrToNewObject(row);
                    int ret = SetTcpEntry(ptr);

                    if (ret == -1) throw new Exception("Unsuccessful");
                    if (ret == 65) throw new Exception("User has no sufficient privilege to execute this API successfully");
                    if (ret == 87) throw new Exception("Specified port is not in state to be closed down");
                    if (ret == 317) throw new Exception("The function is unable to set the TCP entry since the application is running non-elevated");
                    if (ret != 0) throw new Exception("Unknown error (" + ret + ")");

                }
                catch (Exception ex)
                {
                    throw new Exception("CloseConnection failed (" + localAddress + ":" + localPort + "->" +  remoteAddress + ":" + remotePort + ")! [" + ex.GetType().ToString() + "," + ex.Message + "]");
                }
            }

            private static IntPtr GetPtrToNewObject(object obj)
            {
                IntPtr ptr = Marshal.AllocCoTaskMem(Marshal.SizeOf(obj));
                Marshal.StructureToPtr(obj, ptr, false);
                return ptr;
            }
        }
    }

"@
            Add-Type -TypeDefinition $code -passthru -Language CSharp -referencedassemblies "System.dll"| Out-Null
        }

        [NZ.TcpConnection]::CloseConnection($nettcpconnection.localaddress,$nettcpconnection.localport,$nettcpconnection.remoteaddress,$nettcpconnection.remoteport)
    }
    end{
    }

}

function Get-Function{
    param(
        [string]$Name,
        [string]$Path,
        [string]$definition,
        [switch]$HideDefinition
    )

    $a = get-command $name -erroraction ignore
    if (-not $a){
        if ($path){
            write-host ""
            write-host "$path -> $definition" -fore blue
            write-host ""
        }
        return
    }

    
    if ($a.modulename){
        $module = "$($a.modulename)\"
    }

    if ($path){
        $path = "$path ->"
    }

    $path = "$path $($a.name)".trim()

    if ($a.commandtype -eq 'function'){
        write-host ""
        write-host "$path -> $module$($a.name)" -fore blue
        write-host ""
        if (-not $hidedefinition){
            $a.definition
        }
        return 
    }elseif ($a.commandtype -eq 'cmdlet'){
        write-host ""
        write-host "$path -> $module$($a.name)" -fore blue
        write-host ""
        return 
    }
    if ($a.commandtype -eq 'alias'){
        get-function $a.ReferencedCommand $path $a.definition -hidedefinition:$hidedefinition
    }
}

function Get-GrepMatchValues{
    param(
        [parameter(mandatory=$true,ValueFromPipeline=$true)]
        [Microsoft.PowerShell.Commands.MatchInfo[]]$Input,
        [parameter(position=0)]
        [string]$GroupName = '0'
    )

    begin{
    }
    process{
        foreach ($match in $input.matches){
#            $match.value 
            $match.groups | where name -eq $groupname | % value
        }
    }
    end{
    }
}


function Format-HexBytes{
    param(
        [parameter(mandatory=$true,ValueFromPipeline=$true)][byte[]]$Bytes,
        [ValidateSet("Ascii", "UTF32", "UTF7", "UTF8", "BigEndianUnicode", "Unicode")][string] $Encoding = "Ascii"
    )

    begin{
        $chars = @()
    }

    process{

        switch ($encoding){
            "Ascii"{
                $chars += [system.text.encoding]::Ascii.getchars($bytes)
            }"UTF32"{
                $chars += [system.text.encoding]::UTF32.getchars($bytes)
            }"UTF7"{
                $chars += [system.text.encoding]::UTF7.getchars($bytes)
            }"UTF8"{
                $chars += [system.text.encoding]::UTF8.getchars($bytes)
            }"BigEndianUnicode"{
                $chars += [system.text.encoding]::BigEndianUnicode.getchars($bytes)
            }"Unicode"{
                $chars += [system.text.encoding]::Unicode.getchars($bytes)
            }
        }
    }

    end{
        $string = $chars -join ""

        $string | format-hex -encoding $encoding
    }
    
}


function Test-Xml{
    <#
    .SYNOPSIS
    Test the validity of an XML file
    #>
    [CmdletBinding(DefaultParameterSetName="String")]
    param (
        [parameter(parametersetname="String",position=0,mandatory=$true,valuefrompipeline=$true)][ValidateNotNullorEmpty()]$String,
        [parameter(parametersetname="File",position=1,mandatory=$true,valuefrompipeline=$true)][ValidateNotNullorEmpty()]$File,
        [parameter(parametersetname="File",position=0,mandatory=$false)][switch]$FileInput
    )

    begin{
    }

    process{

        $result = $true
        $message = $null
        $name = $null

        $xml = New-Object System.Xml.XmlDocument

        if ($string -is [system.io.fileinfo]){
            $file = $string
            $string = $null
        }

        if ($string){
            $contents = $string
            try {
                $xml.LoadXml($string)
            }
            catch [System.Xml.XmlException] {
                $message = $_.toString()
                $result = $false
            }
        }else{
            if (-not ($file -is [system.io.fileinfo])){
                $file = get-childitem $file -erroraction silentlycontinue
                if (-not $file){
                    throw "File not found."
                }
            }

            $name = $file.name
            $contents = cat $file -raw

            try {
                $xml.Load((convert-path $file))
            }
            catch [System.Xml.XmlException] {
                $message = $_.toString()
                $result = $false
            }
        }

        [PSCustomObject]@{
            FileName = $name
            IsValid = $result
            Message = $message
            Data = $contents
        }
    }
    end{
    }
}

function Convert-NumberStringToSum{
    param(
        [parameter(valuefrompipeline=$true)]$NumberString
    )

    $NumberString -split "`n" | % {$_.trim() -split '\s{1,}'} |  measure -sum | select -expand sum
}



function New-SelectAlias{
    param(
        [parameter(mandatory=$true)] $Name,
        [parameter(mandatory=$true)] [scriptblock]$Value 
    )

    @{
        name = $name
        ex = $value
    }
}

function Invoke-GitDiff{


    param(
        #empty - all params in $args array will be expected to be files
        [switch]$RawInput,
        [switch]$FlOss,
        [switch]$CsvOss,
        [switch]$Format,
        [switch]$Verbose
    )

    if ($verbose){
        $verbosepreference = 'Continue'
    }

    $files = @()

    remove-item "$([system.io.path]::gettemppath())*__gdif__" -confirm:$false
    
    $params = $args
    if ($args.count -eq 1 -and $args[0] -is [array]){
        $params = $args[0]
    }

    foreach ($file in $params){
        if ($rawinput){

            $tmpfilename = "$([system.io.path]::GetTempFileName())__gdif__" 
            $string = $file
            if ($flOss){
                $string = $string | format-list | out-string -stream
            }
            if ($csvoss){
                $string = $string | convertto-csv | out-string -stream
            }
            $tmpfile = $string | set-content -path $tmpfilename -confirm:$false 
            $files += convert-path $tmpfilename


        }else{

            if (-not (test-path $file)){
                write-error "file not found: $file"
                return
            }

            $files += convert-path $file
        }

    }

    if ($files.count -ne 2){
        "incorrect number of files to compare"
        return
    }


    $command = 'git diff -b --no-index --color-words '
    foreach ($file in $files){
#        $command += """$($file -replace ' ','\ ')"" "
        $command += """$file"" "
    }

    write-verbose $command
    $lines = [scriptblock]::create($command).invoke() -split "`n"

    if (-not $format){
        write-output $lines
        return
    }

    $lines -replace "($([convert]::tochar(27))\[\d*m@@.*?@@$([convert]::tochar(27))\[\d*m)\s","`n`$1`n`n" | write-ansicoloredoutput 



#    $command = 'git diff -b --no-index '
#    foreach ($file in $files){
#        $command += """$($file -replace ' ','\ ')"" "
#    }
#
#
#$headerDone = $true
#
##    $command
#    foreach ($contentLine in [scriptblock]::create($command).invoke()){
#
#        if ($noformat){
#            $contentLine
#            continue
#        }
#
#        #based on unified diff / results of git diff
#
#        if ($contentLine -match "^diff --git") {
#            Write-Host "`n`n`n$contentLine" -ForegroundColor Cyan 
#            $headerDone = $false
#        } elseif ($headerDone -eq $false -and $contentLine -match "^Index") {
#            Write-Host $contentLine -ForegroundColor DarkCyan 
#        } elseif ($headerDone -eq $false -and $contentLine -match "^\+{3}\s") {
#            Write-Host $contentLine -ForegroundColor Green 
#        } elseif ($headerDone -eq $false -and $contentLine -match "^\-{3}\s") {
#            Write-Host $contentLine -ForegroundColor Red 
#        } elseif ($headerDone -eq $false -and $contentLine -match "^\={3}\s") {
#            Write-Host $contentLine -ForegroundColor DarkGray 
#        } elseif ($contentLine -match "^\@{2}") {
#            Write-Host "`n$contentLine`n" -ForegroundColor White 
#            $headerDone = $true
#        } elseif ($contentLine -match "^\+") {
#            Write-Host $contentLine -ForegroundColor DarkGreen 
#        } elseif ($contentLine -match "^\-") {
#            Write-Host $contentLine -ForegroundColor DarkRed
#        } else {
#            Write-Host $contentLine -foregroundcolor Gray 
#        }
#    }
}

function Invoke-VimDiff{


    param(
        #empty - all params in $args array will be expected to be files
        [switch]$RawInput,
        [switch]$FlOss,
        [switch]$CsvOss,
        [switch]$Format,
        [switch]$Verbose
    )

    if ($verbose){
        $verbosepreference = 'Continue'
    }

    $files = @()

    remove-item "$([system.io.path]::gettemppath())*__vdif__" -confirm:$false
    
    $params = $args
    if ($args.count -eq 1 -and $args[0] -is [array]){
        $params = $args[0]
    }

    foreach ($file in $params){
        if ($rawinput){

            $tmpfilename = "$([system.io.path]::GetTempFileName())__vdif__" 
            $string = $file
            if ($flOss){
                $string = $string | format-list | out-string -stream
            }
            if ($csvoss){
                $string = $string | convertto-csv | out-string -stream
            }
            $tmpfile = $string | set-content -path $tmpfilename -confirm:$false 
            $files += convert-path $tmpfilename


        }else{

            if (-not (test-path $file)){
                write-error "file not found: $file"
                return
            }

            $files += convert-path $file
        }

    }

    if ($files.count -ne 2){
        "incorrect number of files to compare"
        return
    }


    $command = "tools:\vim\gvim.exe -c 'set diffopt=inline:char' -d "
    foreach ($file in $files){
#        $command += """$($file -replace ' ','\ ')"" "
        $command += """$file"" "
    }

    write-verbose $command
    [scriptblock]::create($command).invoke()

#    $lines = [scriptblock]::create($command).invoke() -split "`n"
#
#    if (-not $format){
#        write-output $lines
#        return
#    }

#    $lines -replace "($([convert]::tochar(27))\[\d*m@@.*?@@$([convert]::tochar(27))\[\d*m)\s","`n`$1`n`n" | write-ansicoloredoutput 



#    $command = 'git diff -b --no-index '
#    foreach ($file in $files){
#        $command += """$($file -replace ' ','\ ')"" "
#    }
#
#
#$headerDone = $true
#
##    $command
#    foreach ($contentLine in [scriptblock]::create($command).invoke()){
#
#        if ($noformat){
#            $contentLine
#            continue
#        }
#
#        #based on unified diff / results of git diff
#
#        if ($contentLine -match "^diff --git") {
#            Write-Host "`n`n`n$contentLine" -ForegroundColor Cyan 
#            $headerDone = $false
#        } elseif ($headerDone -eq $false -and $contentLine -match "^Index") {
#            Write-Host $contentLine -ForegroundColor DarkCyan 
#        } elseif ($headerDone -eq $false -and $contentLine -match "^\+{3}\s") {
#            Write-Host $contentLine -ForegroundColor Green 
#        } elseif ($headerDone -eq $false -and $contentLine -match "^\-{3}\s") {
#            Write-Host $contentLine -ForegroundColor Red 
#        } elseif ($headerDone -eq $false -and $contentLine -match "^\={3}\s") {
#            Write-Host $contentLine -ForegroundColor DarkGray 
#        } elseif ($contentLine -match "^\@{2}") {
#            Write-Host "`n$contentLine`n" -ForegroundColor White 
#            $headerDone = $true
#        } elseif ($contentLine -match "^\+") {
#            Write-Host $contentLine -ForegroundColor DarkGreen 
#        } elseif ($contentLine -match "^\-") {
#            Write-Host $contentLine -ForegroundColor DarkRed
#        } else {
#            Write-Host $contentLine -foregroundcolor Gray 
#        }
#    }
}

function invoke-Xslt{
    param(
        [string]$Xml,
        [string]$Xslt
    )

    try{

        if (-not $xml -or $xml -eq ""){
            write-error "Invalid `$Xml: Null or Empty"
            return
        }

        if (-not $xslt -or $xslt -eq ""){
            write-error "Invalid `$Xslt: Null or Empty"
            return
        }

        $test = test-xml $xml
        if (-not $test.isvalid){
            write-error "Invalid `$Xml: $($test.message)"
            return
        }

        $test = test-xml $xslt
        if (-not $test.isvalid){
            write-error "Invalid `$Xslt: $($test.message)"
            return
        }


        $xsltStringReader = [system.io.StringReader]::new($xslt) 
        $xmlStringReader = [system.io.StringReader]::new($xml)

        $xsltXmlReader = [system.xml.XmlReader]::Create($xsltStringReader)
        $xmlXmlReader = [system.xml.XmlReader]::Create($xmlStringReader)

        $transformer = [system.xml.xsl.XslCompiledTransform]::new()
        $transformer.Load($xsltxmlreader);

        $resultStringWriter = [system.io.StringWriter]::new()
        $resultXmlWriter = [system.xml.XmlWriter]::Create($resultstringwriter, $transformer.OutputSettings)

        $transformer.Transform($xmlxmlreader, $resultxmlwriter)
        $output = $resultstringwriter.ToString()

    }finally{
        if($resultxmlwriter){$resultxmlwriter.dispose()}
        if($resultstringwriter){$resultstringwriter.dispose()}
        if($xmlxmlreader){$xmlxmlreader.dispose()}
        if($xsltxmlreader){$xsltxmlreader.dispose()}
        if($xmlstringreader){$xmlstringreader.dispose()}
        if($xsltstringreader){$xsltstringreader.dispose()}
    }

    $output
}

function Remove-AliasFromScript {

    param(
        [parameter(ValueFromPipeline=$true)]$scriptText
    )

    $aliases = @{}

    get-alias | foreach-object { $aliases.add($_.name, $_.definition)}

    $errors = $null
    $changedText = $scripttext

    $parsedTokens = [system.management.automation.psparser]::Tokenize($changedText, [ref]$errors) | Where-Object { $_.type -eq "command" } 

    foreach ($token in $parsedTokens){

        if($aliases.($token.content)) {
            $changedText = $changedText -replace ('(?<=(\W|\b|^))' + [regex]::Escape($token.content) + '(?=(\W|\b|$))'), $aliases.($token.content)
        }
    }

    write-output $changedText

} 

function ConvertTo-RegexEscape{
    param(
        [parameter(mandatory,valuefrompipeline)]$String
    )
    begin{
    }
    process{
        [System.Text.RegularExpressions.regex]::Escape($string)
    }
    end{
    }
}

function Get-ImageFromZpl{
    param(
        $Zpl,
        $OutputPngFile
    )

    if (test-path $OutputPngFile){
        write-output 'file already exists'
        return
    }

    $dir = split-path $OutputPngFile -parent

    if (-not $dir -or $dir.trim().length -eq 0){
        $dir = '.'
    }

    if (-not (test-path $dir)){
        write-output 'invalid directory'
        return
    }

    Invoke-RestMethod  -Method Post  -Uri http://api.labelary.com/v1/printers/24dpmm/labels/4x6/0/  -ContentType "application/x-www-form-urlencoded" -body $zpl -outfile $OutputPngFile

}

function ConvertFrom-GZip{
    param(
        $GZipBytes,
        [switch]$Raw
    )
    try{
        $stream = [io.memorystream]::new($gzipbytes)
        $data = [System.IO.Compression.GZipStream]::new($stream,[system.io.compression.compressionmode]::decompress)
        $reader = [system.io.streamreader]::new($data)

        $text = $reader.readtoend()

        $output = $null

        if ($raw){
            $output = $text
        }else{
            $output = $text -split "`n"
        }

        write-output $output
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
function Read-ZippedFile{
    Param(
        [parameter(valuefrompipeline)]$ZippedFile,
        [validateset('Zip','GZip')]$CompressionType = 'Zip',
        [switch]$InferObjectTypeFromFileExtension,
        [switch]$AsHashTable,
        [switch]$Raw,
        [switch]$ListingOnly
    )

    if ($zippedfile -is [system.io.fileinfo]){
        $zippedfile = $zippedfile.fullname
    }


    if (-not (test-path $zippedfile -pathtype leaf)){
        write-output "$zippedfile not found"
        return
    }

    $zippedfile = (convert-path $zippedfile)

    if ($compressiontype -eq 'zip'){

        try{
            if (-not ([System.Management.Automation.PSTypeName]'system.io.compression.zipfile').Type){
                add-type -AssemblyName System.IO.Compression.FileSystem
                $null = [System.IO.Compression.zipfile]::Open
            }

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

function Invoke-DeepClone{
    param(
        $SourceObject
    )

    $tmp = [System.Management.Automation.PSSerializer]::Serialize($sourceObject, [int32]::MaxValue)
    write-output ([System.Management.Automation.PSSerializer]::Deserialize($tmp))
}


function Join-Collections{
    [CmdletBinding(DefaultParameterSetName="Inner")]
    param(
        [parameter(parametersetname='Inner',position=0)][parameter(parametersetname='Left',position=0)]$LeftSide,
        [parameter(parametersetname='Inner',position=1)][parameter(parametersetname='Left',position=1)]$RightSide,
        [parameter(parametersetname='Inner',position=2)][parameter(parametersetname='Left',position=2)]$JoinConditions,
        [parameter(parametersetname='Left')][switch]$LeftJoin,
        [parameter(parametersetname='Left')][switch]$UnmatchedOnly
        

    ) 

    if ($joinConditions){
        $outerkeystring = [text.stringbuilder]::new()
        $innerkeystring = [text.stringbuilder]::new()

        $null = $outerkeystring.append("[pscustomobject]@{")
        $null = $innerkeystring.append("[pscustomobject]@{")

        $counter = 0;
        foreach($record in $joinconditions.getenumerator()){
            $counter++
            $null = $record.name.tostring() -match '(?<type>^\[[^\]]+\])?(?<value>.*)' 
            $null = $outerkeystring.append("$counter=$($matches.type)(`$args[0].'$($matches.value)');")

            $null = $record.value.tostring() -match '(?<type>^\[[^\]]+\])?(?<value>.*)' 
            $null = $innerkeystring.append("$counter=$($matches.type)(`$args[0].'$($matches.value)');")
        }

        $null = $outerkeystring.append("} | convertto-json -compress")
        $null = $innerkeystring.append("} | convertto-json -compress")

    }else{
        $outerkeystring = '$args[0]'
        $innerkeystring = '$args[0]'
    }


    if ($leftjoin){
        $join = [scriptblock]::create(",([linq.enumerable]::groupjoin([system.collections.generic.ienumerable[system.object]]`$leftside,[system.collections.generic.ienumerable[system.object]]`$rightside,[func[object,object]]{$($outerkeystring.tostring())},[func[object,object]]{$($innerkeystring.tostring())},[func[object,[system.collections.generic.ienumerable[system.object]],object]]{[pscustomobject]@{LeftSide=`$args[0];RightSide=`$args[1]}}))")
    }else{
        $join = [scriptblock]::create(",([linq.enumerable]::join([system.collections.generic.ienumerable[system.object]]`$leftside,[system.collections.generic.ienumerable[system.object]]`$rightside,[func[object,object]]{$($outerkeystring.tostring())},[func[object,object]]{$($innerkeystring.tostring())},[func[object,object,object]]{[pscustomobject]@{LeftSide=`$args[0];RightSide=`$args[1]}}))")
    }

    write-verbose $join.tostring()

    $results = $join.invoke()| % {$_}
    if ($UnmatchedOnly){
        $results = $results | where {-not $_.rightside -or $_.rightside.gettype().name -match 'emptypartition'} | % {$_.leftside}
    }

    $results

}

#proxy function to replace tee-object specifically for variables
#tee-object sets variables after output, which means ctrl-c during large output will not set the variable
#the -outvariable switch will only capture partial output on ctrl-c, and also results in an arraylist type, even if the output is an object
#this function sets the variable as the actual object type and then displays the output after capturing the whole value
function Invoke-TeeVariable {

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
        $PSBoundParameters['Scope'] = 2

        Remove-Variable -name $name -scope $psboundparameters['Scope'] -erroraction silentlycontinue -confirm:$false

        $outNoOutput = $null
        if ($PSBoundParameters.TryGetValue('NoOutput', [ref]$outNoOutput)) {
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

#    clean {
#        if ($null -ne $steppablePipeline) {
#            $steppablePipeline.Clean()
#        }
#    }
}


function Invoke-ForEachExpand {
    [CmdletBinding()]
    param(
        [parameter(valuefrompipeline)]$Data,
        [parameter(position=0)]$PropertyName,
        [parameter(position=1)]$First = $null,
        [parameter(position=2)]$Skip = 0
    )
    begin{
        $counter = 0
    }
    process{
        $counter++
        if ($skip -gt 0 -and $counter -le $skip){
            return
        }
        if ($first -and $counter -gt $first + $skip){
            return
        }

        $data | select-object -expand $propertyname
    }
    end{
    }
}

function Invoke-Capitalization{
    param(
        [parameter(valuefrompipeline)]$String,
        [parameter(position=0)]$CapitalizeAfterBackreference = '^|_'
    )

    begin{
    }

    process{
        $dolower = $string |select-string "(?<!$capitalizeafterbackreference)(.)" -all |select -exp matches
        $chars = $string.tochararray()
        $asdf = for($x=0;$x-lt $chars.count;$x++){
            if ($x -in $dolower.index){
                $chars[$x].tostring().tolower()
            }else{
                $chars[$x]
            }
        }
    
        $asdf -join ''
    }
    end{
    }
}

function Format-StringWithLineNumbers{
    param(
        [parameter(valuefrompipeline)][string]$Line
    )

    begin{
        $num = 0
    }
    process{
        "{0:0000}: {1}" -f ++$num,$line
    }
    end{
    }
}

function Get-LdapObject{
    param(
        [hashtable]$Filters = @{objectCategory='person';sAMAccountName='nzeleski'},
#        [validateset('asdf.com')]
        $DomainName = $env:userdomain
    )

    $domain = [adsi]"LDAP://$domainname"
    $search = [System.DirectoryServices.DirectorySearcher]::new($domain)
    $search.pagesize = 200

    $filter = [text.stringbuilder]::new()
    $null = $filter.append("(&")

    foreach ($key in $filters.keys){
        $null = $filter.append("($key=$($filters[$key]))")
    }

    $null = $filter.append(")")

    $search.filter = $filter.tostring() 
    $records = $search.findall() 

    foreach($record in $records){
        $hash = [System.Collections.Specialized.OrderedDictionary]::new()
        $hash.add('__path',$record.path)

        $keys = $record.properties.keys|sort

        foreach($key in $keys){
            $values = $record.properties[$key].foreach({$_})
            if ($values.count -lt 1){
                $value = $null
            }elseif ($values.count -eq 1){
                $value = $values[0]
            }else{
                $value = [System.Linq.enumerable]::tolist($values)
            }
            $hash.add($key,$value)
        }
        [pscustomobject]$hash
    }
}

function Get-HasCount{
    [CmdletBinding()]

    param (
        [parameter(parametersetname="GreaterThan",valuefrompipeline)]
        [parameter(parametersetname="LessThan",valuefrompipeline)]
        [parameter(parametersetname="Equals",valuefrompipeline)]
        $Record,
        [parameter(parametersetname="GreaterThan",position=0,mandatory)]$GreaterThan,
        [parameter(parametersetname="LessThan",position=0,mandatory)]$LessThan,
        [parameter(parametersetname="Equals",position=0,mandatory)]$Equals
    )

    begin{
        $count = 0
    }
    process{
        $count++
    }
    end{
        if (
            ($greaterthan -ne $null -and $count -gt $greaterthan) -or
            ($lessthan -ne $null -and $count -lt $lessthan) -or
            ($equals -ne $null -and $count -eq $equals)
        ){
            write-output $true
        }else{
            write-output $false
        }
    }
}

function ConvertTo-ByteArray{
    param(
        [parameter(position=1,valuefrompipeline)]$String,
        [parameter(position=0)][validateset('ASCII','BigEndianUnicode','Default','Unicode','UTF8','UTF7','UTF32')]$Encoding = 'UTF8'
    )
    begin{
    }
    process{
        $type = [scriptblock]::create("[system.text.encoding]::$encoding").invoke()
        $type.getbytes($string)
    }
    end{
    }
    
}

function Search-ObjectProperties{
    param(
        [parameter(valuefrompipeline)]$Object,
        [parameter(position=0)]$ValueRegex,
        [parameter(position=1)]$KeyRegex,
        [switch]$NotMatchValue,
        [switch]$NotMatchKey,
        [switch]$CaseSensitiveValue,
        [switch]$CaseSensitiveKey,
#        [switch]$UseXml,
        [parameter(position=2)][int]$Depth = 10
    )
    begin{
    }
    process{
        #only works if root is xml
        if ($object -is [xml]){
            $object = $object | convertto-jsonfromxml -jsondepth $depth
        }
        $jsonsplit = $object | convertto-json -depth $depth | % {$_ -split "\r?\n"}
        $valuematchfound = $false

        #todo - work for arrays
        foreach ($line in $jsonsplit) {
            $linematch = $line -match '(^\s*")(?<key>.*?)((?<!\\)"\s*: "?)(?<value>.*?)("?,?$)'
            $linematches = $matches

            if (-not ($linematch)){
                continue
            }

            if ([string]::isnullorempty($linematches.value)){
                continue
            }
            if ($keyregex -ne $null){
                #todo - include form feed, backspace, and unicode values for grepping
                $result = $linematches.key.replace('\"','"').replace('\"','"').replace('\/','/').replace('\b','').replace('\f','').replace('\n',"`n").replace('\r',"`r").replace('\t',"`t")
                $result = $result -replace '\\u\d{4}',''
                $result = $result.replace("\\","\")

                #this isn't a good key match, but maybe the next one will be
                if ($casesensitivekey){
                    if (($result -cmatch $keyregex -and $notmatchkey) -or ($result -cnotmatch $keyregex -and (-not $notmatchkey))){
                        continue
                    }
                }else{
                    if (($result -match $keyregex -and $notmatchkey) -or ($result -notmatch $keyregex -and (-not $notmatchkey))){
                        continue
                    }
                }
            }

            #todo - include form feed, backspace, and unicode values for grepping
            $result = $linematches.value.replace('\"','"').replace('\"','"').replace('\/','/').replace('\b','').replace('\f','').replace('\n',"`n").replace('\r',"`r").replace('\t',"`t")
            $result = $result -replace '\\u\d{4}',''
            $result = $result.replace("\\","\")

            if (((-not $casesensitivevalue) -and ($result -match $valueregex)) -or ($casesensitivevalue -and ($result -cmatch $valueregex))){
                $valuematchfound = $true
                break
            }
        }

        if (($valuematchfound -and (-not $notmatchvalue)) -or ((-not $valuematchfound) -and $notmatchvalue)){
            $object
        }
    }
    end{
    }
}


function Convertto-JsonFromXml{
    param(
        [parameter(valuefrompipeline)]
        $xml,
        [switch]$Raw,
        [switch]$AsJson,
        [switch]$AsJsonCompressed,
        [parameter()]
        [int]$JsonDepth = 25
    )

    begin{
    }
    process{
        $json = [Newtonsoft.Json.jsonconvert]::Serializeobject($xml) 

        if ($raw){
            write-output $json #| convertto-
        }else{
            $jsonoutput =  $json|convertfrom-json
            $props = $jsonoutput | get-member -membertype noteproperty | select -expand name
            $output = [ordered]@{}
            foreach($prop in $props){
                $output.add($prop, $jsonoutput.${prop})
            }

            $result = [pscustomobject]$output

            if ($asjson){
                $result | convertto-json -depth $jsondepth
            }elseif ($asjsoncompressed){
                $result | convertto-json -depth $jsondepth -compress
            }else{
                write-output $result
            }
        }

    }
    end{
    }
    
}

function Set-RemoteProfile {
    param(
        [parameter(valuefrompipeline)]
        [System.Management.Automation.Runspaces.pssession]$PsSession,

        [parameter(position=0)]
        [object]$ProfilePath = 'profilehome:\remote-profile.ps1'
    )
    begin{
    }
    process{
        $profilepath = get-childitem $profilepath -file -erroraction silentlycontinue
        if (-not $profilepath){
            throw "invalid profile path"
        }

        $null = Invoke-Command -Session $pssession -filepath $profilepath.fullname
        write-output $pssession

    }
    end{
    }
}

function Rename-FileExtension{
    param(
        [parameter(valuefrompipeline)]
        $File,

        [parameter(position=0)]
        [string]$NewExtension
    )
    begin{
    }
    process{

        $from = get-item $file -erroraction silentlycontinue

        if (-not $from -or -not $from.extension -or $from.psiscontainer){
            return
        }

        if (-not $newextension.startswith('.')){
            $newextension = ".$newextension"
        }

        $new = "$($from.directoryname)\$($from.basename)$newextension"

        rename-item $from.fullname $new -passthru -confirm:$false


    }
    end{
    }
}

function Get-WhereObjectProperty{
    param(
        [parameter(valuefrompipeline)]
        $Value,
        [switch]$Not
    )

    begin{
    }
    process{
        if ((-not $not -and $value) -or ($not -and -not $value)){
            $value
        }
    }
    end{
    }
}

function Invoke-CodeSearch {
    [CmdletBinding()]
    param(

        [parameter(position=0)]
        [string]$Regex,

        [parameter(position=1)]
        [string]$RootDirectory = ".",

        [parameter(position=2)]
        [string]$Exclude = $null,

        [switch]$NoFilter,

        [switch]$PathsOnly
    )
    
    begin{
    }
    process{
        $files = get-childitem $rootdirectory -include *.cs,*.vb, *.config,*.json,*.aspx,*.rdl,*html,*.csproj,*.vbproj,*.runsettings,*.ps1,*.psm1,*.js,*.jsx,*.ts,*.tsx,*.css,*.fsi,*.fsx,*.fsproj,*.sql,*.pls,*.pkb,*.pks,*.xml -recurse -exclude $exclude

        if (-not $nofilter){
            $files = $files | where fullname -notmatch '\\(obj|bin)\\' 
        }

        $output = $files | select-string $regex -allmatches
        if ($pathsonly){
            $output = $output | select-object path -unique
        }

        write-output $output

    }
    end{
    }
}

function Get-ResponseVariableScope{
    [CmdletBinding()] 
    param(
    )

#    $psstacktrace = get-pscallstack
##    foreach($a in $psstacktrace){
##        write-host ($psstacktrace |select *| fl|out-string)
##    }
##    write-host $myinvocation.scriptname
##    write-host $PSCommandPath
#
#    $leaf = split-path $pscommandpath -leaf
#
#    $lastlocation = $null
#    $scope = 0
#
#    foreach($level in $psstacktrace){
#        if ($level.scriptname -eq $pscommandpath){
#            continue
#        }
#
#        $location = $level.location -replace ':.*$'
#        if ($location -ne $lastlocation){
#            $scope++
#        }
#        $lastlocation = $location
#    }
#
#    write-output ($scope - 1)

    $psstacktrace = get-pscallstack
    $leaf = split-path $pscommandpath -leaf

    if ($psstacktrace.count -gt 2 -and $psstacktrace[2].location -and $psstacktrace[2].location.startswith("${leaf}:")){
        write-output 1
    }else{
        write-output 2
    }
}
function show-processwindow {
    param(
        [int]$handle
    )

    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Program {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

        $null = [Program]::SetForegroundWindow($handle)
}

function start-vim(){
    param(
        [parameter(valuefrompipeline=$true)]$File = $null,
        [parameter()][alias('serv','server')]$ServerName = "DEFAULT",
        [parameter()][validateset('gvim','vim')]$ServerType = "gvim",
        [switch]$Transparent,
        [switch]$NoWrap
    )

    begin{
        $filesString = ""
        $stop = $false
    }

    process{

        if ($stop){
            return
        }

        if (-not $file){
            return
        }

        if ($file -is [system.io.filesysteminfo]){
            $file = $file.fullname
        }

        if ( (test-path $file -pathtype container)){
            write-output "Directories not supported: $file"
            $stop = $true
            return
        }

        if (-not (test-path $file)){

            $null | set-content $file -errorvariable fileerror -erroraction silentlycontinue

            if ($fileerror){
                write-output "Failed: $file"
                $stop = $true
                return
            }

            $file = ls $file | select -expand fullname
            
        }
        
#        if ($file -is [system.io.fileinfo]){
#            $file = $file.fullname
#        }

        if ($file -and $file.contains(':')){
            if ($file -match '(?<drive>^[^:]{0,}:)(?<solidus>\\|/){0,}(?<file>.*$)'){
                if (-not (test-path $file)){
                    $null | set-content $file
                }
                $file = (convert-path "$($matches.drive)$($matches.solidus)$($matches.file)")
            }
        }

        $files = $null
        if ($file){

            if ($file -is [system.io.fileinfo]){
                $files = $file
            }else{
                if (test-path $file){
                    $files = ls $file -erroraction silentlycontinue
                }else{
                    try{
                        $files = [system.io.fileinfo]$file
                    }catch{
                        #ignore invalid file names
                    }
                }
            }


            foreach ($filepath in $files){
#                if ($filepath.fullname.toupper().startswith('C:\Windows\System32\WindowsPowerShell\v1.0\'.toupper()) -and (-not (convert-path .).toupper().startswith('C:\Windows\System32\WindowsPowerShell\v1.0\'.toupper()))){
#                    $filesString += ('"' + ($filepath.fullname -replace 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0',(convert-path .)) + '" ')
#                }else{
                    $filesString += ('"' + $filepath.fullname + '" ')
#                }
            }
        }
    }

    end{

        if ($stop){
            return
        }

        $Servername = $Servername.toupper()

#        $process = get-process gvim -erroraction silentlycontinue | where {$_.commandline -match "--servername ""$Servername"""} -erroraction silentlycontinue
        $process = get-process $servertype -erroraction silentlycontinue | where {$_.mainwindowtitle -match " - $Servername`$"} -erroraction silentlycontinue

        if ($process){

            if ($nowrap){
                $noWrapCommand = '--remote-send ":setlocal nowrap<CR>"'
            }


            if ($filesstring.trim().length -eq 0){
                $startProcess = (start-process tools:\vim\$servertype.exe -args "--servername ""$Servername"" --remote-send "":enew<CR>"" $nowrapcommand" -windowstyle normal -passthru -erroraction silentlycontinue -confirm:$false)
            }else{
                $startProcess = (start-process tools:\vim\$servertype.exe -args "--servername ""$Servername"" $nowrapcommand --remote-silent $filesstring" -windowstyle normal -passthru -erroraction silentlycontinue -confirm:$false)
#                "(start-process tools:\vim\$servertype.exe -args ""--servername ""$Servername"" $nowrapcommand --remote-silent $filesstring"" -windowstyle normal -passthru -erroraction silentlycontinue -confirm:$false)"

                if ($nowrapcommand){
                    $startProcess = (start-process tools:\vim\$servertype.exe -args "--servername ""$Servername"" $nowrapcommand " -windowstyle normal -passthru -erroraction silentlycontinue -confirm:$false)
                }
            }
            $startProcess.commandline
#            get-processcommandline $startprocess.id
        }else{

            if ($nowrap){
                $noWrapCommand = '-c "setlocal nowrap"'
            }
            if ($script:vimrcdirectory){
                $vimRcPathCommand = "-c ""set rtp=$(convert-path $script:vimrcdirectory)\vimfiles | set rtp+=$(convert-path tools:\vim) | source $(convert-path $script:vimrcdirectory)\_vimrc "" "
            }

            if ($filesstring.trim().length -eq 0){
                $process = start-process tools:\vim\$servertype.exe -args "$vimrcpathcommand --servername ""$Servername"" $nowrapcommand" -windowstyle normal -passthru -erroraction silentlycontinue -confirm:$false
#write-verbose (Get-ProcessCommandLine $process.id)
            }else{
#                $process = start-process tools:\vim\gvim.exe -args "--servername ""$Servername"" --remote-silent $filesstring " -windowstyle normal -passthru -erroraction silentlycontinue
                $process = start-process tools:\vim\$servertype.exe -args "$vimrcpathcommand --servername ""$Servername"" $nowrapcommand $filesstring" -windowstyle normal -passthru -erroraction silentlycontinue -confirm:$false
#write-verbose (Get-ProcessCommandLine $process.id)
            }

            $process.commandline
#            get-processcommandline $startprocess.id
            
            if ($Transparent){
                for ($x = 1;$x -le 500; $x++){
                    $process = get-process -id $process.id -erroraction silentlycontinue
                    if (-not $process){
                        break
                    }
                    if ($process.MainWindowTitle){
                        [void]($process | set-windowtransparency)
                        break
                    }
                }
            }
        }

#        if ($host.name -eq 'ConsoleHost' -and $host.version.major -lt 6){
#            add-nativehelpertype
#            [nativehelper]::bringwindowtofront($process.mainwindowhandle)
#        }
         if (test-path function:\show-processwindow){
#            start-process $bringtofrontexe -args $process.mainwindowhandle -confirm:$false
            show-processwindow $process.mainwindowhandle
         }

    }
}

function Clear-KeePass{
    $script:keepassCache = $null
}

function Get-KeePass{
    [cmdletbinding()]
    param(
        [parameter(position=0)]
        [string]$KdbxFilePath = 'Tools:\keepass\passwords.kdbx',

        [switch]$Fetch
    )

    if ($fetch){

        $csv = tools:\keepass\keepassxc-cli.exe export -f csv "$(convert-path $kdbxfilepath)" | convertfrom-csv | where {$_.group -eq "Root/passwords"}
        if (-not $csv){
            return
        }

        $hash = [ordered]@{}

        foreach($record in $csv){

            $name = $record.title -replace '[^a-zA-Z0-9]',"_"
            $name = $name.trim()

            $username = $record.username.trim()
            $pass = $record.password | ConvertTo-SecureString -AsPlainText -force
            $url = $record.url.trim()

            $credential = $null
            $note = $null

            try{
                $credential = [pscredential]::new($username,$pass)
            }catch{
                $note = "could not map credential object"
                write-warning $note
            }

            $value = [pscustomobject]@{
                credential = $credential
                url = $url
                note = $note
            }
            $hash.add($name, $value)
        }

        $script:keepassCache = [pscustomobject]$hash
    }


    $script:keepassCache
}

function new-password{
    [cmdletbinding()]

    param(
        [parameter(position=0)]
        [validaterange(5, 50)]
        [int] $Length = 22
    )

    tools:\keepass\keepassxc-cli.exe generate --length $length --every-group --lower --upper --numeric --special
}

function new-passphrase{
    [cmdletbinding()]

    param(
        [parameter(position=0)]
        [validaterange(1, 10)]
        [int] $WordCount = 5
    )

    tools:\keepass\keepassxc-cli.exe diceware --words $wordcount
}

function Open-WindowsExplorer {
    param(
        [parameter(position=0)]
        [string] $Directory = ".\"
    )

    process{
        $dir = convert-path $directory -ea 0
        if ($dir -eq $null -or -not (test-path -pathtype container $directory)){
            "invalid directory"
            return
        }

        explorer $dir
    }
}

function Open-VimforText{
    [cmdletbinding()]

    param(
        [parameter(valuefrompipeline)]
        [string[]] $Text,

        [parameter(position=0)]
        [string] $FileExtension = "txt",

        [parameter(position=1)]
        [string] $ServerName = "OV"
    )

    begin{
        $stringbuilder = [system.text.stringbuilder]::new()
    }

    process{
        $null = $stringbuilder.appendline($text)
    }

    end{
        if ($stringbuilder.length -eq 0){
            return
        }
        
        remove-item "$([system.io.path]::gettemppath())*__ov__.*" -confirm:$false

        $tmpfilename = "$([system.io.path]::GetTempFileName())__ov__.$fileextension" 

        $tmpfile = $stringbuilder.tostring() | set-content -path $tmpfilename -confirm:$false 
        $tmpfilename

        $null = start-vim $tmpfilename -servername $servername
    }

}

function Get-Type{
    [cmdletbinding()]

    param(
        [parameter(valuefrompipeline)]
        [psobject] $Object
    )

    process{
        $object.gettype()
    }
}

function ConvertFrom-Xml{
    [cmdletbinding()]

    param(
        [parameter(valuefrompipeline)]
        [psobject] $Object
    )

    process{
        [xml]$object
    }
}

function ConvertTo-PsCustomObject{
    param(
        [parameter(valuefrompipeline)]
        [hashtable]$HashTable
    )

    [pscustomobject]$hashtable
}

function New-SelectArgument{
    param(
        [parameter(mandatory,position=0)]
        [string]$Label,

        [parameter(mandatory,position=1)]
        [scriptblock]$Scriptblock
    )

    @{label=$label;ex=$scriptblock}
}

function Rename-Stripped{
    [cmdletbinding()]

    param(
        [parameter(mandatory,valuefrompipeline)]
        [System.IO.FileInfo]$File, 
        
        [switch]$Quiet
    )

    process{
        $basename = $file.basename.tolower().trim() -replace "[\.-]*$"
        $basename = $basename -replace "\s+", '-'
        $extension = $file.extension.tolower().trim()
        $name = "$basename$extension"

        if (([string]::compare($file.name, $name)) -eq 0){
            return
        }

        rename-item $file "$basename$extension" -confirm:(-not $quiet)
    }
}

#function Format-FlatObject{
#    param(
#        [parameter(valuefrompipeline,mandatory)]
#        [object]$FlatObject,
#
#        [parameter()]
#        [int]$SortIndexPadding = 3,
#
#        [switch]$WithColor,
#        [switch]$ExcludeValue,
#        [switch]$Sort
#    )
#
#    begin{
#        $oldRendering = $PSStyle.OutputRendering
#
#
#write-host ([console]::isoutputredirected)
#        if ($IsOutputRedirected) {
#            $PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText
#        }
#    }
#
#    process{
#        $gm = $flatobject.psobject.properties
#
#        
#        if ($sort){
#            $sortedgm = @($gm | select-object name,value)
#            for ($idx = 0; $idx -lt $sortedgm.count;$idx++){
#                1..($Sortindexpadding - 1) | foreach-object {
#                    $sortedgm[$idx].name = $sortedgm[$idx].name -replace "(?<=\[)(\d{$_})(?=])", (("0" * ($Sortindexpadding - $_)) + '$1')
#                }
#            }
#            $gm = $sortedgm | sort name
#        }
##        if (-not $withcolor){
##            $keycolor = ""
##            $equalcolor = ""
##            $valuecolor = ""
##        }else{
#            $keycolor = $psstyle.formatting.tableheader
#            $equalcolor = $psstyle.foreground.yellow
#            $valuecolor = $psstyle.foreground.white
##        }
#        foreach($rec in $gm){
#            $key = "$keycolor$($rec.name)"
#
#            if ($excludevalue){
#                $value = ""
#            }else{
#                $value = "$equalcolor = $valuecolor$($rec.value)"
#            }
#            "$key$value$reset"
#        }
#    }
#    end{
#        $PSStyle.OutputRendering = $oldRendering
#    }
#}

Function ConvertTo-FlatObject {
    <#
    .SYNOPSIS
    Flattens a nested object into a single level object.
    .DESCRIPTION
    Flattens a nested object into a single level object.
    .PARAMETER Objects
    The object (or objects) to be flatten.
    .PARAMETER Separator
    The separator used between the recursive property names
    .PARAMETER Base
    The first index name of an embedded array:
    - 1, arrays will be 1 based: <Parent>.1, <Parent>.2, <Parent>.3, …
    - 0, arrays will be 0 based: <Parent>.0, <Parent>.1, <Parent>.2, …
    - "", the first item in an array will be unnamed and than followed with 1: <Parent>, <Parent>.1, <Parent>.2, …
    .PARAMETER Depth
    The maximal depth of flattening a recursive property.
    .NOTES
    From https://evotec.xyz/powershell-converting-advanced-object-to-flat-object/
    Based on https://powersnippets.com/convertto-flatobject/
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeLine)][Object[]]$Objects,
        [alias('s')]
        [String]$Separator = ".",

        [ValidateSet("", 0, 1)]$Base = 0,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ $_ -ge 0 })]
        [alias('d')]
        [int] $Depth = 10,

        [parameter()]
        [int]$SortIndexPadding = 6,

        [parameter()]
        [alias('n')]
        [string]$Name = $null,

        [parameter()]
        [alias('p')]
        [string]$PropertyForName = $null,

        [Parameter(DontShow)][String[]]$Path,
        [Parameter(DontShow)][System.Collections.IDictionary] $OutputObject
    )
    Begin {
        $InputObjects = [System.Collections.Generic.List[Object]]::new()
            $basecount = 0
    }
    Process {
        foreach ($O in $Objects) {
            

            #special case where flattening something without properties - e.g. an array of numbers
            if ($path -eq $null -and (${o}?.GetType().isprimitive -or ${o}?.GetType().isenum)) {
                $o = @{"__base_value[$($basecount)]" = $o}
                $basecount++
            }

            #xml doesn't flatten well unless converted
            if (${o}?.GetType().Name -in 'XmlElement', 'XmlDocument', 'XmlNode', 'XmlLinkedNode') {
                $o = $o | convertto-jsonfromxml
            }

            #jobject doesn't flatten at all. first encountered in an azure logic app object
            elseif($o -is [Newtonsoft.Json.Linq.JObject]){
                try{
                $o = $o.tostring() | convertfrom-json -depth $depth
                }catch{
                    write-information "error converting JObject from json. Retrying AsHashTable.."
                    $o = $o.tostring() | convertfrom-json -depth $depth -ashashtable
                }
            }
            #jvalue doesn't flatten at all. first encountered in an azure logic app object
            elseif($o -is [Newtonsoft.Json.Linq.JValue]){
                $o = $o.value
            }

            #skip if null
            if ($o -eq $null){
                continue
            }

            #add to objects to evaluate
            $InputObjects.Add($O)
        }
    }
    End {
        
        #not the first level of execution nest
        If ($PSBoundParameters.ContainsKey("OutputObject")) {
            $Object = $InputObjects[0]
            $Iterate = [ordered] @{}


            #if object is null, then it can be 
            if ($null -eq $Object) {

           #don't flatten certain objects where the short version is preferable
           } elseif ($Object.GetType().isenum) {
                $Object = $Object.ToString()
           } elseif ($Object.GetType().Name -in 'String', 'DateTime', 'DateTimeOffset', 'TimeSpan', 'Version') {
                $Object = $Object.ToString()
           }

           #flatten to the specified depth
           elseif ($Depth) {
                $Depth--

                #take as is for dictionary
                If ($Object -is [System.Collections.IDictionary]) {
                    $Iterate = $Object

                #take as is for dictionary
                }elseif ($object -is [Newtonsoft.Json.Linq.JObject]){
                    $Iterate = $Object

                #modify name for array depth and assign the value
                }elseif ($Object -is [Array] -or $Object -is [System.Collections.IEnumerable]) {
                    $i = $Base

                    foreach ($Item in $Object.GetEnumerator()) {
                        $Iterate["[$i]"] = $Item
                        $i += 1
                    }
                }

                #assign the values for each property
                else {
                    foreach ($Prop in $Object.PSObject.Properties) {
                        if ($Prop.IsGettable) {
                            $Iterate["$($Prop.Name)"] = $Object."$($Prop.Name)"
                        }
                    }
                }
            }

            #"keys" may be the name of a property, use psbase to ensure that we're iterating through hashtable keys
            If ($Iterate.psbase.Keys.Count) {

                #flatten each iteration
                foreach ($Key in $Iterate.psbase.Keys) {
                    ConvertTo-FlatObject -Objects @(, $Iterate[$Key]) -Separator $Separator -Base $Base -Depth $Depth -Path ($Path + $Key) -OutputObject $OutputObject -sortIndexPadding $sortindexpadding
                }

            #already flat, set the output
            } else {
                $Property = $Path -Join $Separator

                #remove separator before array values
                $Property = $property -replace "$([regex]::escape($separator))\[",'['

                #set empty value for empty dictionary
                if ($object -is [system.collections.idictionary] -and $object.psbase.keys.count -eq 0){
                    $OutputObject[$Property] = ""

                #set empty value for empty array
                }elseif (($object -is [array] -or $object -is [system.collections.ienumerable]) -and @($object).count -eq 0){
                    $OutputObject[$Property] = ""

                #set string representation of value
                }else{
                    $OutputObject[$Property] = ${Object}?.tostring()
                }
            }
        }

        #entry point
        elseif ($InputObjects.Count -gt 0) {

            $rootidx = -1

            #flatten each object
            foreach ($ItemObject in $InputObjects) {

                if ($itemobject -eq $null){
                    continue
                }

                $rootidx++

                #default name
                $rootname = $name

                if ([string]::isnullorempty($rootname)){
                    $rootname = $rootidx.tostring()
                }

                if (-not ([string]::isnullorempty($propertyforname))){
                    $rootname = $itemobject."$propertyforname"?.tostring() ?? $rootname
                }

                $OutputObject = [ordered]@{}
                ConvertTo-FlatObject -Objects @(, $ItemObject) -Separator $Separator -Base $Base -Depth $Depth -Path $Path -OutputObject $OutputObject -sortIndexPadding $sortindexpadding

                #error will occur below if the flattening did nothing
                $props = ([pscustomobject]$outputobject).psobject.properties

                #sorting the properties helps in viewing the output 
                $sortedprops = @($props | select-object name,value)

                #left pad array element values so that they can be sorted numerically
                for ($idx = 0; $idx -lt $sortedprops.count;$idx++){
                    1..($Sortindexpadding - 1) | foreach-object {
                        $sortedprops[$idx].name = $sortedprops[$idx].name -replace "(?<=\[)(\d{$_})(?=])", (("0" * ($Sortindexpadding - $_)) + '$1')
                    }
                }

                #remove the padded zeroes
                for ($idx = 0; $idx -lt $sortedprops.count;$idx++){
                    $sortedprops[$idx].name = $sortedprops[$idx].name -replace "(?<=\[)(?<asdf>0+)(?=\d+])"
                }

                #return output
                foreach($prop in $sortedprops){
                    [pscustomobject]@{
                        pstypename = 'NZ.FlatObject.Entry'
                        name = $rootname.trim()
                        key = $prop.Name
                        equals = "="
                        value = $prop.Value
                    }
                }

            }
        }
    }
}


#vibe coded, not reviewed
function ConvertTo-NoNullsObject {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [Parameter(ValueFromPipeline)]
        [object] $InputObject
    )

    begin{
        # Helper: treat "empty" nodes as removable
        function Test-IsEmptyNode([object]$v) {
            if ($null -eq $v) { return $true }

            # Empty dictionary / hashtable
            if ($v -is [System.Collections.IDictionary]) {
                return $v.Count -eq 0
            }

            # Empty arrays / lists (covers arrays and many collections)
            if ($v -is [System.Collections.ICollection] -and $v -isnot [string]) {
                return $v.Count -eq 0
            }

            # Property-less custom objects (key missing piece)
            if ($v -is [System.Management.Automation.PSCustomObject]) {
                # Use PSObject.Properties enumeration to detect "no properties"
                return -not $v.psobject.Properties.GetEnumerator().MoveNext()
            }

            return $false
        }
    }

    process {
        if ($null -eq $InputObject) { return $null }

        # Leaf scalars
        if ($InputObject -is [string] -or $InputObject.GetType().IsPrimitive) {
            return $InputObject
        }

        # Dictionaries
        if ($InputObject -is [System.Collections.IDictionary]) {
            $out = @{}
            foreach ($k in $InputObject.Keys) {
                $child = ConvertTo-NoNullsObject -InputObject $InputObject[$k]
                if (-not (Test-IsEmptyNode $child)) {
                    $out[$k] = $child
                }
            }
            return $out
        }

        # Arrays (preserve nesting)
        if ($InputObject -is [array]) {
            $out = @()
            foreach ($item in $InputObject) {
                $child = ConvertTo-NoNullsObject -InputObject $item
                if (-not (Test-IsEmptyNode $child)) {
                    # unary comma suppresses enumeration/unrolling when adding
                    $out += ,$child
                }
            }
            return ,$out
        }

        # Other IEnumerable collections (optional support, still preserves nesting)
        if ($InputObject -is [System.Collections.IEnumerable] -and
            $InputObject -isnot [string] -and
            $InputObject -isnot [System.Collections.IDictionary]) {

            $out = @()
            foreach ($item in $InputObject) {
                $child = ConvertTo-NoNullsObject -InputObject $item
                if (-not (Test-IsEmptyNode $child)) {
                    $out += ,$child
                }
            }
            return ,$out
        }

        # Objects / PSCustomObject: prune null-valued properties
        $acc = [ordered]@{}
        foreach ($p in $InputObject.PSObject.Properties) {
            if ($null -eq $p.Value) { continue }

            $child = ConvertTo-NoNullsObject -InputObject $p.Value
            if (-not (Test-IsEmptyNode $child)) {
                $acc[$p.Name] = $child
            }
        }

        $obj = [pscustomobject]$acc

        # If it became property-less, return an empty custom object
        # (caller will drop it if needed)
        return $obj
    }
}


function Get-ProxyFunction{
    [cmdletbinding()]
    param(
        [string]$Function
    )
    process{
        $f = Get-Command $function
        $m = [System.Management.Automation.CommandMetaData]::new($f)
        [System.Management.Automation.ProxyCommand]::Create($m)
    }
}




function ConvertTo-UnixPath{
    param(
        [parameter(valuefrompipeline)]$Path
    )
    begin{
    }
    process{
        $a = convert-path $path
        $a = $a -replace '\\','/'
        $a = $a -replace ' ','\ '
        $a = $a -replace '\(','\('
        $a = $a -replace '\)','\)'
        $a
    }
    end{
    }
}

function ConvertTo-WslPath{
    param(
        [parameter(valuefrompipeline)]$Path
    )
    begin{
    }
    process{
        $onedrivepath = $env:onedrive -replace '\\','\\'
        $onedrivepath = $onedrivepath -replace '\\\\$'
        $onedrivepathregex = [regex]::escape($onedrivepath)

        $a = convert-path $path
        $a = $a -replace "^$onedrivepathregex\\", '~/onedrive/'
        $a = convertto-unixpath $a
        $a = $a -replace '^c:', '/mnt/c'
        $a
    }
    end{
    }
}

function Start-Vd{
    [cmdletbinding()]
    param(
        [parameter(valuefrompipeline)]
        $Path,

        [parameter(position=0)]
        [validateset('arrow', 'arrows', 'csv', 'dot', 'dta', 'eml', 'fixed', 'frictionless', 'geojson', 'hdf5', 'html', 'jira', 'json', 'jsonl', 'lsv', 'mbtiles', 'md', 'mysql', 'npy', 'ods', 'pandas', 'parquet', 'pbf', 'pcap', 'pdf', 'png', 'postgres', 'pyprof', 'rec', 'sas7bdat', 'sav', 'shp', 'spss', 'sqlite', 'tar', 'tsv', 'ttf', 'usv', 'vcf', 'vd', 'vds', 'xls', 'xlsb', 'xlsx', 'xml', 'xpt', 'yaml', 'zip')]
        [string]$Type,

        [parameter()]$AdditionalOptions = $null,
        [parameter()]$Window = 2
    )

    begin{
    }

    process{
#
#~/.visidatarc
#
#globalCommand('gm', 'enable mouse events', 'mm, _ = curses.mousemask(-1); status("mouse "+("ON" if mm else "OFF"))')
#globalCommand('zm', 'disable mouse events', 'mm, _ = curses.mousemask(0); status("mouse "+("ON" if mm else "OFF"))')


        if ($path){
            $wslpath = $path | convertto-wslpath

            if (-not $type){
                $type = @('arrow', 'arrows', 'csv', 'dot', 'dta', 'eml', 'fixed', 'frictionless', 'geojson', 'hdf5', 'html', 'jira', 'json', 'jsonl', 'lsv', 'mbtiles', 'md', 'mysql', 'npy', 'ods', 'pandas', 'parquet', 'pbf', 'pcap', 'pdf', 'png', 'postgres', 'pyprof', 'rec', 'sas7bdat', 'sav', 'shp', 'spss', 'sqlite', 'tar', 'tsv', 'ttf', 'usv', 'vcf', 'vd', 'vds', 'xls', 'xlsb', 'xlsx', 'xml', 'xpt', 'yaml', 'zip') | where {$wslpath -match "\.$_$"}
            }

        }else{
            $wslpath = $null
        }
        if ($type){

            $sb = [scriptblock]::create("wt -w $window -p tumbleweed wsl.exe -d tumbleweed2 --% ~/python-venv/bin/vd $wslpath --filetype $type --clipboard-copy-cmd=clip.exe --quitguard --undo $($additionaloptions -replace "'","\'")")
            $sb.tostring()
            $sb.invoke()

        }else{
            $sb = [scriptblock]::create("wt -w $window -p tumbleweed wsl.exe -d tumbleweed2 ~/python-venv/bin/vd $wslpath --clipboard-copy-cmd=clip.exe --quitguard--header=0 --undo $($additionaloptions -replace "'","\'")'")
            $sb.tostring()
            $sb.invoke()
        }
    }
    end{
    }
}

function out-vd{
    [cmdletbinding()]
    param(
        [parameter(valuefrompipeline)]$Data,

        [validateset('arrow', 'arrows', 'csv', 'dot', 'dta', 'eml', 'fixed', 'frictionless', 'geojson', 'hdf5', 'html', 'jira', 'json', 'jsonl', 'lsv', 'mbtiles', 'md', 'mysql', 'npy', 'ods', 'pandas', 'parquet', 'pbf', 'pcap', 'pdf', 'png', 'postgres', 'pyprof', 'rec', 'sas7bdat', 'sav', 'shp', 'spss', 'sqlite', 'tar', 'tsv', 'ttf', 'usv', 'vcf', 'vd', 'vds', 'xls', 'xlsb', 'xlsx', 'xml', 'xpt', 'yaml', 'zip')]
        [parameter(mandatory,position=0)]$Type = 'csv',

        [parameter(position=1)]$Window = 3,

        [switch]$NoConversion,
        [switch]$AsByteStream
    )

    begin{
        $alldata = [system.collections.generic.list[object]]::new()
        $isXmlType = $false
    }

    process{
#        if ($data -is [System.Xml.XmlElement]){
#            $isXmlType = $true
#        }
        $alldata.add($data)
    }
    end{


        #clean up tmp files from before today
        if (-not $nopurge){
            $files = get-childitem "$([System.IO.Path]::GetTempPath())out-vd.*.*" -erroraction silentlycontinue 

            $files | where {$_.lastwritetime.date -lt (get-date).date} | remove-item -confirm:$false
        }

        $files = get-childitem "$([System.IO.Path]::GetTempPath())out-vd.*.*" -erroraction silentlycontinue | select -expand name | select-string '(?<=^out-vd\.)[^\.]{1,}' | select -expand matches | select -expand value

        if (-not $files){
            $number = 0
        }else{
            $number = $files | measure -max | select -expand maximum
        }

        $number += 1

        $tmpfile = [System.IO.Path]::GetTempPath() + "out-vd.$number.$type"

        $exported = $false
        if (-not $asbytestream -and -not $noconversion){
            switch ($type){
                
                'xml' {
#                    if ($isxmltype){
                        "<vd-root>$($alldata.outerxml)</vd-root>" | set-content $tmpfile -confirm:$false
                        $exported = $true
                        break
#                    }
                }

                default {
                    $alldata | export-csv $tmpfile -confirm:$false
                    $exported = $true
                    break
                }
            }
        }

        if (-not $exported){
            $alldata | set-content $tmpfile -asbytestream:$asbytestream -confirm:$false
        }

#        $outdata|out-string -width ([int]::maxvalue) | wsl vd --filetype $type
         start-vd -path $tmpfile -type $type -window $window
    }
}

function ConvertFrom-JwtToken {
    <#
    .SYNOPSIS
        Decodes a JWT (JWS) into Header and Payload objects (and signature info).
    .DESCRIPTION
        - Splits token into 3 parts: header.payload.signature
        - Base64URL-decodes header and payload, parses JSON
        - Returns a rich object with raw and parsed values
        - NOTE: This does NOT validate the signature.
    .PARAMETER Token
        The JWT string.
    .EXAMPLE
        $jwt = $env:ACCESS_TOKEN
        $decoded = Decode-JwtToken -Token $jwt
        $decoded.Payload
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Token
    )

    begin {
        function ConvertFrom-Base64Url {
            param([Parameter(Mandatory)][string]$in)

            # Base64Url -> Base64
            $b64 = $in.Replace('-', '+').Replace('_', '/')

            # Pad to 4-char boundary
            switch ($b64.Length % 4) {
                2 { $b64 += '==' }
                3 { $b64 += '=' }
                0 { }
                default { throw "Invalid Base64Url string length." }
            }

            [System.Convert]::FromBase64String($b64)
        }

        function ConvertTo-Base64Url {
            param([Parameter(Mandatory)][byte[]]$Bytes)

            [System.Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
        }
    }

    process {
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw "Token cannot be empty."
        }

        # Trim common "Bearer " prefix if user passed it in
        $t = $Token.Trim()
        if ($t -match '^\s*Bearer\s+') { $t = ($t -replace '^\s*Bearer\s+','').Trim() }

        $parts = $t.Split('.')
        if ($parts.Count -ne 3) {
            throw "Invalid JWT format. Expected 3 dot-separated segments (header.payload.signature)."
        }

        $headerBytes  = ConvertFrom-Base64Url -In $parts[0]
        $payloadBytes = ConvertFrom-Base64Url -In $parts[1]
        $sigBytes     = ConvertFrom-Base64Url -In $parts[2]

        $headerJson  = [System.Text.Encoding]::UTF8.GetString($headerBytes)
        $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)

        $headerObj  = $headerJson  | ConvertFrom-Json
        $payloadObj = $payloadJson | ConvertFrom-Json

        # Helpful time conversion if exp/nbf/iat exist (Unix seconds)
        $toDateTime = {
            param($unixSeconds)
            try {
                if ($null -ne $unixSeconds -and $unixSeconds -is [ValueType]) {
                    return [DateTimeOffset]::FromUnixTimeSeconds([int64]$unixSeconds).ToLocalTime()
                }
            } catch {}
            return $null
        }

        $exp = $null; $nbf = $null; $iat = $null
#        if ($payloadObj.PSObject.Properties.Name -contains 'exp') { $exp = & $toDateTime $payloadObj.exp }
#        if ($payloadObj.PSObject.Properties.Name -contains 'nbf') { $nbf = & $toDateTime $payloadObj.nbf }
#        if ($payloadObj.PSObject.Properties.Name -contains 'iat') { $iat = & $toDateTime $payloadObj.iat }
        
        if ($payloadObj.exp -ne $null){ $payloadobj.exp = & $toDateTime $payloadObj.exp}
        if ($payloadObj.nbf -ne $null){ $payloadobj.nbf = & $toDateTime $payloadObj.nbf}
        if ($payloadObj.iat -ne $null){ $payloadobj.iat = & $toDateTime $payloadObj.iat}
        $payloadobj

#        [pscustomobject]@{
#            Token              = $t
#            HeaderRaw          = $headerJson
#            PayloadRaw         = $payloadJson
#            Header             = $headerObj
#            Payload            = $payloadObj
#            SignatureBytes     = $sigBytes
#            SignatureBase64Url = $parts[2]
#            SignatureBase64    = [System.Convert]::ToBase64String($sigBytes)
#
#            # Common claim helpers (nullable)
#            Alg                = $headerObj.alg
#            Kid                = $headerObj.kid
#            Iss                = $payloadObj.iss
#            Aud                = $payloadObj.aud
#            Sub                = $payloadObj.sub
#            ExpUnix            = $payloadObj.exp
#            NbfUnix            = $payloadObj.nbf
#            IatUnix            = $payloadObj.iat
#            ExpLocal           = $exp
#            NbfLocal           = $nbf
#            IatLocal           = $iat
#        }
    }
}

function Select-HashTableKey{
    [cmdletbinding()]
    param(
        [parameter(mandatory,valuefrompipeline)]
        [hashtable]$HashTable,

        [parameter(mandatory,position=0)]$Key
    )

    process{
        $hashtable[$key]
    }
}

Update-TypeData -PrependPath "$PSScriptRoot\formatting-files\profile-module.type.ps1xml"
Update-FormatData -PrependPath "$PSScriptRoot\formatting-files\profile-module.format.ps1xml"


