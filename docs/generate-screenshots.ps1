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

function Get-WorstAspectRatio {
    param(
        [object[]]$Row,
        [double]$ShortSide,
        [double]$Scale
    )

    if (-not $Row -or $Row.Count -eq 0 -or $ShortSide -le 0 -or $Scale -le 0) { return [double]::PositiveInfinity }

    $sumArea = 0.0
    $maxArea = 0.0
    $minArea = [double]::PositiveInfinity

    foreach ($entry in $Row) {
        $area = [double]$entry.Size * $Scale
        if ($area -le 0) { continue }
        $sumArea += $area
        if ($area -gt $maxArea) { $maxArea = $area }
        if ($area -lt $minArea) { $minArea = $area }
    }

    if ($sumArea -le 0 -or $maxArea -le 0 -or $minArea -eq [double]::PositiveInfinity) { return [double]::PositiveInfinity }

    $sumSquared = $sumArea * $sumArea
    $sideSquared = $ShortSide * $ShortSide

    return [math]::Max(
        ($sideSquared * $maxArea) / $sumSquared,
        $sumSquared / ($sideSquared * $minArea)
    )
}

function Add-TreemapRow {
    param(
        [System.Collections.ArrayList]$Layout,
        [object[]]$Row,
        [double]$X,
        [double]$Y,
        [double]$Width,
        [double]$Height,
        [double]$Scale
    )

    if (-not $Row -or $Row.Count -eq 0 -or $Width -le 0 -or $Height -le 0) {
        return [pscustomobject]@{ X = $X; Y = $Y; Width = $Width; Height = $Height }
    }

    $rowArea = 0.0
    foreach ($entry in $Row) {
        $rowArea += [double]$entry.Size * $Scale
    }

    if ($rowArea -le 0) {
        return [pscustomobject]@{ X = $X; Y = $Y; Width = $Width; Height = $Height }
    }

    if ($Width -ge $Height) {
        $rowHeight = [math]::Min($Height, $rowArea / $Width)
        if ($rowHeight -le 0) { $rowHeight = $Height }

        $offsetX = $X
        $remainingRowWidth = $Width
        for ($index = 0; $index -lt $Row.Count; $index++) {
            $entry = $Row[$index]
            $entryArea = [double]$entry.Size * $Scale
            if ($index -eq $Row.Count - 1) {
                $itemWidth = $remainingRowWidth
            } else {
                $itemWidth = [math]::Min($remainingRowWidth, $entryArea / $rowHeight)
            }

            [void]$Layout.Add([pscustomobject]@{
                Item = $entry
                Rect = [System.Drawing.RectangleF]::new(
                    [float]$offsetX,
                    [float]$Y,
                    [float][math]::Max(0, $itemWidth),
                    [float][math]::Max(0, $rowHeight)
                )
            })

            $offsetX += $itemWidth
            $remainingRowWidth -= $itemWidth
        }

        return [pscustomobject]@{ X = $X; Y = $Y + $rowHeight; Width = $Width; Height = [math]::Max(0, $Height - $rowHeight) }
    }

    $rowWidth = [math]::Min($Width, $rowArea / $Height)
    if ($rowWidth -le 0) { $rowWidth = $Width }

    $offsetY = $Y
    $remainingRowHeight = $Height
    for ($index = 0; $index -lt $Row.Count; $index++) {
        $entry = $Row[$index]
        $entryArea = [double]$entry.Size * $Scale
        if ($index -eq $Row.Count - 1) {
            $itemHeight = $remainingRowHeight
        } else {
            $itemHeight = [math]::Min($remainingRowHeight, $entryArea / $rowWidth)
        }

        [void]$Layout.Add([pscustomobject]@{
            Item = $entry
            Rect = [System.Drawing.RectangleF]::new(
                [float]$X,
                [float]$offsetY,
                [float][math]::Max(0, $rowWidth),
                [float][math]::Max(0, $itemHeight)
            )
        })

        $offsetY += $itemHeight
        $remainingRowHeight -= $itemHeight
    }

    return [pscustomobject]@{ X = $X + $rowWidth; Y = $Y; Width = [math]::Max(0, $Width - $rowWidth); Height = $Height }
}

function New-TreemapLayout {
    param(
        [System.Drawing.Rectangle]$Bounds,
        [object[]]$Items,
        [double]$TotalSize
    )

    $layout = New-Object System.Collections.ArrayList
    if (-not $Items -or $Items.Count -eq 0 -or $TotalSize -le 0 -or $Bounds.Width -le 0 -or $Bounds.Height -le 0) { return $layout }

    $scale = ([double]$Bounds.Width * [double]$Bounds.Height) / $TotalSize
    $available = [pscustomobject]@{ X = [double]$Bounds.X; Y = [double]$Bounds.Y; Width = [double]$Bounds.Width; Height = [double]$Bounds.Height }
    $row = @()

    foreach ($item in $Items) {
        if ($available.Width -le 0 -or $available.Height -le 0) { break }

        $candidateRow = @($row + $item)
        $shortSide = [math]::Min($available.Width, $available.Height)
        $currentScore = Get-WorstAspectRatio -Row $row -ShortSide $shortSide -Scale $scale
        $candidateScore = Get-WorstAspectRatio -Row $candidateRow -ShortSide $shortSide -Scale $scale

        if ($row.Count -eq 0 -or $candidateScore -le $currentScore) {
            $row = $candidateRow
            continue
        }

        $available = Add-TreemapRow -Layout $layout -Row $row -X $available.X -Y $available.Y -Width $available.Width -Height $available.Height -Scale $scale
        $row = @($item)
    }

    if ($row.Count -gt 0 -and $available.Width -gt 0 -and $available.Height -gt 0) {
        $available = Add-TreemapRow -Layout $layout -Row $row -X $available.X -Y $available.Y -Width $available.Width -Height $available.Height -Scale $scale
    }

    return $layout
}

function Show-Treemap {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Rectangle]$Bounds,
        [object[]]$Items
    )

    if (-not $Items -or $Items.Count -eq 0) { return }

    $items = @($Items | Where-Object { $_.Size -gt 0 }) | Sort-Object Size -Descending
    if ($items.Count -eq 0) { return }

    $total = ($items | Measure-Object Size -Sum).Sum
    if ($total -le 0) { return }

    $font = New-Object System.Drawing.Font('Arial', 9)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $layout = New-TreemapLayout -Bounds $Bounds -Items $items -TotalSize $total

    for ($index = 0; $index -lt $layout.Count; $index++) {
        $entry = $layout[$index]
        $item = $entry.Item
        $rect = $entry.Rect

        $color = [System.Drawing.Color]::FromArgb(
            180,
            ((($index * 73) + 50) % 176) + 40,
            ((($index * 137) + 80) % 176) + 40,
            ((($index * 53) + 110) % 176) + 40
        )

        $brush = New-Object System.Drawing.SolidBrush $color
        $Graphics.FillRectangle($brush, $rect)
        $Graphics.DrawRectangle([System.Drawing.Pens]::Black, $rect.X, $rect.Y, $rect.Width, $rect.Height)

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
            Show-Treemap -Graphics $e.Graphics -Bounds $panelMap.ClientRectangle -Items $treemapItems
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