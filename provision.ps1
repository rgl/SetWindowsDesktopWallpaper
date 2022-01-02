Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Output (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
    Exit 1
}


# enable TLS 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol `
    -bor [Net.SecurityProtocolType]::Tls12


# wrap the choco command (to make sure this script aborts when it fails).
function Start-Choco([string[]]$Arguments, [int[]]$SuccessExitCodes=@(0)) {
    $command, $commandArguments = $Arguments
    if ($command -eq 'install') {
        $Arguments = @($command, '--no-progress') + $commandArguments
    }
    for ($n = 0; $n -lt 10; ++$n) {
        if ($n) {
            # NB sometimes choco fails with "The package was not found with the source(s) listed."
            #    but normally its just really a transient "network" error.
            Write-Host "Retrying choco install..."
            Start-Sleep -Seconds 3
        }
        &C:\ProgramData\chocolatey\bin\choco.exe @Arguments
        if ($SuccessExitCodes -Contains $LASTEXITCODE) {
            return
        }
    }
    throw "$(@('choco')+$Arguments | ConvertTo-Json -Compress) failed with exit code $LASTEXITCODE"
}
function choco {
    Start-Choco $Args
}


Write-Output 'Configuring Windows...'

# set keyboard layout.
# NB you can get the name from the list:
#      [Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | Out-GridView
Set-WinUserLanguageList pt-PT -Force

# set the date format, number format, etc.
Set-Culture pt-PT

# show window content while dragging.
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name DragFullWindows -Value 1

# show hidden files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1

# show protected operating system files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowSuperHidden -Value 1

# show file extensions.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

# display full path in the title bar.
New-Item -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState -Force `
    | New-ItemProperty -Name FullPath -Value 1 -PropertyType DWORD `
    | Out-Null


Write-Output 'Installing Chocolatey...'
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# update $env:PATH.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment


Write-Output 'Installing Git...'
choco install -y git --params '/GitOnlyOnPath /NoAutoCrlf /SChannel'
choco install -y gitextensions
choco install -y meld
Update-SessionEnvironment


# configure git.
# see http://stackoverflow.com/a/12492094/477532
git config --global user.name 'Rui Lopes'
git config --global user.email 'rgl@ruilopes.com'
git config --global http.sslbackend schannel
git config --global push.default simple
git config --global core.autocrlf false
git config --global core.longpaths true
git config --global diff.guitool meld
git config --global difftool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global difftool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" \"$LOCAL\" \"$REMOTE\"'
git config --global merge.tool meld
git config --global mergetool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global mergetool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" \"$LOCAL\" \"$BASE\" \"$REMOTE\" --auto-merge --output \"$MERGED\"'
#git config --list --show-origin

# configure Git Extensions.
function Set-GitExtensionsStringSetting($name, $value) {
    $settingsPath = "$env:APPDATA\GitExtensions\GitExtensions\GitExtensions.settings"
    [xml]$settingsDocument = Get-Content $settingsPath
    $node = $settingsDocument.SelectSingleNode("/dictionary/item[key/string[text()='$name']]")
    if (!$node) {
        $node = $settingsDocument.CreateElement('item')
        $node.InnerXml = "<key><string>$name</string></key><value><string/></value>"
        $settingsDocument.dictionary.AppendChild($node) | Out-Null
    }
    $node.value.string = $value
    $settingsDocument.Save($settingsPath)
}
Set-GitExtensionsStringSetting TelemetryEnabled 'False'
Set-GitExtensionsStringSetting translation 'English'
Set-GitExtensionsStringSetting gitbindir 'C:\Program Files\Git\bin\'


Write-Output 'Installing .NET 6.0 SDK...'
choco install -y dotnet-6.0-sdk


Write-Output 'Installing Visual Studio Code...'
choco install -y vscode
Update-SessionEnvironment

# configure vscode.
mkdir -Force "$env:APPDATA\Code\User" | Out-Null
Set-Content "$env:APPDATA\Code\User\settings.json" @'
{
    "files.associations": {
        "Vagrantfile": "ruby"
    }
}
'@

# install vscode extensions.
@(
    'ms-vscode.powershell'
    'ms-dotnettools.csharp'
) | ForEach-Object {
    code --install-extension $_
}

Write-Ouput 'Installing ILSpy...'
choco install -y ilspy
