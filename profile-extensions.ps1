

update-typedata -typename 'System.Object' -membertype scriptmethod -membername ToJsonString -value {
    param(
        [int]$Depth = 10,
        [switch]$Compress)
    $this | convertto-json -depth $depth -compress:$compress
} -force -confirm:$false 

update-typedata -typename 'System.Management.Automation.PSCustomObject' -membertype scriptmethod -membername ToJsonString -value {
    param(
        [int]$Depth = 10,
        [switch]$Compress)
    $this | convertto-json -depth $depth -compress:$compress
} -force -confirm:$false 


update-typedata -typename 'System.Object' -membertype scriptmethod -membername With -value {
    param([hashtable]$props)
    $copy = $this | select-object -property *
    foreach($key in $props.keys){
        if ($key -in $copy.psobject.properties.name){
            $copy.${key} = $props[$key]
        }else{
            write-warning "Adding new property: $key"
            $copy | add-member -notepropertyname $key -notepropertyvalue $props[$key]
        }
    }
    write-output $copy
} -force -confirm:$false 

update-typedata -typename 'System.Management.Automation.PSCustomObject' -membertype scriptmethod -membername With -value {
    param([hashtable]$props)
    $copy = $this | select-object -property *
    foreach($key in $props.keys){
        if ($key -in $copy.psobject.properties.name){
            $copy.${key} = $props[$key]
        }else{
            write-warning "Adding new property: $key"
            $copy | add-member -notepropertyname $key -notepropertyvalue $props[$key]
        }
    }
    write-output $copy
} -force -confirm:$false 

update-typedata -typename 'string' -membertype scriptmethod -membername FromJsonString -value {
    $this | convertfrom-json
} -force -confirm:$false 

update-typedata -typename 'array' -membertype scriptmethod -membername ToJson -value {param([int]$Depth=3,[switch]$Compress)$this|convertto-json -depth $depth -compress:$compress} -force -confirm:$false 

update-typedata -typename 'string' -membertype scriptmethod -membername FromXmlString -value {[xml]$this} -force -confirm:$false 
update-typedata -typename 'array' -membertype scriptmethod -membername FromXmlString -value {[xml]($this -join '')} -force -confirm:$false 
