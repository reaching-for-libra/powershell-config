
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
