
$aliases = @{
    cat = 'get-content'
    grep = 'select-string'
    ls = 'get-childitem'
    ps = 'get-process'
    rm = 'remove-item'
    rmdir = 'remove-item'
    sort = 'sort-object'
    s = 'select-object'
    join = 'join-string'
    cred = 'get-credential'
    which = 'get-command'
    cp = 'copy-item'

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
    whereis = 'profile-module\Where-ObjectProperty'

    #queryhub
    OAdd = 'queryhub\Add-OracleQueryHubConnection'
    OBuild = 'queryhub\Invoke-OraclePackageBuild'
    OCode = 'queryhub\Get-OracleCodeDefinition'
    OCodes = 'queryhub\Get-OracleCodeNames'
    OConnections = 'queryhub\Get-OracleQueryHubConnections'
    ODef = 'queryhub\Get-OracleDefinition'
    ODefault = 'queryhub\Get-OracleDefaultQueryHubConnection'
    ODependencies = 'queryhub\Get-OracleDependencies'
    OErrors = 'queryhub\Get-OracleErrors'
    OExplain = 'queryhub\Get-OracleExplainPlan'
    OFile = 'queryhub\Invoke-OracleQueryFromFile'
    OHistory = 'queryhub\Get-OracleSessionSqlHistory'
    OIndex = 'queryhub\Get-OracleIndex'
    OKeys = 'queryhub\Get-OracleFndTableKeys'
    OKillSession = 'queryhub\Stop-OracleSession'
    OLastDbms = 'queryhub\Get-LastOracleDbmsOutput'
    OLastError = 'queryhub\Get-LastOracleQueryError'
    OLastExplain = 'queryhub\Get-LastOracleQueryExplain'
    OLastRequest = 'queryhub\Get-LastOracleQueryRequest'
    OLastTime = 'queryhub\Get-LastOracleQueryTime'
    ORemove = 'queryhub\Remove-OracleQueryHubConnection'
    OSelect = 'queryhub\Get-OracleTableSelectString'
    OSession = 'queryhub\Get-OracleSession'
    OSet = 'queryhub\Set-OracleDefaultQueryHubConnection'
    OSetDate = 'queryhub\Set-OracleSessionDateFormat'
    OSql = 'queryhub\Invoke-OracleQuery'
    OTable = 'queryhub\Get-OracleTableSchema'
    OTables = 'queryhub\Get-OracleTableNames'
    OTest = 'queryhub\Test-OracleConnection'
    os = 'queryhub\invoke-oraclescript'
    oslist = 'queryhub\get-oraclescripts'

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

    PAdd = 'queryhub\Add-PostgresQueryHubConnection'
    PConnections = 'queryhub\Get-PostgresQueryHubConnections'
    PDefault = 'queryhub\Get-PostgresDefaultQueryHubConnection'
    PFile = 'queryhub\Invoke-PostgresQueryFromFile'
    PLastError = 'queryhub\Get-LastPostgresQueryError'
    PLastRequest = 'queryhub\Get-LastPostgresQueryRequest'
    PLastTime = 'queryhub\Get-LastPostgresQueryTime'
    PRemove = 'queryhub\Remove-PostgresQueryHubConnection'
    PSet = 'queryhub\Set-PostgresDefaultQueryHubConnection'
    PSql = 'queryhub\Invoke-PostgresQuery'
    PTable = 'queryhub\Get-PostgresTableSchema'
    PTables = 'queryhub\Get-PostgresTableNames'
    PTest = 'queryhub\Test-PostgresConnection'
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

if(Test-Path variable:\olast) {
    Remove-Item variable:\olast -Force
}
$executioncontext.SessionState.PSVariable.Set([NZ.PSScriptVariable]::new('OLast',{@(get-lastoraclequeryresult)},$null))

if(Test-Path variable:\slast) {
    Remove-Item variable:\slast -Force
}
$executioncontext.SessionState.PSVariable.Set([NZ.PSScriptVariable]::new('SLast',{@(get-lastsqlserverqueryresult)},$null))

if(Test-Path variable:\plast) {
    Remove-Item variable:\plast -Force
}
$executioncontext.SessionState.PSVariable.Set([NZ.PSScriptVariable]::new('PLast',{@(get-lastpostgresqueryresult)},$null))

#type accelerators
[psobject].assembly.gettype("System.Management.Automation.TypeAccelerators")::add("a","System.Management.Automation.PSObject")
