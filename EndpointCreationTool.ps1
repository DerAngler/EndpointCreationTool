[System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null

$Version = "v1.1.0"

function Import-Xaml {
	[xml]$xaml = Get-Content -Path $PSScriptRoot\EndpointCreationTool.xaml -Encoding UTF8
	$manager = New-Object System.Xml.XmlNamespaceManager -ArgumentList $xaml.NameTable
	$manager.AddNamespace("x", "http://schemas.microsoft.com/winfx/2006/xaml");
	$xamlReader = New-Object System.Xml.XmlNodeReader $xaml
	[Windows.Markup.XamlReader]::Load($xamlReader)
}

$Window = Import-Xaml

$Standort_CoBo = $Window.FindName('Standort_CoBo')
$Typ_CoBo = $Window.FindName('Typ_CoBo')
$Lizenz_CoBo = $Window.FindName('Lizenz_CoBo')
$Benutzer_TB = $Window.FindName('Benutzer_TB')
$Abteilung_TB = $Window.FindName('Abteilung_TB')
$NDL_TB = $Window.FindName('NDL_TB')
$MAC_TB = $Window.FindName('MAC_TB')
$OSErlauben_CB = $Window.FindName('OSErlauben_CB')
$OSZuweisen_CB = $Window.FindName('OSZuweisen_CB')
$ClientAnlegen_BTN = $Window.FindName('ClientAnlegen_BTN')
$RichtigeOU_CB = $Window.FindName('RichtigeOU_CB')
$Log_RTB = $Window.FindName('Log_RTB')

$Log_RTB.AppendText("Endpoint Creation Tool $($Version) gestartet`rWarte auf Eingaben...`r")

$ClientAnlegen_BTN.Add_Click({
	$Log_RTB.AppendText("MAC-Adresse: $($MAC_TB.Text)")
})

$Window.ShowDialog()