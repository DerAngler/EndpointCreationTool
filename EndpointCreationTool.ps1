$Version = "1.1.01"
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

$path = Join-Path $PSScriptRoot '\EndpointCreationTool.xaml'
$Window = [hashtable]::Synchronized(@{ })
$Window = Get-ChildItem -Path $path | Get-XamlObject

# Skript
$Window.Log_RTB.Dispatcher.Invoke([action]{
	$Window.Log_RTB.AppendText("Endpoint Creation Tool gestartet`rVersion: $($Version)`rBenutzer: $($ENV:USERNAME)`rServer: NESDP001.de.geis-group.net`rWarte auf Eingaben... ")
})
$Window.ClientAnlegen_BTN.add_Click({
	#Variablen von Terminal RunSpace in GUI RunSpace pushen
	$Window.Name = $Window.MAC_TB.text
	$Window.NDL = $Window.BANummer_TB.text
	# GUI Runspace erstellen, damit die GUI und das Terminal parallel ausgeführt werden können
	$runspace = [runspacefactory]::CreateRunspace()
	$powerShell = [powershell]::Create()
	$powerShell.runspace = $runspace
	$runspace.Open()
	$runspace.SessionStateProxy.SetVariable("Window",$Window)
	
	[void]$PowerShell.AddScript({
		$Text = ""
		#Funktionen in GUI Runspace
		function Progress($Progress){
			$Window.ProgressBar.Dispatcher.Invoke([action]{
				$Window.ProgressBar.Value = $Progress
			})
			Write-Host "test$($Progress)"
		}

		function Message($Message){
			$Window.Log_RTB.Dispatcher.Invoke([action]{
				$Window.Log_RTB.AppendText("$($Message)")
			})
		}
		# Skript
		$Window.Log_RTB.Dispatcher.Invoke([action]{
			$Window.Log_RTB.Document.Blocks.Clear()
			$Window.ProgressBar.Visibility = "Visible"
			$Window.ProgressBar.Value = 0
			$Window.Log_RTB.AppendText("Hostname ermitteln...    ")
		})
		start-sleep 1
		Progress(10)
		start-sleep 1
		Progress(20)
		start-sleep 1
		Message("$($Window.Name)`rClient wird angelegt ...                   ")
		Progress(40)
		start-sleep 1
		Progress(50)
		Start-Sleep 2
		Progress(60)
		Start-Sleep 2
		Message("erfolgreich`rVariablen setzen ...                         ")
		Progress(80)
		start-sleep 1
		Message("erfolgreich`rOS-Install zuweisen ...                    ")
		Progress(90)
		start-sleep 1
		Message("erfolgreich`rSchreibe Log ....                              ")
		Progress(95)
		Start-Sleep 1
		Progress(100)
		Message("erfolgreich`r$($Window.Name) wurde in $($Window.NDL) angelegt")
	})
	$AsyncObject = $PowerShell.BeginInvoke() #Zeile tut Not, obwohl Variable nie genutzt wird!?!?
})
$Window.WpfWindow.ShowDialog() | Out-Null