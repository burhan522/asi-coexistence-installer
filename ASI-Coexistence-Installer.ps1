# ==========================================================
#  ASI Coexistence Installer  -  interactive tool (WinForms)
#  Runs UE4SS and other dwmapi proxy mods together.
#  Pure PowerShell + WinForms - no install/compiler needed.
# ==========================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) }
$LoaderDir = Join-Path $ScriptDir 'loader'
$Proxies   = @('winmm.dll','dxgi.dll','version.dll')
$SettingsDir  = Join-Path $env:LOCALAPPDATA 'ASI Coexistence Installer'
$SettingsFile = Join-Path $SettingsDir 'lastgame.txt'
function Save-GamePath($p){ try{ if(-not(Test-Path $SettingsDir)){ New-Item -ItemType Directory $SettingsDir | Out-Null }; Set-Content -Path $SettingsFile -Value $p -Encoding UTF8 }catch{} }
function Load-GamePath(){ try{ if(Test-Path $SettingsFile){ return (Get-Content $SettingsFile -Raw).Trim() } }catch{} ; return $null }

# palette (green / white)
$cBack=[Drawing.Color]::FromArgb(245,247,245); $cPanel=[Drawing.Color]::FromArgb(46,125,50)
$cText=[Drawing.Color]::FromArgb(30,30,30); $cGold=[Drawing.Color]::White; $cAccent=[Drawing.Color]::FromArgb(27,94,32)
$cField=[Drawing.Color]::White; $cBtn=[Drawing.Color]::FromArgb(56,142,60)
$cBtnBorder=[Drawing.Color]::FromArgb(27,94,32); $cPrimary=[Drawing.Color]::FromArgb(27,94,32)
$cOk=[Drawing.Color]::FromArgb(46,125,50); $cErr=[Drawing.Color]::FromArgb(198,40,40); $cDim=[Drawing.Color]::FromArgb(110,110,110)

# ---------------- logic ----------------
function Find-GameWin64 {
    $cands=@()
    try {
        $steam=(Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -EA SilentlyContinue).InstallPath
        if(-not $steam){$steam=(Get-ItemProperty 'HKCU:\Software\Valve\Steam' -EA SilentlyContinue).SteamPath}
        if($steam){
            $libs=@($steam); $vdf=Join-Path $steam 'steamapps\libraryfolders.vdf'
            if(Test-Path $vdf){ foreach($m in (Select-String -Path $vdf -Pattern '"path"\s+"(.+?)"' -AllMatches).Matches){ $libs+=($m.Groups[1].Value -replace '\\\\','\') } }
            foreach($lib in ($libs|Select-Object -Unique)){
                $p=Join-Path $lib 'steamapps\common\The Blood of Dawnwalker\Dawnwalker\Binaries\Win64'
                if(Test-Path (Join-Path $p 'Dawnwalker.exe')){ $cands+=$p }
            }
        }
    } catch {}
    if($cands.Count -gt 0){ return $cands[0] } else { return $null }
}
function Resolve-Win64($path){
    if(-not $path){ return $null }
    if(Test-Path $path -PathType Leaf){ $path=Split-Path $path -Parent }
    if(Test-Path (Join-Path $path 'Dawnwalker.exe')){ return $path }
    $d=Join-Path $path 'Dawnwalker\Binaries\Win64'; if(Test-Path (Join-Path $d 'Dawnwalker.exe')){ return $d }
    $d2=Join-Path $path 'The Blood of Dawnwalker\Dawnwalker\Binaries\Win64'; if(Test-Path (Join-Path $d2 'Dawnwalker.exe')){ return $d2 }
    return $null
}
function Get-Proxy($w){ foreach($p in $Proxies){ if(Test-Path (Join-Path $w $p)){ return $p } }; return $null }
function Install-Loader($w,$proxy){
    foreach($p in $Proxies){ $pp=Join-Path $w $p; if(Test-Path $pp){ Remove-Item $pp -Force } }
    Copy-Item (Join-Path $LoaderDir $proxy) (Join-Path $w $proxy) -Force
    Copy-Item (Join-Path $LoaderDir 'global.ini') (Join-Path $w 'global.ini') -Force
    $sc=Join-Path $w 'scripts'; if(-not(Test-Path $sc)){ New-Item -ItemType Directory $sc|Out-Null }
}
function Add-ModFile($w,$file){
    $sc=Join-Path $w 'scripts'; if(-not(Test-Path $sc)){ New-Item -ItemType Directory $sc|Out-Null }
    $base=[IO.Path]::GetFileNameWithoutExtension($file)
    Copy-Item $file (Join-Path $sc ($base+'.asi')) -Force
    return $base
}

# ---------------- UI ----------------
$form=New-Object Windows.Forms.Form
$form.Text='ASI Coexistence Installer'; $form.Size=New-Object Drawing.Size(660,660)
$form.StartPosition='CenterScreen'; $form.Font=New-Object Drawing.Font('Segoe UI',9)
$form.BackColor=$cBack; $form.ForeColor=$cText; $form.AllowDrop=$true; $form.MaximizeBox=$false; $form.FormBorderStyle='FixedSingle'

# header
$hdr=New-Object Windows.Forms.Panel; $hdr.Location='0,0'; $hdr.Size='660,64'; $hdr.BackColor=$cPanel; $form.Controls.Add($hdr)
$title=New-Object Windows.Forms.Label; $title.Text='ASI  COEXISTENCE  INSTALLER'; $title.Location='18,10'; $title.AutoSize=$true
$title.Font=New-Object Drawing.Font('Segoe UI',15,[Drawing.FontStyle]::Bold); $title.ForeColor=$cGold; $hdr.Controls.Add($title)
$sub=New-Object Windows.Forms.Label; $sub.Text='Run UE4SS and other dwmapi proxy mods together'; $sub.Location='20,42'; $sub.AutoSize=$true
$sub.ForeColor=[Drawing.Color]::FromArgb(216,236,216); $hdr.Controls.Add($sub)

function Lbl($t,$x,$y,$bold,$fore){ $l=New-Object Windows.Forms.Label; $l.Text=$t; $l.Location="$x,$y"; $l.AutoSize=$true
    $l.ForeColor= if($fore){$fore}else{$cText}; if($bold){$l.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)}; $form.Controls.Add($l); return $l }
function Btn($t,$x,$y,$w,$h,$primary){ $b=New-Object Windows.Forms.Button; $b.Text=$t; $b.Location="$x,$y"; $b.Size="$w,$h"
    $b.FlatStyle='Flat'; $b.ForeColor=$cGold; $b.BackColor= if($primary){$cPrimary}else{$cBtn}
    $b.FlatAppearance.BorderColor=$cBtnBorder; $b.FlatAppearance.BorderSize=1
    if($primary){$b.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold); $b.ForeColor=[Drawing.Color]::White}
    $form.Controls.Add($b); return $b }

Lbl '1)  Game folder' 16 78 $true $cAccent | Out-Null
$txtPath=New-Object Windows.Forms.TextBox; $txtPath.Location='16,102'; $txtPath.Size='452,24'; $txtPath.ReadOnly=$true
$txtPath.BackColor=$cField; $txtPath.ForeColor=$cText; $txtPath.BorderStyle='FixedSingle'; $form.Controls.Add($txtPath)
$btnAuto=Btn 'Auto' 476 101 76 26 $false
$btnBrowse=Btn 'Browse' 558 101 82 26 $false
$lblState=Lbl '' 16 134 $false $cText; $lblState.AutoSize=$false; $lblState.Size=New-Object Drawing.Size(624,40)

# primary: set up everything
$btnAll=Btn "  Set up everything  (install loader + add a mod)" 16 182 480 40 $true
Lbl 'Proxy' 508 176 $false $cDim | Out-Null
$cmbProxy=New-Object Windows.Forms.ComboBox; $cmbProxy.Location='508,192'; $cmbProxy.Size='128,24'; $cmbProxy.DropDownStyle='DropDownList'
$cmbProxy.BackColor=$cField; $cmbProxy.ForeColor=$cText; $cmbProxy.FlatStyle='Flat'; $cmbProxy.Items.AddRange($Proxies); $cmbProxy.SelectedIndex=0; $form.Controls.Add($cmbProxy)

Lbl 'Advanced:' 16 236 $false $cDim | Out-Null
$btnInstall=Btn 'Install / Repair loader' 92 230 160 28 $false
$btnUninstall=Btn 'Remove loader' 260 230 130 28 $false

Lbl '3)  Proxy mods   (drag a mod .dll onto this window, or use Add)' 16 274 $true $cAccent | Out-Null
$list=New-Object Windows.Forms.ListBox; $list.Location='16,300'; $list.Size='476,264'; $list.BackColor=$cField; $list.ForeColor=$cText
$list.BorderStyle='FixedSingle'; $list.Font=New-Object Drawing.Font('Consolas',10); $list.AllowDrop=$true; $form.Controls.Add($list)
$btnAdd=Btn 'Add mod...' 504 300 136 32 $false
$btnToggle=Btn 'Enable / Disable' 504 340 136 32 $false
$btnRemove=Btn 'Remove' 504 380 136 32 $false
$btnOpen=Btn 'Open scripts folder' 504 420 136 44 $false

$lblLog=Lbl 'Ready.' 16 578 $false $cDim; $lblLog.AutoSize=$false; $lblLog.Size=New-Object Drawing.Size(624,44)

# ---------------- state ----------------
$script:win64=$null
function Log($t,$err){ $lblLog.Text=$t; $lblLog.ForeColor= if($err){$cErr}else{$cOk} }
function Refresh {
    $list.Items.Clear()
    if(-not $script:win64){ $lblState.Text='No game selected. Click Auto (Steam), or Browse to your Dawnwalker.exe.'; $lblState.ForeColor=$cErr; $txtPath.Text=''; return }
    $txtPath.Text=$script:win64
    $ue4ss=(Test-Path (Join-Path $script:win64 'ue4ss')) -and (Test-Path (Join-Path $script:win64 'dwmapi.dll'))
    $proxy=Get-Proxy $script:win64; $gi=Test-Path (Join-Path $script:win64 'global.ini')
    $s="UE4SS: "+($(if($ue4ss){'detected'}else{'not found'}))+"      Loader: "+($(if($proxy){"installed ($proxy)"+$(if(-not $gi){'  global.ini MISSING!'}else{''})}else{'not installed'}))
    $lblState.Text=$s; $lblState.ForeColor= if($ue4ss -and $proxy){$cOk}else{$cText}
    if($proxy){ $cmbProxy.SelectedItem=$proxy }
    $sc=Join-Path $script:win64 'scripts'
    if(Test-Path $sc){ foreach($f in Get-ChildItem $sc -File | Where-Object { $_.Name -match '\.asi(\.off)?$' } | Sort-Object Name){
        $list.Items.Add($f.Name + $(if($f.Name -match '\.off$'){'   [disabled]'}else{''})) | Out-Null } }
}
function Set-Win64($raw){ $r=Resolve-Win64 $raw; if($r){ $script:win64=$r; Save-GamePath $r; Refresh; Log "Game set: $r" $false } else { Log "Not a Dawnwalker folder: $raw" $true } }

# ---------------- actions ----------------
$btnAuto.Add_Click({ $g=Find-GameWin64; if($g){ Set-Win64 $g } else { Log 'Auto-detect failed (game not found via Steam). Click Browse and pick your Dawnwalker.exe.' $true } })
$btnBrowse.Add_Click({ $o=New-Object Windows.Forms.OpenFileDialog; $o.Title='Select Dawnwalker.exe (in ...\Binaries\Win64)'; $o.Filter='Dawnwalker.exe|Dawnwalker.exe|All exe|*.exe'; if($o.ShowDialog() -eq 'OK'){ Set-Win64 $o.FileName } })
$btnInstall.Add_Click({ if(-not $script:win64){ Log 'Select the game first.' $true; return }
    try { Install-Loader $script:win64 $cmbProxy.SelectedItem; Refresh; Log "Loader installed as $($cmbProxy.SelectedItem). Add your proxy mods below." $false }
    catch { Log "Install failed: $($_.Exception.Message)  (close the game; if it's in Program Files, right-click the tool and Run as administrator)" $true } })
$btnUninstall.Add_Click({ if(-not $script:win64){ return }
    try { foreach($p in $Proxies){ $pp=Join-Path $script:win64 $p; if(Test-Path $pp){ Remove-Item $pp -Force } }
        $gi=Join-Path $script:win64 'global.ini'; if(Test-Path $gi){ Remove-Item $gi -Force }; Refresh; Log 'Loader removed (UE4SS/dwmapi untouched, scripts kept).' $false }
    catch { Log "Remove failed: $($_.Exception.Message)" $true } })
$btnAdd.Add_Click({ if(-not $script:win64){ Log 'Select the game first.' $true; return }
    $o=New-Object Windows.Forms.OpenFileDialog; $o.Title='Pick the mod DLL (usually dwmapi.dll) or an .asi'; $o.Filter='Mod files (*.dll;*.asi)|*.dll;*.asi|All files|*.*'
    if($o.ShowDialog() -eq 'OK'){ try{ $b=Add-ModFile $script:win64 $o.FileName; Refresh; Log "Added '$b.asi' - it now loads next to UE4SS." $false }catch{ Log "Add failed: $($_.Exception.Message)" $true } } })
$btnToggle.Add_Click({ if(-not $script:win64 -or $list.SelectedItem -eq $null){ return }
    $name=($list.SelectedItem -replace '\s+\[disabled\]$',''); $p=Join-Path (Join-Path $script:win64 'scripts') $name
    try { if($name -match '\.off$'){ Rename-Item $p ($name -replace '\.off$','') } else { Rename-Item $p ($name+'.off') }; Refresh; Log 'Toggled. (.off = disabled, not loaded)' $false }
    catch { Log "Toggle failed: $($_.Exception.Message)" $true } })
$btnRemove.Add_Click({ if(-not $script:win64 -or $list.SelectedItem -eq $null){ return }
    $name=($list.SelectedItem -replace '\s+\[disabled\]$','')
    if([Windows.Forms.MessageBox]::Show("Remove $name ?",'Confirm',[Windows.Forms.MessageBoxButtons]::YesNo) -eq 'Yes'){
        try { Remove-Item (Join-Path (Join-Path $script:win64 'scripts') $name) -Force; Refresh; Log "Removed $name." $false }catch{ Log "Remove failed: $($_.Exception.Message)" $true } } })
$btnOpen.Add_Click({ if($script:win64){ $sc=Join-Path $script:win64 'scripts'; if(-not(Test-Path $sc)){ New-Item -ItemType Directory $sc|Out-Null }; Start-Process explorer.exe $sc } })

# SET UP EVERYTHING
$btnAll.Add_Click({
    if(-not $script:win64){ Log 'Select the game first (Auto or Browse).' $true; return }
    try {
        Install-Loader $script:win64 $cmbProxy.SelectedItem
        $ue4ss=(Test-Path (Join-Path $script:win64 'ue4ss')) -and (Test-Path (Join-Path $script:win64 'dwmapi.dll'))
        $o=New-Object Windows.Forms.OpenFileDialog; $o.Title='Optional: pick a proxy mod DLL to add now (or Cancel to skip)'; $o.Filter='Mod files (*.dll;*.asi)|*.dll;*.asi|All files|*.*'
        $added=$null; if($o.ShowDialog() -eq 'OK'){ $added=Add-ModFile $script:win64 $o.FileName }
        Refresh
        $msg="Loader ready ($($cmbProxy.SelectedItem)). " + $(if($ue4ss){'UE4SS detected. '}else{'NOTE: UE4SS not found - install it separately. '}) + $(if($added){"Added $added.asi."}else{'No mod added.'})
        Log $msg $false
        [Windows.Forms.MessageBox]::Show($msg + "`n`nDone. Launch the game - your mods run together.",'Set up complete') | Out-Null
    } catch { Log "Setup failed: $($_.Exception.Message)  (close the game; if it's in Program Files, run the tool as administrator)" $true }
})

# drag & drop
$onEnter={ param($s,$e); if($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)){ $e.Effect=[Windows.Forms.DragDropEffects]::Copy } }
$onDrop ={ param($s,$e); if(-not $script:win64){ Log 'Select the game first.' $true; return }
    foreach($f in $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)){ if($f -match '\.(dll|asi)$'){ try{ $b=Add-ModFile $script:win64 $f; Log "Added $b.asi." $false }catch{ Log "Add failed: $($_.Exception.Message)" $true } } }
    Refresh }
$form.Add_DragEnter($onEnter); $form.Add_DragDrop($onDrop); $list.Add_DragEnter($onEnter); $list.Add_DragDrop($onDrop)

# startup: remembered path first, then Steam auto-detect
$saved=Load-GamePath; $init=$null
if($saved){ $init=Resolve-Win64 $saved }
if(-not $init){ $init=Find-GameWin64 }
if($init){ Set-Win64 $init; Log "Game loaded (remembered): $init" $false } else { Refresh }
[void]$form.ShowDialog()
