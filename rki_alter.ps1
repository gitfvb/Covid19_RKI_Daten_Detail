# source is this server
Set-location -path "C:\Users\Florian\Desktop\20210605\rki_alter_zahlen"
. ".\Get-DateTimeFromUnixtime.ps1"

# Erläuterungen
# https://www.arcgis.com/home/item.html?id=dd4580c810204019a7b8eb3e0b329dd6

<#
IdBundesland: Id des Bundeslands des Falles mit 1=Schleswig-Holstein bis 16=Thüringen
Bundesland: Name des Bundeslanes
Landkreis ID: Id des Landkreises des Falles in der üblichen Kodierung 1001 bis 16077=LK Altenburger Land
Landkreis: Name des Landkreises
Altersgruppe: Altersgruppe des Falles aus den 6 Gruppe 0-4, 5-14, 15-34, 35-59, 60-79, 80+ sowie unbekannt
Altersgruppe2: Altersgruppe des Falles aus 5-Jahresgruppen 0-4, 5-9, 10-14, ..., 75-79, 80+ sowie unbekannt
Geschlecht: Geschlecht des Falles M0männlich, W=weiblich und unbekannt
AnzahlFall: Anzahl der Fälle in der entsprechenden Gruppe
AnzahlTodesfall: Anzahl der Todesfälle in der entsprechenden Gruppe
Meldedatum: Datum, wann der Fall dem Gesundheitsamt bekannt geworden ist
Datenstand: Datum, wann der Datensatz zuletzt aktualisiert worden ist
NeuerFall: 

    0: Fall ist in der Publikation für den aktuellen Tag und in der für den Vortag enthalten
    1: Fall ist nur in der aktuellen Publikation enthalten
    -1: Fall ist nur in der Publikation des Vortags enthalten
    damit ergibt sich: Anzahl Fälle der aktuellen Publikation als Summe(AnzahlFall), wenn NeuerFall in (0,1); Delta zum Vortag als Summe(AnzahlFall) wenn NeuerFall in (-1,1)

NeuerTodesfall:

    0: Fall ist in der Publikation für den aktuellen Tag und in der für den Vortag jeweils ein Todesfall
    1: Fall ist in der aktuellen Publikation ein Todesfall, nicht jedoch in der Publikation des Vortages
    -1: Fall ist in der aktuellen Publikation kein Todesfall, jedoch war er in der Publikation des Vortags ein Todesfall
    -9: Fall ist weder in der aktuellen Publikation noch in der des Vortages ein Todesfall
    damit ergibt sich: Anzahl Todesfälle der aktuellen Publikation als Summe(AnzahlTodesfall) wenn NeuerTodesfall in (0,1); Delta zum Vortag als Summe(AnzahlTodesfall) wenn NeuerTodesfall in (-1,1)

Referenzdatum: Erkrankungsdatum bzw. wenn das nicht bekannt ist, das Meldedatum
AnzahlGenesen: Anzahl der Genesenen in der entsprechenden Gruppe
NeuGenesen:

    0: Fall ist in der Publikation für den aktuellen Tag und in der für den Vortag jeweils Genesen
    1: Fall ist in der aktuellen Publikation Genesen, nicht jedoch in der Publikation des Vortages
    -1: Fall ist in der aktuellen Publikation nicht Genesen, jedoch war er in der Publikation des Vortags Genesen
    -9: Fall ist weder in der aktuellen Publikation noch in der des Vortages Genesen 
    damit ergibt sich: Anzahl Genesen der aktuellen Publikation als Summe(AnzahlGenesen) wenn NeuGenesen in (0,1); Delta zum Vortag als Summe(AnzahlGenesen) wenn NeuGenesen in (-1,1)

IstErkrankungsbeginn: 1, wenn das Refdatum der Erkrankungsbeginn ist, 0 sonst
#>

#https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_COVID19/FeatureServer/0/query?outFields=*&returnGeometry=false&resultOffset=130&resultRecordCount=10&f=json&orderByFields=Meldedatum&where=IdLandkreis = '05334'


#$url = "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_COVID19/FeatureServer/0/query?outFields=*&where=1%3D1"
$size = 1000
$offset = 0
$data = [System.Collections.ArrayList]@()
Do {
    $url = "https://services7.arcgis.com/mOBPykOjAyBO2ZKk/arcgis/rest/services/RKI_COVID19/FeatureServer/0/query?where=IdLandkreis%3D05334&outFields=*&outSR=&f=json&resultOffset=$( $offset )&resultRecordCount=$( $size )&orderByFields=Meldedatum"
    $c = Invoke-RestMethod -Uri $url -Method Get -verbose
    $data.AddRange( $c.features.attributes )
    $offset += $size
} while ( $c.exceededTransferLimit -eq $true )

$data | select  @{Name="Date";Expression={ Get-DateTimeFromUnixtime -unixtime $_.Refdatum -inMilliseconds }}, * | export-csv -Path ".\data.csv" -Delimiter ";" -Encoding ASCII -NoTypeInformation

$age = $data | select Altersgruppe -Unique | Out-GridView -PassThru

$data | where { $_.Altersgruppe -in $age.Altersgruppe } | sort -property Refdatum -Descending | select @{Name="Date";Expression={ Get-DateTimeFromUnixtime -unixtime $_.Refdatum -inMilliseconds }}, * | Out-GridView

