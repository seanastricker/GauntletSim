Add-Type -AssemblyName System.Drawing

# Load the original image
$imagePath = "C:\Users\seana\Downloads\character_creation_background_compressed.png"
$outputPath = "C:\Users\seana\Downloads\cover_image_itch.jpg"

$image = [System.Drawing.Image]::FromFile($imagePath)
Write-Host "Original size: $($image.Width) x $($image.Height)"

# Calculate new dimensions (reduce by 50% for much smaller file)
$newWidth = [int]($image.Width * 0.6)
$newHeight = [int]($image.Height * 0.6)
Write-Host "New size: $newWidth x $newHeight"

# Create new bitmap and resize
$newImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
$graphics = [System.Drawing.Graphics]::FromImage($newImage)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

# Draw the resized image
$graphics.DrawImage($image, 0, 0, $newWidth, $newHeight)

# Get JPEG codec for quality settings
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 85L)

# Save as JPEG with 85% quality
$newImage.Save($outputPath, $jpegCodec, $encoderParams)

# Clean up
$graphics.Dispose()
$newImage.Dispose()
$image.Dispose()

Write-Host "Compressed image saved to: $outputPath"

# Check the new file size
$newFileSize = (Get-Item $outputPath).Length / 1MB
Write-Host "New file size: $([math]::Round($newFileSize, 2)) MB" 