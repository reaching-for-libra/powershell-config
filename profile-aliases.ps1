
$unwantedAliases = @(
    'si'
)

foreach ($a in $unwantedAliases){
    remove-item "alias:\${a}" -force -confirm:$false
}

$aliases = @{
    cat = 'get-content'
    grep = 'select-string'
    ls = 'get-childitem'
    ps = 'get-process'
    rm = 'remove-item'
    rmdir = 'remove-item'
    sort = 'sort-object'
    s = 'select-object'
    #join = 'join-string'
    cred = 'get-credential'
    which = 'get-command'
    cp = 'copy-item'
    mv = 'move-item'
    clip = 'set-clipboard'
    tojson = 'convertto-json'
    fromjson = 'convertfrom-json'
    void = 'out-null'
    gclip = 'get-clipboard'

    #custom functions
    split = 'profile-module\split-string'
    cf = 'profile-module\get-function'
    gg = 'profile-module\get-grepmatchvalues'
    nsum = 'profile-module\convert-numberstringtosum'
    zcat = 'profile-module\Read-ZippedFile'
    j = 'profile-module\Join-Collections'
    ldap = 'profile-module\Get-LdapObject'
    getbytes = 'profile-module\ConvertTo-ByteArray'
    ogrep = 'profile-module\Search-ObjectProperties'
    whereis = 'profile-module\Get-WhereObjectProperty'
    vim = 'profile-module\Start-Vim'
    git = 'C:\Users\nzeleski\AppData\Local\Programs\Git\bin\git.exe'
    amp = 'profile-module\Invoke-Execute'
    capitalize = 'profile-module\Invoke-Capitalization'
    codegrep = 'profile-module\Invoke-CodeSearch'
    deepclone = 'profile-module\Invoke-DeepClone'
    e = 'profile-module\Invoke-ForEachExpand'
    fls = 'profile-module\Format-ListSorted'
    gdif = 'profile-module\Invoke-GitDiff'
    vdif = 'profile-module\Invoke-VimDiff'
    hascount = 'profile-module\Get-HasCount'
    lsod = 'profile-module\Get-LastFromDirectory'
    od = 'profile-module\Invoke-SortLastWriteTime'
    salias = 'profile-module\New-SelectAlias'
    re = 'profile-module\ConvertTo-RegexEscape'
    replace = 'profile-module\Invoke-ReplaceText'
    t = 'profile-module\Invoke-TeeVariable'
    trim = 'profile-module\Invoke-Trim'
    we = 'profile-module\Open-WindowsExplorer'
    ov = 'profile-module\Open-VimforText'
    pso = 'profile-module\ConvertTo-PsCustomObject'
    nsa = 'profile-module\New-SelectArgument'
    fromxml = 'profile-module\ConvertFrom-Xml'
    flatten = 'profile-module\ConvertTo-FlatObject'
    nonulls = 'profile-module\convertto-nonullsobject'
    vd = 'profile-module\start-vd'
    ovd = 'profile-module\out-vd'
    skey = 'profile-module\select-hashtablekey'
    jwt = 'profile-module\convertfrom-jwttoken'

    #Dataverse
    dnew = 'dataverse\new-dataversesession'
    dremove = 'dataverse\remove-dataversesession'
    dsessions = 'dataverse\get-dataversesessions'
    dport = 'dataverse\set-dataverselocalhostport'
    ddata = 'dataverse\invoke-dataverseodatarequest'
    dtables = 'dataverse\get-dataverseentities'
    dtable = 'dataverse\get-dataverseentity'
    dfield = 'dataverse\get-dataverseentityfields'
    drel = 'dataverse\get-dataverseentityrelationships'

    #orderful
    orderful = 'orderful\get-orderfultransactions'

    #queryhub
    SAdd = 'queryhub\Add-SqlServerQueryHubConnection'
    SCode = 'queryhub\Get-SqlServerDefinition'
    SCodes = 'queryhub\Get-SqlServerCodeNames'
    SConnections = 'queryhub\Get-SqlServerQueryHubConnections'
    SDef = 'queryhub\Get-SqlServerDefinition'
    SGetDefault = 'queryhub\Get-SqlServerDefaultQueryHubConnection'
    SJobs = 'queryhub\Get-SqlServerJobs'
    SLastMessage = 'queryhub\Get-LastSqlServerMessages'
    SLastRequest = 'queryhub\Get-LastSqlServerQueryRequest'
    SLastTime = 'queryhub\Get-LastSqlServerQueryTime'
    SRemove = 'queryhub\Remove-SqlServerQueryHubConnection'
    SSession = 'queryhub\Get-SqlServerSession'
    SSet = 'queryhub\Set-SqlServerDefaultQueryHubConnection'
    SSql = 'queryhub\Invoke-SqlServerQuery'
    STable = 'queryhub\Get-SqlServerTableSchema'
    STables = 'queryhub\Get-SqlServerTableNames'
    STest = 'queryhub\Test-SqlServerConnection'
    sLastError = 'queryhub\Get-LastSqlServerQueryError'
    sfile = 'queryhub\Invoke-sqlserverQueryFromFile'
    ss = 'queryhub\invoke-sqlserverscript'
    sslist = 'queryhub\get-sqlserverscripts'
}

foreach ($key in $aliases.keys){
    if (test-path "alias:$key"){
        remove-item "alias:$key" -confirm:$false -force
    }
    if (-not (get-command $aliases[$key] -ea 0)){
        write-warning "alias '$key' skipped because command '$($aliases[$key])' doesn't exist"
        continue
    }
    new-alias -name $key -value $aliases[$key] -confirm:$false
}

#automatic variables
if (-not ("NZ.PSScriptVariable" -as [type])) {
    Add-Type @"
    using System;
    using System.Collections.ObjectModel;
    using System.Management.Automation;

    namespace NZ
    {
        public class PSScriptVariable : PSVariable
        {
            public PSScriptVariable(string name, ScriptBlock scriptGetter, ScriptBlock scriptSetter) : base(name, null, ScopedItemOptions.AllScope) {
                getter = scriptGetter;
                setter = scriptSetter;
            }

            private ScriptBlock getter;
            private ScriptBlock setter;

            public override object Value {
                get {

                    if(getter != null) {

                        Collection<PSObject> results = getter.Invoke();

                        if(results.Count == 1) {
                            return results[0];

                        } else {
                            PSObject[] returnResults = new PSObject[results.Count];
                            results.CopyTo(returnResults, 0);
                            return returnResults;
                        }
                    } else { 
                        return null; 
                    }
                }
                set {
                    if(setter != null) { setter.Invoke(value); }
                }
            }
        }
    }
"@
}

if(Test-Path variable:\keepass) {
    Remove-Item variable:\keepass -Force
}
$executioncontext.SessionState.PSVariable.Set([NZ.PSScriptVariable]::new('Keepass',{@(get-keepass)},$null))

if(Test-Path variable:\SConnection) {
    Remove-Item variable:\SConnection -Force
}
$executioncontext.SessionState.PSVariable.Set([NZ.PSScriptVariable]::new('SConnection',{@(queryhub\get-sqlserverconnectionsession)},$null))

if(Test-Path variable:\slast) {
    Remove-Item variable:\slast -Force
}
$executioncontext.SessionState.PSVariable.Set([NZ.PSScriptVariable]::new('SLast',{@(get-lastsqlserverqueryresult)},$null))

if(Test-Path variable:\azurecontext) {
    Remove-Item variable:\azurecontext -Force
}
$executioncontext.SessionState.PSVariable.Set([NZ.PSScriptVariable]::new('AzureContext',{@(Get-AzureContexts)},$null))
