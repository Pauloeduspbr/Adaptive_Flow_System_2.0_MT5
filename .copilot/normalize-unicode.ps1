# SAFE Unicode Normalization - Only specific problematic characters
# Fix compilation errors caused by Unicode MINUS SIGN in arrow operators

$folder = "D:\EA_Projetos\Adaptive_Flow_System_2.0_MT5\Adaptive_Flow_System_2.0_MT5\MQL5\Include\AdaptiveFlowSystem"

Get-ChildItem -Path $folder -Filter *.mqh | ForEach-Object {
    $file = $_.FullName
    Write-Host "Processing: $($_.Name)" -ForegroundColor Cyan
    
    # Read as UTF-8 (preserve all content)
    $text = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
    
    # ONLY replace Unicode MINUS SIGN (U+2212) with ASCII HYPHEN-MINUS (0x2D)
    # This is the ONLY character causing the '>' - operand expected error
    $original = $text
    $text = $text.Replace([char]0x2212, '-')
    
    if($text -ne $original) {
        # Write back as UTF-8 WITHOUT BOM
        $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file, $text, $utf8NoBOM)
        Write-Host "  FIXED: Unicode MINUS SIGN -> ASCII HYPHEN" -ForegroundColor Green
    } else {
        Write-Host "  OK: No changes needed" -ForegroundColor Gray
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SAFE NORMALIZATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
