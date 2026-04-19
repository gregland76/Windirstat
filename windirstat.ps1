# WinDirStat PowerShell - Version 1.6
# Developed by Gregory HARGOUS
# Date: 19 April 2026
# Description: A PowerShell script to analyze disk usage with treemap visualization
# History available in docs/changelog.html


Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$form = New-Object System.Windows.Forms.Form
$form.Text = "WinDirStat PowerShell"
$form.ClientSize = [System.Drawing.Size]::new(920, 640)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Arial", 9)

$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = [System.Drawing.Point]::new(10, 10)
$txtPath.Size = [System.Drawing.Size]::new(740, 24)
$txtPath.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Location = [System.Drawing.Point]::new(760, 10)
$btnBrowse.Size = [System.Drawing.Size]::new(70, 24)
$btnBrowse.Text = "Browse"
$btnBrowse.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Location = [System.Drawing.Point]::new(840, 10)
$btnScan.Size = [System.Drawing.Size]::new(70, 24)
$btnScan.Text = "Scan"
$btnScan.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

$chkAutoScan = New-Object System.Windows.Forms.CheckBox
$chkAutoScan.Location = [System.Drawing.Point]::new(10, 40)
$chkAutoScan.Size = [System.Drawing.Size]::new(400, 24)
$chkAutoScan.Text = "Scan automatically after folder selection"
$chkAutoScan.Checked = $true
$chkAutoScan.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

$btnRoot = New-Object System.Windows.Forms.Button
$btnRoot.Location = [System.Drawing.Point]::new(680, 40)
$btnRoot.Size = [System.Drawing.Size]::new(70, 24)
$btnRoot.Text = "Parent"
$btnRoot.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

$btnDocs = New-Object System.Windows.Forms.Button
$btnDocs.Location = [System.Drawing.Point]::new(760, 40)
$btnDocs.Size = [System.Drawing.Size]::new(70, 24)
$btnDocs.Text = "Docs"
$btnDocs.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

$btnAbout = New-Object System.Windows.Forms.Button
$btnAbout.Location = [System.Drawing.Point]::new(840, 40)
$btnAbout.Size = [System.Drawing.Size]::new(70, 24)
$btnAbout.Text = "About"
$btnAbout.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Location = [System.Drawing.Point]::new(600, 70)
$lblHint.Size = [System.Drawing.Size]::new(310, 30)
$lblHint.Text = "Double-click a folder to scan it, or right-click an item for more actions."
$lblHint.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblHint.ForeColor = [System.Drawing.Color]::Black
$lblHint.BackColor = [System.Drawing.Color]::LightYellow
$lblHint.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$lblHint.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
$lblHint.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = [System.Drawing.Point]::new(10, 560)
$lblStatus.Size = [System.Drawing.Size]::new(900, 24)
$lblStatus.Text = "Select a folder or drive, then click Scan."
$lblStatus.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = [System.Drawing.Point]::new(10, 590)
$progressBar.Size = [System.Drawing.Size]::new(900, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$panelMap = New-Object System.Windows.Forms.Panel
$panelMap.Location = [System.Drawing.Point]::new(10, 70)
$panelMap.Size = [System.Drawing.Size]::new(580, 480)
$panelMap.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$panelMap.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
$panelMap.BackColor = [System.Drawing.Color]::White

$lv = New-Object System.Windows.Forms.ListView
$lv.Location = [System.Drawing.Point]::new(600, 102)
$lv.Size = [System.Drawing.Size]::new(310, 448)
$lv.View = 'Details'
$lv.FullRowSelect = $true
$lv.GridLines = $true
$lv.Columns.Add("Object", 160) | Out-Null
$lv.Columns.Add("Type", 70) | Out-Null
$lv.Columns.Add("Size", 80) | Out-Null
$lv.Columns.Add("%", 50) | Out-Null

$imageList = New-Object System.Windows.Forms.ImageList
$imageList.ImageSize = [System.Drawing.Size]::new(16, 16)
$imageList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit

$folderBitmap = New-Object System.Drawing.Bitmap 16, 16
$g = [System.Drawing.Graphics]::FromImage($folderBitmap)
$g.Clear([System.Drawing.Color]::Transparent)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gold)
$g.FillRectangle($brush, 2, 7, 12, 7)
$g.FillRectangle($brush, 3, 4, 6, 5)
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Goldenrod)
$g.DrawRectangle($pen, 2, 7, 12, 7)
$g.DrawRectangle($pen, 3, 4, 6, 5)
$g.Dispose(); $brush.Dispose(); $pen.Dispose()
$imageList.Images.Add('Folder', $folderBitmap)

$fileBitmap = New-Object System.Drawing.Bitmap 16, 16
$g = [System.Drawing.Graphics]::FromImage($fileBitmap)
$g.Clear([System.Drawing.Color]::Transparent)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::LightGray)
$g.FillRectangle($brush, 3, 2, 10, 12)
$brush.Color = [System.Drawing.Color]::White
$points = @( [System.Drawing.Point]::new(9,2), [System.Drawing.Point]::new(13,6), [System.Drawing.Point]::new(9,6) )
$g.FillPolygon($brush, $points)
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gray)
$g.DrawRectangle($pen, 3, 2, 10, 12)
$g.DrawLine($pen, 9,2,13,6)
$g.DrawLine($pen, 9,2,9,6)
$g.Dispose(); $brush.Dispose(); $pen.Dispose()
$imageList.Images.Add('File', $fileBitmap)

$lv.SmallImageList = $imageList
$lv.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

$listContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuOpenItem = $listContextMenu.Items.Add("Open")
$menuOpenFolder = $listContextMenu.Items.Add("Open Folder")

$lv.ContextMenuStrip = $listContextMenu

function Update-Layout {
    $newPanelWidth = [math]::Max(250, $form.ClientSize.Width - $lv.Width - 30)
    $panelMap.Width = $newPanelWidth
}

$form.Add_Resize({ Update-Layout })

$lv.Add_DoubleClick({
    if ($lv.SelectedItems.Count -eq 0) { return }
    $item = $lv.SelectedItems[0]
    if ($item.SubItems[1].Text -eq 'Folder' -and $item.Tag) {
            $txtPath.Text = $item.Tag
            Perform-Scan $false
        }
})

$lv.Add_MouseDown({
    param($sender, $e)

    [void]$sender

    if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Right) { return }

    $hit = $lv.HitTest($e.Location)
    if (-not $hit.Item) {
        $lv.SelectedItems.Clear()
        return
    }

    $lv.SelectedItems.Clear()
    $hit.Item.Selected = $true
    $hit.Item.Focused = $true
})

$listContextMenu.Add_Opening({
    param($sender, $e)

    [void]$sender

    if ($lv.SelectedItems.Count -eq 0) {
        $e.Cancel = $true
        return
    }

    $selectedItem = $lv.SelectedItems[0]
    $isFolder = $selectedItem.SubItems[1].Text -eq 'Folder'
    $menuOpenItem.Text = if ($isFolder) { 'Open Folder' } else { 'Open File' }
    $menuOpenFolder.Text = if ($isFolder) { 'Open This Folder' } else { 'Go To Containing Folder' }
})

$menuOpenItem.Add_Click({
    if ($lv.SelectedItems.Count -eq 0) { return }
    Invoke-ListViewItemOpen -Item $lv.SelectedItems[0]
})

$menuOpenFolder.Add_Click({
    if ($lv.SelectedItems.Count -eq 0) { return }
    Invoke-ListViewItemFolderOpen -Item $lv.SelectedItems[0]
})

$form.Controls.AddRange(@($txtPath, $btnBrowse, $btnScan, $btnRoot, $btnDocs, $chkAutoScan, $btnAbout, $lblHint, $lblStatus, $progressBar, $panelMap, $lv))
$form.Add_Shown({
    Update-Layout
    $panelMap.Invalidate()
    $panelMap.Refresh()
})

$treemapItems = @()
$totalSize = 0

function Format-Size {
    param([int64]$Size)
    if ($Size -ge 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
    if ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    return "$Size B"
}

function Invoke-ListViewItemOpen {
    param([System.Windows.Forms.ListViewItem]$Item)

    if (-not $Item -or -not $Item.Tag) { return }

    $targetPath = [string]$Item.Tag
    if (-not (Test-Path -LiteralPath $targetPath)) {
        [System.Windows.Forms.MessageBox]::Show("The selected item no longer exists.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    try {
        Start-Process -FilePath $targetPath | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Unable to open the selected item: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

function Invoke-ListViewItemFolderOpen {
    param([System.Windows.Forms.ListViewItem]$Item)

    if (-not $Item -or -not $Item.Tag) { return }

    $targetPath = [string]$Item.Tag
    if (-not (Test-Path -LiteralPath $targetPath)) {
        [System.Windows.Forms.MessageBox]::Show("The selected item no longer exists.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    try {
        if ($Item.SubItems[1].Text -eq 'Folder') {
            Start-Process -FilePath $targetPath | Out-Null
        } else {
            Start-Process -FilePath 'explorer.exe' -ArgumentList ('/select,"{0}"' -f $targetPath) | Out-Null
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Unable to open the containing folder: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

function Get-ItemSizes {
    param([string]$RootPath)

    $items = @()
    try {
        $rootItem = Get-Item -LiteralPath $RootPath -ErrorAction Stop
    } catch {
        return $items
    }

    if ($rootItem.PSIsContainer) {
        $children = Get-ChildItem -LiteralPath $RootPath -Force -ErrorAction SilentlyContinue
        foreach ($child in $children) {
            if ($child.PSIsContainer) {
                $size = 0
                try {
                    $size = (Get-ChildItem -LiteralPath $child.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                } catch {}
                $items += [PSCustomObject]@{
                    Name     = $child.Name
                    FullName = $child.FullName
                    Type     = "Folder"
                    Size     = [int64]$size
                }
            } else {
                $items += [PSCustomObject]@{
                    Name     = $child.Name
                    FullName = $child.FullName
                    Type     = "File"
                    Size     = [int64]$child.Length
                }
            }
        }
    } else {
        $items += [PSCustomObject]@{
            Name     = $rootItem.Name
            FullName = $rootItem.FullName
            Type     = "File"
            Size     = [int64]$rootItem.Length
        }
    }

    return $items
}

function Draw-Treemap {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Rectangle]$Bounds,
        $Items
    )

    if (-not $Items) { return }

    $items = @($Items) | Sort-Object Size -Descending
    if ($items.Count -eq 0) { return }

    $total = ($items | Measure-Object Size -Sum).Sum
    if ($total -le 0) { return }

    $font = New-Object System.Drawing.Font("Arial", 9)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $horizontal = $Bounds.Width -ge $Bounds.Height
    $offsetX = $Bounds.X
    $offsetY = $Bounds.Y
    $remainingWidth = $Bounds.Width
    $remainingHeight = $Bounds.Height

    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        if ($horizontal) {
            $width = [math]::Max(1, [int](($item.Size / $total) * $Bounds.Width))
            if ($i -eq $items.Count - 1) { $width = $remainingWidth }
            $rect = [System.Drawing.Rectangle]::new($offsetX, $offsetY, $width, $remainingHeight)
            $offsetX += $width
            $remainingWidth -= $width
        } else {
            $height = [math]::Max(1, [int](($item.Size / $total) * $Bounds.Height))
            if ($i -eq $items.Count - 1) { $height = $remainingHeight }
            $rect = [System.Drawing.Rectangle]::new($offsetX, $offsetY, $remainingWidth, $height)
            $offsetY += $height
            $remainingHeight -= $height
        }

        $color = [System.Drawing.Color]::FromArgb(
            180,
            ((($i * 73) + 50) % 176) + 40,
            ((($i * 137) + 80) % 176) + 40,
            ((($i * 53) + 110) % 176) + 40
        )
        $brush = New-Object System.Drawing.SolidBrush $color
        $Graphics.FillRectangle($brush, $rect)
        $Graphics.DrawRectangle([System.Drawing.Pens]::Black, $rect)

        if ($rect.Width -gt 60 -and $rect.Height -gt 24) {
            $label = $item.Name
            if ($label.Length -gt 24) {
                $label = $label.Substring(0, 21) + "..."
            }
            $rectF = [System.Drawing.RectangleF]::new($rect.X, $rect.Y, $rect.Width, $rect.Height)
            $Graphics.DrawString($label, $font, [System.Drawing.Brushes]::Black, $rectF, $sf)
        }
        $brush.Dispose()
    }

    $font.Dispose()
    $sf.Dispose()
}

function Perform-Scan {
    param([bool]$setRoot = $true)

    $path = $txtPath.Text.Trim()
    if (-not $path) {
        [System.Windows.Forms.MessageBox]::Show("Please select a folder or drive.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    if ($setRoot) {
        $global:RootPath = $path
    }

    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("The path does not exist.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    $btnScan.Enabled = $false
    $btnBrowse.Enabled = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $lblStatus.Text = "Analysis in progress..."
    $progressBar.Value = 0
    $lv.Items.Clear()
    $treemapItems = @()
    $totalSize = 0

    try {
        $items = Get-ItemSizes -RootPath $path
        $totalSize = ($items | Measure-Object Size -Sum).Sum
        $items = $items | Sort-Object Size -Descending
        if ($items.Count -gt 50) {
            $items = $items | Select-Object -First 50
        }
        $treemapItems = $items
        $folderCount = ($items | Where-Object Type -eq 'Folder').Count
        $fileCount = ($items | Where-Object Type -eq 'File').Count

        $counter = 0
        foreach ($item in $items) {
            $percent = if ($totalSize -gt 0) { "{0:N2}" -f (($item.Size / $totalSize) * 100) } else { "0.00" }
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
            $counter++
            if ($items.Count -gt 0) {
                $progressBar.Value = [math]::Min(100, [int]($counter / $items.Count * 100))
            }
        }
        $progressBar.Value = 100

        if ($items.Count -eq 0) {
            $lblStatus.Text = "Analysis completed: no items found in the folder."
        } else {
            $lblStatus.Text = "Analysis completed - Total: $(Format-Size $totalSize) - $folderCount folders, $fileCount files - $(($items.Count)) items displayed."
        }
        $panelMap.Invalidate()
        $panelMap.Refresh()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error during analysis: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } finally {
        $btnScan.Enabled = $true
        $btnBrowse.Enabled = $true
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
}

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Choose a folder or drive to analyze"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPath.Text = $dialog.SelectedPath
        if ($chkAutoScan.Checked) {
            Perform-Scan
        }
    }
})

$btnScan.Add_Click({
    Perform-Scan $true
})

$btnRoot.Add_Click({
    $currentPath = $txtPath.Text.Trim()
    if (-not $currentPath) {
        [System.Windows.Forms.MessageBox]::Show("Please select a folder or drive first.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    try {
        $parentPath = Split-Path -Path $currentPath -Parent
    } catch {
        $parentPath = $null
    }

    if (-not $parentPath) {
        [System.Windows.Forms.MessageBox]::Show("No parent folder available.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    $txtPath.Text = $parentPath
    Perform-Scan $true
})

$btnDocs.Add_Click({
    $scriptRoot = if ($PSCommandPath) {
        Split-Path -Parent $PSCommandPath
    } else {
        (Get-Location).Path
    }

    $docsHtmlPath = Join-Path $scriptRoot "docs/help.html"
    $docsFilePath = Join-Path $scriptRoot "docs/help.md"
    $docsFolderPath = Join-Path $scriptRoot "docs"

    try {
        if (Test-Path -LiteralPath $docsHtmlPath) {
            Start-Process -FilePath $docsHtmlPath | Out-Null
        } elseif (Test-Path -LiteralPath $docsFilePath) {
            Start-Process -FilePath $docsFilePath | Out-Null
        } elseif (Test-Path -LiteralPath $docsFolderPath) {
            Start-Process -FilePath $docsFolderPath | Out-Null
        } else {
            [System.Windows.Forms.MessageBox]::Show("Documentation not found. Expected path: $docsHtmlPath", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Unable to open documentation: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$btnAbout.Add_Click({
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "About"
    $aboutForm.Size = [System.Drawing.Size]::new(400, 180)
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.Font = New-Object System.Drawing.Font("Arial", 9)
    $aboutForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

    $lblDev = New-Object System.Windows.Forms.Label
    $lblDev.Text = "Developed by Gregory HARGOUS"
    $lblDev.Location = [System.Drawing.Point]::new(10, 10)
    $lblDev.Size = [System.Drawing.Size]::new(380, 25)
    $lblDev.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblDev.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)

    $lblSite = New-Object System.Windows.Forms.Label
    $lblSite.Text = "https://gregland.net"
    $lblSite.Location = [System.Drawing.Point]::new(10, 40)
    $lblSite.Size = [System.Drawing.Size]::new(380, 25)
    $lblSite.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblSite.Font = New-Object System.Drawing.Font("Arial", 9, [System.Drawing.FontStyle]::Underline)
    $lblSite.ForeColor = [System.Drawing.Color]::Blue
    $lblSite.Cursor = [System.Windows.Forms.Cursors]::Hand
    $lblSite.Add_Click({ Start-Process "https://gregland.net" })

    $lblMail = New-Object System.Windows.Forms.Label
    $lblMail.Text = "gregory.hargous@gmail.com"
    $lblMail.Location = [System.Drawing.Point]::new(10, 65)
    $lblMail.Size = [System.Drawing.Size]::new(380, 25)
    $lblMail.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblMail.Font = New-Object System.Drawing.Font("Arial", 9, [System.Drawing.FontStyle]::Underline)
    $lblMail.ForeColor = [System.Drawing.Color]::Blue
    $lblMail.Cursor = [System.Windows.Forms.Cursors]::Hand
    $lblMail.Add_Click({ Start-Process "mailto:gregory.hargous@gmail.com" })

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = [System.Drawing.Point]::new(150, 100)
    $btnClose.Size = [System.Drawing.Size]::new(100, 35)
    $btnClose.Add_Click({ $aboutForm.Close() })

    $aboutForm.Controls.AddRange(@($lblDev, $lblSite, $lblMail, $btnClose))
    [void]$aboutForm.ShowDialog()
})

$panelMap.Add_Paint({
    param($sender, $e)
    try {
        $e.Graphics.Clear([System.Drawing.Color]::White)
        if ($treemapItems -and $treemapItems.Count -gt 0) {
            Draw-Treemap -Graphics $e.Graphics -Bounds $panelMap.ClientRectangle -Items $treemapItems
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error displaying treemap: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

[void]$form.ShowDialog()
