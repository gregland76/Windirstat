Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function Format-Size {
    param([int64]$Size)

    if ($Size -ge 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
    if ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    return "$Size B"
}

function Get-ItemSizes {
    param([string]$RootPath)

    $items = @()
    $children = Get-ChildItem -LiteralPath $RootPath -Force -ErrorAction SilentlyContinue
    foreach ($child in $children) {
        if ($child.PSIsContainer) {
            $size = 0
            try {
                $size = (Get-ChildItem -LiteralPath $child.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            } catch {
                $size = 0
            }

            $items += [PSCustomObject]@{
                Name     = $child.Name
                FullName = $child.FullName
                Type     = 'Folder'
                Size     = [int64]$size
            }
        } else {
            $items += [PSCustomObject]@{
                Name     = $child.Name
                FullName = $child.FullName
                Type     = 'File'
                Size     = [int64]$child.Length
            }
        }
    }

    return $items | Sort-Object Size -Descending | Select-Object -First 50
}

function Draw-Treemap {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Rectangle]$Bounds,
        [object[]]$Items
    )

    if (-not $Items -or $Items.Count -eq 0) { return }

    $total = ($Items | Measure-Object Size -Sum).Sum
    if ($total -le 0) { return }

    $font = New-Object System.Drawing.Font('Arial', 9)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $horizontal = $Bounds.Width -ge $Bounds.Height
    $offsetX = $Bounds.X
    $offsetY = $Bounds.Y
    $remainingWidth = $Bounds.Width
    $remainingHeight = $Bounds.Height

    for ($index = 0; $index -lt $Items.Count; $index++) {
        $item = $Items[$index]

        if ($horizontal) {
            $width = [math]::Max(1, [int](($item.Size / $total) * $Bounds.Width))
            if ($index -eq $Items.Count - 1) { $width = $remainingWidth }
            $rect = [System.Drawing.Rectangle]::new($offsetX, $offsetY, $width, $remainingHeight)
            $offsetX += $width
            $remainingWidth -= $width
        } else {
            $height = [math]::Max(1, [int](($item.Size / $total) * $Bounds.Height))
            if ($index -eq $Items.Count - 1) { $height = $remainingHeight }
            $rect = [System.Drawing.Rectangle]::new($offsetX, $offsetY, $remainingWidth, $height)
            $offsetY += $height
            $remainingHeight -= $height
        }

        $color = [System.Drawing.Color]::FromArgb(
            180,
            ((($index * 73) + 50) % 176) + 40,
            ((($index * 137) + 80) % 176) + 40,
            ((($index * 53) + 110) % 176) + 40
        )

        $brush = New-Object System.Drawing.SolidBrush $color
        $Graphics.FillRectangle($brush, $rect)
        $Graphics.DrawRectangle([System.Drawing.Pens]::Black, $rect)

        if ($rect.Width -gt 60 -and $rect.Height -gt 24) {
            $label = $item.Name
            if ($label.Length -gt 24) {
                $label = $label.Substring(0, 21) + '...'
            }

            $rectF = [System.Drawing.RectangleF]::new($rect.X, $rect.Y, $rect.Width, $rect.Height)
            $Graphics.DrawString($label, $font, [System.Drawing.Brushes]::Black, $rectF, $sf)
        }

        $brush.Dispose()
    }

    $font.Dispose()
    $sf.Dispose()
}

function Save-ControlImage {
    param(
        [System.Windows.Forms.Control]$Control,
        [string]$Path
    )

    $bitmap = New-Object System.Drawing.Bitmap $Control.Width, $Control.Height
    $Control.DrawToBitmap($bitmap, [System.Drawing.Rectangle]::new(0, 0, $Control.Width, $Control.Height))
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

function Draw-ContextMenuOverlay {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )

    $bitmap = [System.Drawing.Image]::FromFile($SourcePath)
    $canvas = New-Object System.Drawing.Bitmap $bitmap.Width, $bitmap.Height
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.DrawImage($bitmap, 0, 0)

    $menuRect = [System.Drawing.Rectangle]::new(675, 145, 170, 56)
    $graphics.FillRectangle([System.Drawing.Brushes]::WhiteSmoke, $menuRect)
    $graphics.DrawRectangle([System.Drawing.Pens]::Gray, $menuRect)
    $graphics.FillRectangle([System.Drawing.Brushes]::LightSkyBlue, 676, 146, 168, 27)

    $font = New-Object System.Drawing.Font('Segoe UI', 9)
    $graphics.DrawString('Open Folder', $font, [System.Drawing.Brushes]::Black, 686, 151)
    $graphics.DrawLine([System.Drawing.Pens]::Gainsboro, 678, 174, 842, 174)
    $graphics.DrawString('Open This Folder', $font, [System.Drawing.Brushes]::Black, 686, 178)

    $canvas.Save($TargetPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $font.Dispose()
    $graphics.Dispose()
    $canvas.Dispose()
    $bitmap.Dispose()
}

function New-MainForm {
    param(
        [string]$TargetPath,
        [switch]$PopulateData
    )

    $treemapItems = @()
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'WinDirStat PowerShell'
    $form.ClientSize = [System.Drawing.Size]::new(920, 640)
    $form.StartPosition = 'Manual'
    $form.Location = [System.Drawing.Point]::new(-2000, 50)
    $form.Font = New-Object System.Drawing.Font('Arial', 9)

    $txtPath = New-Object System.Windows.Forms.TextBox
    $txtPath.Location = [System.Drawing.Point]::new(10, 10)
    $txtPath.Size = [System.Drawing.Size]::new(740, 24)
    $txtPath.Text = if ($PopulateData) { $TargetPath } else { '' }

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Location = [System.Drawing.Point]::new(760, 10)
    $btnBrowse.Size = [System.Drawing.Size]::new(70, 24)
    $btnBrowse.Text = 'Browse'

    $btnScan = New-Object System.Windows.Forms.Button
    $btnScan.Location = [System.Drawing.Point]::new(840, 10)
    $btnScan.Size = [System.Drawing.Size]::new(70, 24)
    $btnScan.Text = 'Scan'

    $chkAutoScan = New-Object System.Windows.Forms.CheckBox
    $chkAutoScan.Location = [System.Drawing.Point]::new(10, 40)
    $chkAutoScan.Size = [System.Drawing.Size]::new(400, 24)
    $chkAutoScan.Text = 'Scan automatically after folder selection'
    $chkAutoScan.Checked = $true

    $btnRoot = New-Object System.Windows.Forms.Button
    $btnRoot.Location = [System.Drawing.Point]::new(680, 40)
    $btnRoot.Size = [System.Drawing.Size]::new(70, 24)
    $btnRoot.Text = 'Parent'

    $btnDocs = New-Object System.Windows.Forms.Button
    $btnDocs.Location = [System.Drawing.Point]::new(760, 40)
    $btnDocs.Size = [System.Drawing.Size]::new(70, 24)
    $btnDocs.Text = 'Docs'

    $btnAbout = New-Object System.Windows.Forms.Button
    $btnAbout.Location = [System.Drawing.Point]::new(840, 40)
    $btnAbout.Size = [System.Drawing.Size]::new(70, 24)
    $btnAbout.Text = 'About'

    $lblHint = New-Object System.Windows.Forms.Label
    $lblHint.Location = [System.Drawing.Point]::new(600, 70)
    $lblHint.Size = [System.Drawing.Size]::new(310, 30)
    $lblHint.Text = 'Double-click a folder to scan it, or right-click an item for more actions.'
    $lblHint.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblHint.ForeColor = [System.Drawing.Color]::Black
    $lblHint.BackColor = [System.Drawing.Color]::LightYellow
    $lblHint.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $lblHint.Font = New-Object System.Drawing.Font('Arial', 8, [System.Drawing.FontStyle]::Bold)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = [System.Drawing.Point]::new(10, 560)
    $lblStatus.Size = [System.Drawing.Size]::new(900, 24)
    $lblStatus.Text = 'Select a folder or drive, then click Scan.'

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = [System.Drawing.Point]::new(10, 590)
    $progressBar.Size = [System.Drawing.Size]::new(900, 20)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100

    $panelMap = New-Object System.Windows.Forms.Panel
    $panelMap.Location = [System.Drawing.Point]::new(10, 70)
    $panelMap.Size = [System.Drawing.Size]::new(580, 480)
    $panelMap.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $panelMap.BackColor = [System.Drawing.Color]::White

    $lv = New-Object System.Windows.Forms.ListView
    $lv.Location = [System.Drawing.Point]::new(600, 102)
    $lv.Size = [System.Drawing.Size]::new(310, 448)
    $lv.View = 'Details'
    $lv.FullRowSelect = $true
    $lv.GridLines = $true
    $lv.Columns.Add('Object', 160) | Out-Null
    $lv.Columns.Add('Type', 70) | Out-Null
    $lv.Columns.Add('Size', 80) | Out-Null
    $lv.Columns.Add('%', 50) | Out-Null

    $imageList = New-Object System.Windows.Forms.ImageList
    $imageList.ImageSize = [System.Drawing.Size]::new(16, 16)
    $imageList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit

    $folderBitmap = New-Object System.Drawing.Bitmap 16, 16
    $folderGraphics = [System.Drawing.Graphics]::FromImage($folderBitmap)
    $folderBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gold)
    $folderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Goldenrod)
    $folderGraphics.Clear([System.Drawing.Color]::Transparent)
    $folderGraphics.FillRectangle($folderBrush, 2, 7, 12, 7)
    $folderGraphics.FillRectangle($folderBrush, 3, 4, 6, 5)
    $folderGraphics.DrawRectangle($folderPen, 2, 7, 12, 7)
    $folderGraphics.DrawRectangle($folderPen, 3, 4, 6, 5)
    $folderGraphics.Dispose()
    $folderBrush.Dispose()
    $folderPen.Dispose()
    $imageList.Images.Add('Folder', $folderBitmap) | Out-Null

    $fileBitmap = New-Object System.Drawing.Bitmap 16, 16
    $fileGraphics = [System.Drawing.Graphics]::FromImage($fileBitmap)
    $fileBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::LightGray)
    $filePen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gray)
    $fileGraphics.Clear([System.Drawing.Color]::Transparent)
    $fileGraphics.FillRectangle($fileBrush, 3, 2, 10, 12)
    $fileBrush.Color = [System.Drawing.Color]::White
    $points = @( [System.Drawing.Point]::new(9, 2), [System.Drawing.Point]::new(13, 6), [System.Drawing.Point]::new(9, 6) )
    $fileGraphics.FillPolygon($fileBrush, $points)
    $fileGraphics.DrawRectangle($filePen, 3, 2, 10, 12)
    $fileGraphics.DrawLine($filePen, 9, 2, 13, 6)
    $fileGraphics.DrawLine($filePen, 9, 2, 9, 6)
    $fileGraphics.Dispose()
    $fileBrush.Dispose()
    $filePen.Dispose()
    $imageList.Images.Add('File', $fileBitmap) | Out-Null

    $lv.SmallImageList = $imageList

    if ($PopulateData) {
        $items = @(Get-ItemSizes -RootPath $TargetPath)
        $treemapItems = $items
        $totalSize = ($items | Measure-Object Size -Sum).Sum
        $folderCount = ($items | Where-Object Type -eq 'Folder').Count
        $fileCount = ($items | Where-Object Type -eq 'File').Count

        foreach ($item in $items) {
            $percent = if ($totalSize -gt 0) { '{0:N2}' -f (($item.Size / $totalSize) * 100) } else { '0.00' }
            $imageKey = if ($item.Type -eq 'Folder') { 'Folder' } else { 'File' }
            $row = New-Object System.Windows.Forms.ListViewItem($item.Name, $imageKey)
            $row.Tag = $item.FullName
            $row.SubItems.Add($item.Type) | Out-Null
            $row.SubItems.Add((Format-Size $item.Size)) | Out-Null
            $row.SubItems.Add($percent) | Out-Null
            if ($item.Type -eq 'Folder') {
                $row.BackColor = [System.Drawing.Color]::LightGoldenrodYellow
            } else {
                $row.BackColor = [System.Drawing.Color]::LightSteelBlue
            }
            $lv.Items.Add($row) | Out-Null
        }

        if ($lv.Items.Count -gt 0) {
            $lv.Items[0].Selected = $true
            $lv.Items[0].Focused = $true
        }

        $progressBar.Value = 100
        $lblStatus.Text = "Analysis completed - Total: $(Format-Size $totalSize) - $folderCount folders, $fileCount files - $($items.Count) items displayed."
    }

    $panelMap.Add_Paint({
        param($unusedSender, $e)

        [void]$unusedSender
        $e.Graphics.Clear([System.Drawing.Color]::White)
        if ($treemapItems -and $treemapItems.Count -gt 0) {
            Draw-Treemap -Graphics $e.Graphics -Bounds $panelMap.ClientRectangle -Items $treemapItems
        }
    })

    $form.Controls.AddRange(@($txtPath, $btnBrowse, $btnScan, $chkAutoScan, $btnRoot, $btnDocs, $btnAbout, $lblHint, $lblStatus, $progressBar, $panelMap, $lv))
    $form.Show()
    [System.Windows.Forms.Application]::DoEvents()
    $panelMap.Refresh()
    [System.Windows.Forms.Application]::DoEvents()

    return $form
}

function New-AboutForm {
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = 'About'
    $aboutForm.ClientSize = [System.Drawing.Size]::new(400, 180)
    $aboutForm.StartPosition = 'Manual'
    $aboutForm.Location = [System.Drawing.Point]::new(-2000, 80)
    $aboutForm.Font = New-Object System.Drawing.Font('Arial', 9)

    $lblDev = New-Object System.Windows.Forms.Label
    $lblDev.Text = 'Developed by Gregory HARGOUS'
    $lblDev.Location = [System.Drawing.Point]::new(10, 10)
    $lblDev.Size = [System.Drawing.Size]::new(380, 25)
    $lblDev.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblDev.Font = New-Object System.Drawing.Font('Arial', 10, [System.Drawing.FontStyle]::Bold)

    $lblSite = New-Object System.Windows.Forms.Label
    $lblSite.Text = 'https://gregland.net'
    $lblSite.Location = [System.Drawing.Point]::new(10, 40)
    $lblSite.Size = [System.Drawing.Size]::new(380, 25)
    $lblSite.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblSite.Font = New-Object System.Drawing.Font('Arial', 9, [System.Drawing.FontStyle]::Underline)
    $lblSite.ForeColor = [System.Drawing.Color]::Blue

    $lblMail = New-Object System.Windows.Forms.Label
    $lblMail.Text = 'gregory.hargous@gmail.com'
    $lblMail.Location = [System.Drawing.Point]::new(10, 65)
    $lblMail.Size = [System.Drawing.Size]::new(380, 25)
    $lblMail.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblMail.Font = New-Object System.Drawing.Font('Arial', 9, [System.Drawing.FontStyle]::Underline)
    $lblMail.ForeColor = [System.Drawing.Color]::Blue

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = 'Close'
    $btnClose.Location = [System.Drawing.Point]::new(150, 100)
    $btnClose.Size = [System.Drawing.Size]::new(100, 35)

    $aboutForm.Controls.AddRange(@($lblDev, $lblSite, $lblMail, $btnClose))
    $aboutForm.Show()
    [System.Windows.Forms.Application]::DoEvents()

    return $aboutForm
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$shotsDir = Join-Path $PSScriptRoot 'screenshots'

$initialForm = New-MainForm -TargetPath $repoRoot
Save-ControlImage -Control $initialForm -Path (Join-Path $shotsDir '01-interface-principale.png')
$initialForm.Close()
$initialForm.Dispose()

$scannedForm = New-MainForm -TargetPath $repoRoot -PopulateData
$scanPath = Join-Path $shotsDir '02-apres-scan.png'
Save-ControlImage -Control $scannedForm -Path $scanPath
Draw-ContextMenuOverlay -SourcePath $scanPath -TargetPath (Join-Path $shotsDir '03-menu-contextuel.png')
$scannedForm.Close()
$scannedForm.Dispose()

$aboutForm = New-AboutForm
Save-ControlImage -Control $aboutForm -Path (Join-Path $shotsDir '04-fenetre-about.png')
$aboutForm.Close()
$aboutForm.Dispose()