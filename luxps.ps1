#Dev: Jonathan Brunath
#Contact: mak.programming.labs@gmail.com
#Desc: CLI tool for setting colour of Luxafor LED Status Flag, with option for running as background process that sets colour on screen lock

#The WebHook ID will load from the configPath file defined below, make sure you update this file if you re-generate the ID
$luxID = ""

#Duration inbetween Lock status scans
$scanPeriod = 5

#Toggle Console output
$echoOn = $false

#Config Path defaults to same directory as the script
$configPath = "./luxid.conf"

#API info: https://luxafor.com/webhook-api/
$APIurl = @{
    solid = "https://api.luxafor.com/webhook/v1/actions/solid_color" #accepts any colour in colours array
    blink = "https://api.luxafor.com/webhook/v1/actions/blink" #accepts any colour in colours array
    pattern = "https://api.luxafor.com/webhook/v1/actions/pattern" #accepts any pattern in pattern array
}

#Colour Definitions
$lockColour = "red"
$onlineColour = "green"
$busyColour = "blue"

$colours = "red", "green", "yellow", "blue", "white", "cyan", "magenta"
$patterns = "police", "traffic lights", "random 1", "random 2", "random 3", "random 4", "random 5"
$extraWindowsOnlyPatterns = "rainbow", "sea", "white wave", "synthetic"

#Functions
function echo {
    if ($echoOn -eq $true) {
        Write-Host $args[0]
        return $true
    } else {
        return $false
    }
}
function genConfig {
    #get LuxID from user via CLI, write to config file
    Write-Host "Error: No config file found"
}
function config {
    if ((Test-Path -Path $configPath) -eq $true) {
        echo "Config file found"
        $testLuxID = $(Get-Content -Path $configPath)
        echo "LuxID: $testLuxID"

        #add luxID valiation here

        $luxID = $testLuxID
    } else {
        genConfig
    }
}

function validateItem {
    Param($item,$array)
    $isValid = $false

    echo $item
    foreach ($testItem in $array) {
        if ($testItem -eq $item) {
            echo "Test Item: $testItem"
            $isValid = $true
            break
        }
    }
    echo $isValid
    return $isValid
}
function validateColour {
    Param($colour)
    return $(validateItem -item $colour -array $colours)
}
function validatePattern {
    Param($pattern)
    return $(validateItem -item $pattern -array $patterns)
}
function listArray {
    Param($array)
    foreach ($item in $array) {
        Write-Host " - $item"
    }
}
function listColours {
    listArray -array $colours
}
function listPatterns {
    listArray -array $patterns
}
function setColour {
    Param($colour)

    if ((validateColour -colour $colour) -eq $true) {
        $jsonData = @{
            userId = $luxID
            actionFields = @{ color = $colour }
        }

        $params = @{
            Uri         = $APIurl['solid']
            Method      = 'POST'
            Body        = ConvertTo-Json $jsonData
            ContentType = 'application/json'
        }

        Invoke-RestMethod @params -UseDefaultCredentials
    } else {
        Write-Host "Error: Invalid Colour \"$colour\""
        Write-Host "Valid colours are: "
        listColours
    }
}
function setBlink {
    Param($colour)

    if ((validateColour -colour $colour) -eq $true) {
        $jsonData = @{
            userId = $luxID
            actionFields = @{ color = $colour }
        }

        $params = @{
            Uri         = $APIurl['blink']
            Method      = 'POST'
            Body        = ConvertTo-Json $jsonData
            ContentType = 'application/json'
        }

        Invoke-RestMethod @params -UseDefaultCredentials
    } else {
        Write-Host 'Error: Invalid Colour "'$colour'"'
        Write-Host ""
        Write-Host "Valid colours are: "
        listColours
    }
}
function setPattern {
    Param($pattern)

    if ((validatePattern -pattern $pattern) -eq $true) {
        $jsonData = @{
            userId = $luxID
            actionFields = @{ pattern = $pattern }
        }

        $params = @{
            Uri         = $APIurl['pattern']
            Method      = 'POST'
            Body        = ConvertTo-Json $jsonData
            ContentType = 'application/json'
        }

        Invoke-RestMethod @params -UseDefaultCredentials
    } else {
        Write-Host 'Error: Invalid pattern "'$pattern'"'
        Write-Host ""
        Write-Host "Valid paterns are: "
        listPatterns
    }
}    
function serviceMode {
    $onlineLock = $false
    echo "scanPeriod: $scanPeriod"
    while ($true)
    {
        start-sleep $scanPeriod
        
        $currentuser = gwmi -Class win32_computersystem | select -ExpandProperty username
        $process = get-process logonui -ea silentlycontinue
        $lockState = ($currentuser -and $process)
        echo "LockState: $lockState"

        if ($lockState -eq $true) {
            $onlineLock = $false
            setColour -colour $lockColour
        } else {
            if ($onlineLock -eq $false) {
                setColour -colour $onlineColour
                $onlineLock = $true
            }
        }
        echo "OnlineLock: $onlineLock"
        echo ""
    }
}
function showHelp {
    Write-Host ""
    Write-Host "Help Menu"
    Write-Host "---------"
    Write-Host ""
    Write-Host "NOTE: You must manually set the correct WebHook LuxID in this script before running"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host " -colour <colour>  :  Set a specific colour"
    Write-Host " -blink <colour>   :  Trigger a blink event to a specific colour"
    Write-Host " -pattern <pattern>:  Trigger a pattern event"
    Write-Host " -service          :  Enable service mode that changes the colour based on the machines Screen Lock state"
    Write-Host ""
}

#Main
#Param($verbose)
#if ($verbose.GetType().FullName -eq "System.Boolean") {
#    $echoOn = $verbose
#    echo "Verbose: $echoON"
#}
echo "echoOn: $echoOn"
echo "Args: $args"
echo ""

config

switch ($args[0]) {
    -colour { setColour -colour $args[1]; break }
    -blink { setBlink -colour $args[1]; break }
    -pattern { setPattern -pattern $args[1]; break }
    -service { serviceMode; break }
    default { showHelp; break}
}
