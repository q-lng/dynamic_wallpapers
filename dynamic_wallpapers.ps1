Function Set-Wallpaper {
    param($Theme, $File)

    # Get image path
    $WallpaperPath = (Get-Item "C:\temp\macos_wallpapers\$Theme\*$File*").FullName
    Write-Host $WallpaperPath

    $Style = "Fill"
    
    # Conversion style → valeurs registre
    $styleMap = @{
        "Fill"    = 10
        "Fit"     = 6
        "Stretch" = 2
        "Tile"    = 0
        "Center"  = 0
        "Span"    = 22
    }

    $absolutePath = (Resolve-Path $WallpaperPath).Path

    # Fichier BMP temporaire (indispensable pour éviter les bugs PNG → noir)
    $tempBmp = "$env:TEMP\wallpaper_temp.bmp"

    # Charger System.Drawing
    Add-Type -AssemblyName System.Drawing

    # Charger l'image et convertir en BMP
    $img = [System.Drawing.Image]::FromFile($absolutePath)
    $img.Save($tempBmp, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $img.Dispose()

    Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@


    # SPI_SETDESKWALLPAPER = 20, SPIF_UPDATEINIFILE = 1, SPIF_SENDWININICHANGE = 2
    [Wallpaper]::SystemParametersInfo(20, 0, $tempBmp, 3)

    Write-Host "Fond d'écran appliqué : $absolutePath (converti en BMP)"
}

$selectedTheme = "desert"

$h = Get-Date  # ou [datetime]"2025-01-01 23:15"
# $h = [datetime]"2025-11-16 12:45"

$apiResult = (Invoke-RestMethod -Uri "https://api.open-meteo.com/v1/forecast?latitude=48.8534&longitude=2.3488&daily=sunrise,sunset,daylight_duration,sunshine_duration&models=meteofrance_seamless&timezone=auto&forecast_days=1").daily
$sunrise = [datetime]([string]$apiResult.sunrise -Replace "^.*T", "")
$morning = $sunrise.AddHours(1)
$noon = $morning.AddHours($apiResult.daylight_duration[0] / 2.5 / 60 / 60)
$sunset = [datetime]([string]$apiResult.sunset -Replace "^.*T", "")
$night = $sunset.AddHours(1)

if ($h -ge $night -or $h -lt $sunrise) {
    "Plage : Nuit"
    Set-Wallpaper -Theme $selectedTheme -File "Night"
}
elseif ($h -ge $sunrise -and $h -lt $morning) {
    "Plage : Aube"
    Set-Wallpaper -Theme $selectedTheme -File "Dawn"
}
elseif ($h -ge $morning -and $h -lt $noon) {
    "Plage : Matin"
    Set-Wallpaper -Theme $selectedTheme -File "Morning"
}
elseif ($h -ge $noon -and $h -lt $sunset) {
    "Plage : Après-midi"
    Set-Wallpaper -Theme $selectedTheme -File "Noon"
}
elseif ($h -ge $sunset -and $h -lt $night) {
    "Plage : Soir"
    Set-Wallpaper -Theme $selectedTheme -File "Dusk"
}

