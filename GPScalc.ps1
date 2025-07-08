# Prompt user to enter the COM port
$selectedPort = Read-Host "Enter the COM port you want to use (e.g., COM5)"

# Configure the selected COM port
$baudRate = 9600 # Typical baud rate for GPS
$port = new-Object System.IO.Ports.SerialPort $selectedPort, $baudRate, 'None', 8, 'One'

try {
    $port.Open()
    Write-Host "Connected to port $selectedPort." -ForegroundColor Green
} catch {
    Write-Host "Failed to open port $selectedPort. Ensure the port is correct and available. Exiting." -ForegroundColor Red
    exit
}

# Function to read NMEA sentences
function Get-NMEAData {
    while ($port.IsOpen) {
        $data = $port.ReadLine()
        if ($data -like "*GNRMC*" -or $data -like "*GNGGA*" -or $data -like "*GPGSV*" -or $data -like "*GLGSV*" -or $data -like "*GAGSV*") {
            return $data
        }
    }
}

# Function to parse NMEA GNRMC sentence
function Parse-GNRMC($nmea) {
    $parts = $nmea -split ","
    return @{
        Time = $parts[1]
        Status = $parts[2]
        Latitude = [double]($parts[3][0..1] -join "") + [double]($parts[3][2..5] -join "") / 60
        NS = $parts[4]
        Longitude = [double]($parts[5][0..2] -join "") + [double]($parts[5][3..6] -join "") / 60
        EW = $parts[6]
    }
}

# Function to parse NMEA GNGGA sentence
function Parse-GNGGA($nmea) {
    $parts = $nmea -split ","
    return @{
        FixQuality = $parts[6]
        NumSatellites = $parts[7]
    }
}

# Function to parse NMEA GSV sentences
function Parse-GSV($nmea) {
    $parts = $nmea -split ","
    return @{
        SatellitesInView = $parts[3]
    }
}

# Function to calculate the distance between two GPS points using the Haversine formula
function Get-Distance($lat1, $lon1, $lat2, $lon2) {
    $earthRadius = 6371 # Radius in kilometers

    # Convert degrees to radians
    $degToRad = [math]::PI / 180
    $lat1Rad = $lat1 * $degToRad
    $lon1Rad = $lon1 * $degToRad
    $lat2Rad = $lat2 * $degToRad
    $lon2Rad = $lon2 * $degToRad

    $dLat = $lat2Rad - $lat1Rad
    $dLon = $lon2Rad - $lon1Rad
    $a = [math]::Sin($dLat/2) * [math]::Sin($dLat/2) +
         [math]::Cos($lat1Rad) * [math]::Cos($lat2Rad) *
         [math]::Sin($dLon/2) * [math]::Sin($dLon/2)
    $c = 2 * [math]::Atan2([math]::Sqrt($a), [math]::Sqrt(1-$a))
    $distance = $earthRadius * $c
    return [PSCustomObject]@{
        Distance = $distance
        StartLatRad = $lat1Rad
        StartLonRad = $lon1Rad
        EndLatRad = $lat2Rad
        EndLonRad = $lon2Rad
        DeltaLat = $dLat
        DeltaLon = $dLon
        A = $a
        C = $c
    }
}

# Variables to store start and end positions
$startData = $null
$endData = $null
$gpsSatellites = 0
$glonassSatellites = 0
$galileoSatellites = 0

# Display initial instruction
Clear-Host
Write-Host "Press 'S' to record the start position." -ForegroundColor Yellow

# Main loop to read GPS data and await key presses
while ($true) {
    $nmea = Get-NMEAData

    if ($nmea -like "*GNRMC*") {
        $currentData = Parse-GNRMC $nmea
    } elseif ($nmea -like "*GNGGA*") {
        $ggaData = Parse-GNGGA $nmea
    } elseif ($nmea -like "*GPGSV*") {
        $gsvData = Parse-GSV $nmea
        $gpsSatellites = $gsvData.SatellitesInView
    } elseif ($nmea -like "*GLGSV*") {
        $gsvData = Parse-GSV $nmea
        $glonassSatellites = $gsvData.SatellitesInView
    } elseif ($nmea -like "*GAGSV*") {
        $gsvData = Parse-GSV $nmea
        $galileoSatellites = $gsvData.SatellitesInView
    }

    # Display GPS information continuously
    Clear-Host
    if (-not $startData) {
        Write-Host "Press 'S' to record the start position." -ForegroundColor Yellow
    } else {
        Write-Host "Start Position Recorded: Latitude $($startData.Latitude) $($startData.NS), Longitude $($startData.Longitude) $($startData.EW)" -ForegroundColor Green
        Write-Host "Press 'E' to record the end position." -ForegroundColor Yellow
    }
    Write-Host "Fix Quality: $($ggaData.FixQuality), Satellites in Use: $($ggaData.NumSatellites)" -ForegroundColor Cyan
    Write-Host "Satellites in View - GPS: $gpsSatellites, GLONASS: $glonassSatellites, GALILEO: $galileoSatellites" -ForegroundColor Cyan
    if ($currentData) {
        Write-Host "Current Position: Latitude $($currentData.Latitude) $($currentData.NS), Longitude $($currentData.Longitude) $($currentData.EW)" -ForegroundColor White
    }

    if ([console]::KeyAvailable) {
        $key = [console]::ReadKey($true).Key
        if ($key -eq "S" -and $currentData) {
            $startData = $currentData
        } elseif ($key -eq "E" -and $currentData) {
            $endData = $currentData
            break
        }
    }

    Start-Sleep -Milliseconds 500
}

# Calculate and display the distance if both positions are recorded
if ($startData -and $endData) {
    $result = Get-Distance $startData.Latitude $startData.Longitude $endData.Latitude $endData.Longitude
    Clear-Host
    Write-Host "Summary:" -ForegroundColor Green
    Write-Host "Start Position: Latitude $($startData.Latitude) $($startData.NS), Longitude $($startData.Longitude) $($startData.EW)" -ForegroundColor White
    Write-Host "End Position: Latitude $($endData.Latitude) $($endData.NS), Longitude $($endData.Longitude) $($endData.EW)" -ForegroundColor White
    Write-Host "Calculated Distance: $($result.Distance) km" -ForegroundColor Green
    Write-Host ""
    Write-Host "Distance Calculation Details:" -ForegroundColor Magenta
    Write-Host "  Start Latitude (radians): $($result.StartLatRad)"
    Write-Host "  Start Longitude (radians): $($result.StartLonRad)"
    Write-Host "  End Latitude (radians): $($result.EndLatRad)"
    Write-Host "  End Longitude (radians): $($result.EndLonRad)"
    Write-Host "  Delta Latitude (radians): $($result.DeltaLat)"
    Write-Host "  Delta Longitude (radians): $($result.DeltaLon)"
    Write-Host "  a: $($result.A)"
    Write-Host "  c: $($result.C)"
    Write-Host ""
    Write-Host "Haversine Formula: " -ForegroundColor Blue
    Write-Host "a = sin²(Δφ/2) + cos(φ1) * cos(φ2) * sin²(Δλ/2)"
    Write-Host "c = 2 * atan2(√a, √(1−a))"
    Write-Host "d = R * c"
    Write-Host "Where:"
    Write-Host "  φ1 is the start latitude, φ2 is the end latitude"
    Write-Host "  Δφ is the difference between the latitudes (lat2 - lat1)"
    Write-Host "  Δλ is the difference between the longitudes (lon2 - lon1)"
    Write-Host "  R is the Earth's radius (mean radius = 6,371 km)"
}

# Close the COM port
$port.Close()
