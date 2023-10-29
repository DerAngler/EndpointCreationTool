$Version = "1.1.01"
# WPF-Asembly laden und die GUI (xaml) einbinden
[System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null
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

$path = Join-Path $PSScriptRoot '\EndpointCreationTool.xaml'
$Window = [hashtable]::Synchronized(@{ })
$Window = Get-ChildItem -Path $path | Get-XamlObject

# Skript
$Window.Log_RTB.Dispatcher.Invoke([action]{
	$Window.Log_RTB.AppendText("Endpoint Creation Tool gestartet`rVersion: $($Version)`rBenutzer: $($ENV:USERNAME)`rServer: NESDP001.de.geis-group.net`rWarte auf Eingaben... ")
})
$Window.ClientAnlegen_BTN.add_Click({
	# Zweite Runspace erstellen, damit die GUI und das Terminal parallel ausgeführt werden können
	$runspace = [runspacefactory]::CreateRunspace()
	$powerShell = [powershell]::Create()
	$powerShell.runspace = $runspace
	$runspace.Open()
	$runspace.SessionStateProxy.SetVariable("Window",$Window)
	[void]$PowerShell.AddScript({
		# Skript
		$Window.Log_RTB.Dispatcher.Invoke([action]{
			$Window.Log_RTB.Document.Blocks.Clear()
			$Window.ProgressBar.Visibility = "Visible"
			$Window.ProgressBar.Value = 0
			$Window.Log_RTB.AppendText("Ermittle Hostname ... ")
		})
		start-sleep 1
		$Window.ProgressBar.Dispatcher.Invoke([action]{
			$Window.ProgressBar.Value = 10
		})
		start-sleep 1
		$Window.ProgressBar.Dispatcher.Invoke([action]{
			$Window.ProgressBar.Value = 20
		})
		start-sleep 1
		$Window.Log_RTB.Dispatcher.Invoke([action]{
			$Window.Log_RTB.AppendText("$($Window.MAC_TB.Text)`rErstelle Client ... ")
		})
		$Window.ProgressBar.Dispatcher.Invoke([action]{
			$Window.ProgressBar.Value = 40
		})
		start-sleep 1
		$Window.ProgressBar.Dispatcher.Invoke([action]{
			$Window.ProgressBar.Value = 50
		})
		Start-Sleep 2
		$Window.ProgressBar.Dispatcher.Invoke([action]{
			$Window.ProgressBar.Value = 60
		})
		Start-Sleep 2
		$Window.Log_RTB.Dispatcher.Invoke([action]{
			$Window.Log_RTB.AppendText("erfolgreich`rVariablen setzen ... ")
		})
		$Window.ProgressBar.Dispatcher.Invoke([action]{
			$Window.ProgressBar.Value = 80
		})
		start-sleep 1
		$Window.Log_RTB.Dispatcher.Invoke([action]{
			$Window.Log_RTB.AppendText("erfolgreich`rOS-Install zuweisen ... ")
		})
		$Window.ProgressBar.Dispatcher.Invoke([action]{
			$Window.ProgressBar.Value = 90
		})
		start-sleep 1
		$Window.Log_RTB.Dispatcher.Invoke([action]{
			$Window.Log_RTB.AppendText("erfolgreich`rSchreibe Log ... ")
		})
		$Window.ProgressBar.Dispatcher.Invoke([action]{
			$Window.ProgressBar.Value = 95
		})
		Start-Sleep 1
		$Window.ProgressBar.Dispatcher.Invoke([action]{
			$Window.ProgressBar.Value = 100
		})
		$Window.Log_RTB.Dispatcher.Invoke([action]{
			$Window.Log_RTB.AppendText("erfolgreich`r$($Window.MAC_TB.Text) wurde in $($Window.BANummer_TB.Text) angelegt")
		})
	})
	$AsyncObject = $PowerShell.BeginInvoke() #Zeile tut Not, obwohl Variable nie genutzt wird!
})
$Window.WpfWindow.ShowDialog() | Out-Null