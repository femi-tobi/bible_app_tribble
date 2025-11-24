Add-Type -AssemblyName System.IO.Compression.FileSystem

$pdfPath = "GHS FINAL.pdf"

# Try to read PDF as text (this is a simple attempt)
try {
    $content = [System.IO.File]::ReadAllText($pdfPath)
    Write-Output $content
} catch {
    Write-Output "Error reading PDF: $_"
    
    # Alternative: Try to use Word COM object if available
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $doc = $word.Documents.Open((Resolve-Path $pdfPath).Path)
        $doc.SaveAs([ref] "temp_output.txt", [ref] 2)
        $doc.Close()
        $word.Quit()
        Get-Content "temp_output.txt"
    } catch {
        Write-Output "Word COM also failed: $_"
    }
}
