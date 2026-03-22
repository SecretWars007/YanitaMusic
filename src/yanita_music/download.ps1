$destDir = "assets/training_data"
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir }

$sources = @{
    "bach_minuet_g.mp3"        = "https://www.chosic.com/wp-content/uploads/2021/07/Petzold-Minuet-in-G-major.mp3"
    "bach_toccata_d_minor.mp3" = "https://www.chosic.com/wp-content/uploads/2021/07/Bach-Toccata-And-Fugue-In-D-Minor.mp3"
    "beethoven_fur_elise.mp3"  = "https://www.chosic.com/wp-content/uploads/2021/07/Beethoven-Fur-Elise.mp3"
    "pachelbel_canon_d.mp3"    = "https://www.chosic.com/wp-content/uploads/2021/02/Pachelbel-Canon-in-D-Kevin-MacLeod.mp3"
    "debussy_arabesque_1.mp3"  = "https://www.chosic.com/wp-content/uploads/2021/07/Claude-Debussy-Arabesque-No-1.mp3"
    "satie_gymnopedie_1.mp3"   = "https://www.chosic.com/wp-content/uploads/2021/07/Erik-Satie-Gymnopedie-No-1.mp3"
    "schubert_ave_maria.mp3"   = "https://www.chosic.com/wp-content/uploads/2021/07/Schubert-Ave-Maria.mp3"
}

foreach ($item in $sources.GetEnumerator()) {
    $file = $item.Key
    $url = $item.Value
    $path = Join-Path $destDir $file
    Write-Host "Descargando $file desde $url..."
    # USAR CURL.EXE EXPLÍCITAMENTE (evita alias Invoke-WebRequest)
    & curl.exe -L -k -A "Mozilla/5.0" -o $path $url
    
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        if ($size -lt 100000) {
            Write-Warning "$file es sospechosamente pequeño ($size bytes)."
        } else {
            Write-Host "Éxito: $file ($size bytes)."
        }
    }
}
