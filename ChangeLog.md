# Change Log - Endpoint Creation Tool
# 2023-10-29


## v1.1.0
 #### - Aufteilung der Skriptausführung auf 2 Runspaces - 1x für GUI und 1x Terminal
 #### - Migration GUI Assembley von Winforms zu WPF (Windows Presentation Framework
 #### - Einführung eines Change Logs inkl. Ergänzung der 1.0.x Versionen
 #### - Doku geschrieben für Endanwender (DAU)
 #### - GUI Erweiterungen
 - RichTextBox: "Activtity Log" für gescheite Rückmeldungen an den User während der Ausführung
 - Button: "Einstellungen" bisher keine Funktion - Vorbereitung für evtl. kommende Funktion
 - Button: "Change Log" um das Change Log aufzurufen, das du grad liest
 - Button: "Logs" um die Logs des Endpoint Creation Tools im Explorer zu öffnen
 - Button: "Hilfe" um die Doku zu öffnen
 - ProgressBar: Fortschrittsbalken für die Skriptausführung 
 #### - Anpassungen an der Ausnahmen-Liste für Bara-DSMove.ini
 - "FAU" wieder aufgenommen, da es jetzt doch FAU-Clients geben wird
 - "ZMK" (Zentrales Marketing) aufgenommen (Neue/Umbenannte Zentralabteilung ehemals ZPM)
 - "ZSI" entfernt, da die jetzt wieder "ZIT" sind
 
## v1.0.3

#### - Ausnahmen-Liste für Bara-DSMove.ini erstellt
- "SEU", da es keine SEU-Clients geben wird
- "FAU", da es keine FAU-Clients geben wird
- "AWS", da diese Clients über das AWS-Portal erstellt werden müssen
- "DMZ(1-4)", da diese Endpoints nicht über Endpoint Creation Tool erstellt werden sollen

## v1.0.2

#### - Anpassungen an den Logs
- Ergänzung fehlender Variablen
- Logs werden jetzt in die Freigabe `\\nesdp001.de.geis-group.net\Clients_anlegen_Logs$` geschrieben

## v1.0.1

#### - Einführung des "Adminmodus"
- Clients werden direkt in der richtigen OU in der Logischen Gruppierung in Baramundi angelegt
- Neue Textbox:  "MAC-Adresse" mit Regex-Check, um eine MAC-Adresse mit übergeben zu können
- Neuer Button: "OS-Install zuweisen" [Nur nutzbar, wenn MAC-Eingabe eine MAC seien kann] um den OS-Installjob zuzuweisen
#### - Regex-Prüfungen
- BA-Nummer: Darf nur aus 0-5 Ziffern bestehen, sonst Textbox.Background = Rot; Skriptausführung ist dennoch möglich
- MAC-Adresse: Eingabe muss eine MAC seien können (Trennung nicht nötig, aber mit ":" oder "-" möglich)
#### - Bei Installation über Baramundi wird jetzt das bConnect-Module mit installiert

## v1.0.0

#### - Erste funktionsfähige Version des Endpoint Creation Tools
#### - Einbindung in Baramundi
