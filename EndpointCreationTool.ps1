$LogPath = "C:\Temp\"
$Version = "1.1.0"
$Rot = "#f55555"
# WPF-Asembly laden und die GUI (xaml) einbinden
[System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null
#Funktionen in Terminal Runspace
function Get-XamlObject {
	[CmdletBinding()]
	param(
		[Parameter(Position = 0,
			Mandatory = $true,
			ValuefromPipelineByPropertyName = $true,
			ValuefromPipeline = $true)]
		[Alias("FullName")]
		[System.String[]]$Path
	)

	BEGIN{
		Set-StrictMode -Version Latest
		$expandedParams = $null
		$PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
		Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
		$output = @{ }
		Add-Type -AssemblyName presentationframework, presentationcore
	}

	PROCESS{
		try{
			foreach ($xamlFile in $Path){
				#Change content of Xaml file to be a set of powershell GUI objects
				$inputXML = Get-Content -Path $xamlFile -ErrorAction Stop -Encoding UTF8
				[xml]$xaml = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace 'x:Class=".*?"', '' -replace 'd:DesignHeight="\d*?"', '' -replace 'd:DesignWidth="\d*?"', ''
				$tempform = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml -ErrorAction Stop))

				#Grab named objects from tree and put in a flat structure using Xpath
				$namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")
				$namedNodes | ForEach-Object {
					$output.Add($_.Name, $tempform.FindName($_.Name))
				}
			}
		}
		catch{
			throw $error[0]
		}
	}

	END{
		Write-Output $output
		Write-Verbose "Finished: $($MyInvocation.Mycommand)"
	}
} 

$GUIpath = Join-Path $PSScriptRoot '\EndpointCreationTool.xaml'
$GUI = [hashtable]::Synchronized(@{ })
$GUI = Get-ChildItem -Path $GUIpath | Get-XamlObject

$EinstellungenPath = Join-Path $PSScriptRoot '\Einstellungen.xaml'
$Einstellungen = [hashtable]::Synchronized(@{ })
$Einstellungen = Get-ChildItem -Path $EinstellungenPath | Get-XamlObject

$GUI.Standort_CoBo.Items.Add("AMB")
# Skript
$GUI.Log_RTB.Dispatcher.Invoke([action]{
	$GUI.Log_RTB.AppendText("Endpoint Creation Tool gestartet`rVersion: $($Version)`rBenutzer: $($ENV:USERNAME)`rServer: NESDP001.de.geis-group.net`rWarte auf Eingaben ... ")
})

$GUI.BANummer_TB.Add_TextChanged({
    if (!($GUI.BANummer_TB.Text -match "^[0-9]{0,5}$")) {
        $GUI.BANummer_TB.Background = $Rot
    }else{
        $GUI.BANummer_TB.Background = "white"
    }
	if ($GUI.BANummer_TB.Text -eq "Reset") {
        $GUI.MainWindow.Height = 564
		$Einstellungen.TitelMenu_Setting_CB.IsChecked = $true
    }
})

$GUI.MAC_TB.Add_TextChanged({
	if (($GUI.MAC_TB.Text -match "^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$" -or $GUI.MAC_TB.Text -match "^[0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2}-[0-9A-F]{2}$" -or $GUI.MAC_TB.Text -match "^[0-9A-F]{2}[0-9A-F]{2}[0-9A-F]{2}[0-9A-F]{2}[0-9A-F]{2}[0-9A-F]{2}$" -or $GUI.MAC_TB.Text -eq "")) {
		if(!($GUI.MAC_TB.Text -eq "")){
			$GUI.MAC_TB.Background = "white"
			$GUI.OSZuweisen_CB.IsEnabled = $true
		}else{
			$GUI.MAC_TB.Background = "white"
			$GUI.OSZuweisen_CB.IsEnabled = $false
			$GUI.OSZuweisen_CB.IsChecked = $false
		}
	}else{
		$GUI.OSZuweisen_CB.IsEnabled = $false
		$GUI.OSZuweisen_CB.IsChecked = $false
		$GUI.MAC_TB.Background = $Rot
	}
})

$GUI.Einstellungen_BTN.add_Click({
	$Einstellungen.Einstellungen.Show()
})

$GUI.ChangeLog_BTN.add_Click({
	$ChangeLogPath = Join-Path $PSScriptRoot '\ChangeLog.log'
	notepad $ChangeLogPath
})

$GUI.Logs_BTN.add_Click({
	explorer $LogPath
})

$GUI.Doku_BTN.add_Click({
	$DokuPath = Join-Path $PSScriptRoot '\Dokumentation.pdf'
	Start-Process $DokuPath
})

$Einstellungen.TitelMenu_Setting_CB.add_Click({
	if($Einstellungen.TitelMenu_Setting_CB.IsChecked){
		$GUI.MainWindow.Height = 564
	}else{
		$GUI.MainWindow.Height = 540
	}
})

$Einstellungen.Benachrichtigungen_Setting_CB.add_Click({
	if($Einstellungen.Benachrichtigungen_Setting_CB.IsChecked){
		# $GUI.MainWindow.Height = 564
	}else{
		# $GUI.MainWindow.Height = 540
	}
})

$Einstellungen.Speichern_BTN.add_Click({
	$Einstellungen.Einstellungen.Hide()
})

$GUI.ClientAnlegen_BTN.add_Click({
	#Variablen von Terminal RunSpace in GUI RunSpace pushen
	$GUI.Name = $GUI.MAC_TB.text
	$GUI.NDL = $GUI.BANummer_TB.text
	# GUI Runspace erstellen, damit die GUI und das Terminal parallel ausgeführt werden können
	$runspace = [runspacefactory]::CreateRunspace()
	$powerShell = [powershell]::Create()
	$powerShell.runspace = $runspace
	$runspace.Open()
	$runspace.SessionStateProxy.SetVariable("GUI",$GUI)
	
	[void]$PowerShell.AddScript({
		#Funktionen in GUI Runspace
		function Progress($Progress){
			$GUI.ProgressBar.Dispatcher.Invoke([action]{
				$GUI.ProgressBar.Value = $Progress
			})
		}

		function Message($Message){
			$GUI.Log_RTB.Dispatcher.Invoke([action]{
				$GUI.Log_RTB.AppendText("$($Message)")
			})
		}
		# Skript
		$GUI.Log_RTB.Dispatcher.Invoke([action]{
			$GUI.Log_RTB.Document.Blocks.Clear()
			$GUI.ProgressBar.Visibility = "Visible"
			$GUI.ProgressBar.Value = 0
			$GUI.Log_RTB.AppendText("Name ermitteln...   ")
		})
		start-sleep 1
		Progress(10)
		start-sleep 1
		Progress(20)
		start-sleep 1
		Message("$($GUI.Name)`rClient anlegen ...   ")
		Progress(40)
		start-sleep 1
		Progress(50)
		Start-Sleep 2
		Progress(60)
		Start-Sleep 2
		Message("erfolgreich`rVariablen setzen ...   ")
		Progress(80)
		start-sleep 1
		Message("erfolgreich`rOS-Install zuweisen ...   ")
		Progress(90)
		start-sleep 1
		Message("erfolgreich`rLog Eintrag schreiben ...   ")
		Progress(95)
		Start-Sleep 1
		Progress(100)
		# Message("erfolgreich`r`"$($GUI.Name)`" wurde in `"$($GUI.NDL)`" angelegt")
		Message("erfolgreich`r############## FERTIG #############")
	})
	$PowerShell.BeginInvoke()
	if($Einstellungen.Benachrichtigungen_Setting_CB.IsChecked -eq $True){
		[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
		$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 
		$objNotifyIcon.Icon = "C:\Icons\wt.ico"
		$objNotifyIcon.BalloonTipIcon = "Info" #"Error" 
		$objNotifyIcon.BalloonTipText = "Es dauert nur noch einen kurzen Augenblick!" 
		$objNotifyIcon.BalloonTipTitle = "Endpoint Creation Tool legt los!"
		$objNotifyIcon.Visible = $True
		$objNotifyIcon.ShowBalloonTip(10000)
	}
})

$GUI.MainWindow.ShowDialog() | Out-Null