
update-typedata -typename 'string' -membertype scriptmethod -membername FromJson -value {
    $this | convertfrom-json
} -force -confirm:$false 

update-typedata -typename 'psobject' -membertype scriptmethod -membername ToJson -value {
    param(
        [int]$Depth = 10,
        [switch]$Compress)
    $this | convertto-json -depth $depth -compress:$compress
} -force -confirm:$false 

update-typedata -typename 'System.Management.Automation.PSCustomObject' -membertype scriptmethod -membername ToJson -value {
    param(
        [int]$Depth = 10,
        [switch]$Compress)
    $this | convertto-json -depth $depth -compress:$compress
} -force -confirm:$false 
update-typedata -typename 'array' -membertype scriptmethod -membername ToJson -value {param([int]$Depth=3,[switch]$Compress)$this|convertto-json -depth $depth -compress:$compress} -force -confirm:$false 

update-typedata -typename 'string' -membertype scriptmethod -membername FromXml -value {[xml]$this} -force -confirm:$false 
update-typedata -typename 'array' -membertype scriptmethod -membername FromXml -value {[xml]($this -join '')} -force -confirm:$false 
