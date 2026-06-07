# WinDirStat PowerShell - Version 1.13
# Developpe par Gregory HARGOUS
# Date : 07 juin 2026
# Description : Un script PowerShell pour analyser l'utilisation du disque avec une visualisation treemap
# Historique disponible dans docs/changelog.md et docs/changelog.html


Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not $global:WinDirStatWinFormsInitialized) {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    try {
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    } catch [System.InvalidOperationException] {
        # Happens when WinForms has already created an IWin32Window in this process.
    }
    $global:WinDirStatWinFormsInitialized = $true
}

# === Formulaire principal modernise ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "WinDirStat PowerShell"
$form.ClientSize = [System.Drawing.Size]::new(960, 660)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)

# --- Barre de titre personnalisee ---
$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Size = [System.Drawing.Size]::new(960, 42)
$titleBar.Location = [System.Drawing.Point]::new(0, 0)
$titleBar.BackColor = [System.Drawing.Color]::FromArgb(30, 50, 100)
$titleBar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

# Mini logo dans la barre de titre
$titleLogoBitmap = New-Object System.Drawing.Bitmap(28, 28)
$tlg = [System.Drawing.Graphics]::FromImage($titleLogoBitmap)
$tlg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$tlg.Clear([System.Drawing.Color]::Transparent)
$tlBrush1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 180, 255))
$tlg.FillEllipse($tlBrush1, 2, 2, 24, 24)
$tlBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 60))
$tlBrush3 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 100, 80))
$tlBrush4 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 200, 120))
$tlg.FillRectangle($tlBrush2, 7, 7, 10, 6)
$tlg.FillRectangle($tlBrush3, 17, 7, 5, 6)
$tlg.FillRectangle($tlBrush4, 7, 13, 7, 8)
$tlBrush5 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 120, 220))
$tlg.FillRectangle($tlBrush5, 14, 13, 8, 8)
$tlg.Dispose(); $tlBrush1.Dispose(); $tlBrush2.Dispose(); $tlBrush3.Dispose(); $tlBrush4.Dispose(); $tlBrush5.Dispose()

$titleLogoBox = New-Object System.Windows.Forms.PictureBox
$titleLogoBox.Image = $titleLogoBitmap
$titleLogoBox.Size = [System.Drawing.Size]::new(28, 28)
$titleLogoBox.Location = [System.Drawing.Point]::new(12, 7)
$titleLogoBox.BackColor = [System.Drawing.Color]::Transparent
$titleLogoBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage

$lblAppTitle = New-Object System.Windows.Forms.Label
$lblAppTitle.Text = "WinDirStat PowerShell"
$lblAppTitle.Location = [System.Drawing.Point]::new(46, 0)
$lblAppTitle.Size = [System.Drawing.Size]::new(280, 42)
$lblAppTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblAppTitle.ForeColor = [System.Drawing.Color]::White
$lblAppTitle.BackColor = [System.Drawing.Color]::Transparent
$lblAppTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

$lblAppSub = New-Object System.Windows.Forms.Label
$lblAppSub.Text = "v1.13 - Analyse d'espace disque"
$lblAppSub.Location = [System.Drawing.Point]::new(330, 0)
$lblAppSub.Size = [System.Drawing.Size]::new(620, 42)
$lblAppSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblAppSub.ForeColor = [System.Drawing.Color]::FromArgb(160, 190, 230)
$lblAppSub.BackColor = [System.Drawing.Color]::Transparent
$lblAppSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$lblAppSub.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

$titleBar.Controls.AddRange(@($titleLogoBox, $lblAppTitle, $lblAppSub))

# --- Barre d'outils (fond clair) ---
$toolbarPanel = New-Object System.Windows.Forms.Panel
$toolbarPanel.Location = [System.Drawing.Point]::new(0, 42)
$toolbarPanel.Size = [System.Drawing.Size]::new(960, 80)
$toolbarPanel.BackColor = [System.Drawing.Color]::White
$toolbarPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

# Separateur sous la barre de titre
$sepTitle = New-Object System.Windows.Forms.Label
$sepTitle.Size = [System.Drawing.Size]::new(960, 1)
$sepTitle.Location = [System.Drawing.Point]::new(0, 0)
$sepTitle.BackColor = [System.Drawing.Color]::FromArgb(200, 210, 220)
$sepTitle.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

# Etiquette "Chemin :"
$lblPathLabel = New-Object System.Windows.Forms.Label
$lblPathLabel.Text = "Chemin :"
$lblPathLabel.Location = [System.Drawing.Point]::new(12, 8)
$lblPathLabel.Size = [System.Drawing.Size]::new(62, 36)
$lblPathLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblPathLabel.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$lblPathLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

# TextBox modernisee
$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = [System.Drawing.Point]::new(76, 8)
$txtPath.Size = [System.Drawing.Size]::new(636, 36)
$txtPath.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$txtPath.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtPath.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
$txtPath.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

# Fonction helper pour creer des boutons modernes
function New-ModernButton {
    param($Text, $X, $Y, $Width, $Height, $BgColor, $Anchor)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = [System.Drawing.Point]::new($X, $Y)
    $btn.Size = [System.Drawing.Size]::new($Width, $Height)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.BackColor = $BgColor
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $btn.FlatAppearance.BorderSize = 0
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.TabStop = $false
    $btn.Anchor = $Anchor
    return $btn
}

# Ligne 1 : Parcourir puis Analyser
$btnBrowse = New-ModernButton -Text "Parcourir" -X 720 -Y 8 -Width 110 -Height 28 -BgColor ([System.Drawing.Color]::FromArgb(30, 100, 200)) -Anchor ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right)
$btnScan = New-ModernButton -Text "Analyser" -X 838 -Y 8 -Width 100 -Height 28 -BgColor ([System.Drawing.Color]::FromArgb(0, 150, 100)) -Anchor ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right)

# Ligne 2 : checkbox + boutons secondaires
$chkAutoScan = New-Object System.Windows.Forms.CheckBox
$chkAutoScan.Location = [System.Drawing.Point]::new(12, 52)
$chkAutoScan.Size = [System.Drawing.Size]::new(400, 22)
$chkAutoScan.Text = "Analyser automatiquement apres selection du dossier"
$chkAutoScan.Checked = $true
$chkAutoScan.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$chkAutoScan.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$chkAutoScan.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left

$btnRoot = New-ModernButton -Text "Dossier parent" -X 690 -Y 50 -Width 110 -Height 26 -BgColor ([System.Drawing.Color]::FromArgb(120, 130, 150)) -Anchor ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right)
$btnDocs = New-ModernButton -Text "Aide" -X 806 -Y 50 -Width 55 -Height 26 -BgColor ([System.Drawing.Color]::FromArgb(140, 120, 180)) -Anchor ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right)
$btnAbout = New-ModernButton -Text "A propos" -X 867 -Y 50 -Width 75 -Height 26 -BgColor ([System.Drawing.Color]::FromArgb(30, 50, 100)) -Anchor ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right)

$toolbarPanel.Controls.AddRange(@($sepTitle, $lblPathLabel, $txtPath, $btnScan, $btnBrowse, $chkAutoScan, $btnRoot, $btnDocs, $btnAbout))

# --- SplitContainer principal ---
$splitMain = New-Object System.Windows.Forms.SplitContainer
$splitMain.Location = [System.Drawing.Point]::new(8, 130)
$splitMain.Size = [System.Drawing.Size]::new(944, 490)
$splitMain.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$splitMain.Orientation = [System.Windows.Forms.Orientation]::Vertical
$splitMain.SplitterWidth = 5
$splitMain.Panel1MinSize = 250
$splitMain.Panel2MinSize = 260
$splitMain.SplitterDistance = 580
$splitMain.BackColor = [System.Drawing.Color]::FromArgb(200, 210, 220)

# --- Panneau Treemap ---
$panelMapContainer = New-Object System.Windows.Forms.Panel
$panelMapContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$panelMapContainer.Padding = [System.Windows.Forms.Padding]::new(1)
$panelMapContainer.BackColor = [System.Drawing.Color]::FromArgb(180, 190, 200)

$panelMap = New-Object System.Windows.Forms.Panel
$panelMap.Dock = [System.Windows.Forms.DockStyle]::Fill
$panelMap.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$panelMap.BackColor = [System.Drawing.Color]::White

$panelMapContainer.Controls.Add($panelMap)

# --- Panneau Liste ---
$panelListContainer = New-Object System.Windows.Forms.Panel
$panelListContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$panelListContainer.BackColor = [System.Drawing.Color]::White

# Indice d'utilisation moderne
$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Dock = [System.Windows.Forms.DockStyle]::Top
$lblHint.Height = 26
$lblHint.Text = "  Double-cliquez sur un dossier pour l'analyser, ou faites un clic droit pour plus d'actions."
$lblHint.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$lblHint.ForeColor = [System.Drawing.Color]::FromArgb(80, 100, 130)
$lblHint.BackColor = [System.Drawing.Color]::FromArgb(235, 240, 248)
$lblHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)

$lv = New-Object System.Windows.Forms.ListView
$lv.Dock = [System.Windows.Forms.DockStyle]::Fill
$lv.View = 'Details'
$lv.FullRowSelect = $true
$lv.GridLines = $false
$lv.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$lv.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable
$lv.Columns.Add("Objet", 160) | Out-Null
$lv.Columns.Add("Type", 70) | Out-Null
$lv.Columns.Add("Taille", 80) | Out-Null
$lv.Columns.Add("%", 50) | Out-Null

$lv.BackColor = [System.Drawing.Color]::White
$lv.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)

$panelListContainer.Controls.Add($lv)
$panelListContainer.Controls.Add($lblHint)

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

$listContextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuOpenItem = $listContextMenu.Items.Add("Ouvrir")
$menuOpenFolder = $listContextMenu.Items.Add("Ouvrir le dossier")

$lv.ContextMenuStrip = $listContextMenu

$splitMain.Panel1.Controls.Add($panelMapContainer)
$splitMain.Panel2.Controls.Add($panelListContainer)
$splitMain.Add_SplitterMoved({
    Update-TreemapDisplay
})

$panelMap.Add_Resize({
    Update-TreemapDisplay
})

$lv.Add_DoubleClick({
    if ($lv.SelectedItems.Count -eq 0) { return }
    $item = $lv.SelectedItems[0]
    if ($item.SubItems[1].Text -eq 'Dossier' -and $item.Tag) {
        $txtPath.Text = $item.Tag
        Start-Scan $false
    }
})

$lv.Add_MouseDown({
    param($control, $e)

    [void]$control

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
    param($control, $e)

    [void]$control

    if ($lv.SelectedItems.Count -eq 0) {
        $e.Cancel = $true
        return
    }

    $selectedItem = $lv.SelectedItems[0]
    $isFolder = $selectedItem.SubItems[1].Text -eq 'Dossier'
    $menuOpenItem.Text = if ($isFolder) { 'Ouvrir le dossier' } else { 'Ouvrir le fichier' }
    $menuOpenFolder.Text = if ($isFolder) { 'Ouvrir ce dossier' } else { 'Aller au dossier parent' }
})

$menuOpenItem.Add_Click({
    if ($lv.SelectedItems.Count -eq 0) { return }
    Invoke-ListViewItemOpen -Item $lv.SelectedItems[0]
})

$menuOpenFolder.Add_Click({
    if ($lv.SelectedItems.Count -eq 0) { return }
    Invoke-ListViewItemFolderOpen -Item $lv.SelectedItems[0]
})

# --- Barre d'etat modernisee ---
$statusBar = New-Object System.Windows.Forms.Panel
$statusBar.Size = [System.Drawing.Size]::new(960, 30)
$statusBar.Location = [System.Drawing.Point]::new(0, 630)
$statusBar.BackColor = [System.Drawing.Color]::FromArgb(240, 242, 245)
$statusBar.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$sepStatus = New-Object System.Windows.Forms.Label
$sepStatus.Size = [System.Drawing.Size]::new(960, 1)
$sepStatus.Location = [System.Drawing.Point]::new(0, 0)
$sepStatus.BackColor = [System.Drawing.Color]::FromArgb(200, 210, 220)
$sepStatus.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = [System.Drawing.Point]::new(12, 2)
$lblStatus.Size = [System.Drawing.Size]::new(936, 26)
$lblStatus.Text = "  Selectionnez un dossier ou un lecteur, puis cliquez sur Analyser."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(100, 110, 130)
$lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$lblStatus.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = [System.Drawing.Point]::new(0, 636)
$progressBar.Size = [System.Drawing.Size]::new(960, 4)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$progressBar.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$statusBar.Controls.AddRange(@($sepStatus, $lblStatus))

$form.Controls.AddRange(@($titleBar, $toolbarPanel, $splitMain, $statusBar, $progressBar))
$form.Add_Shown({
    Update-TreemapDisplay
})

$script:treemapItems = @()
$script:treemapHitRegions = @()
$script:lastTreemapTooltipText = ""
$script:panelMapBitmap = $null
$totalSize = 0

$treemapToolTip = New-Object System.Windows.Forms.ToolTip
$treemapToolTip.InitialDelay = 120
$treemapToolTip.ReshowDelay = 80
$treemapToolTip.AutoPopDelay = 5000
$treemapToolTip.ShowAlways = $true

function Format-Size {
    param([int64]$Size)
    if ($Size -ge 1TB) { return "{0:N2} To" -f ($Size / 1TB) }
    if ($Size -ge 1GB) { return "{0:N2} Go" -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return "{0:N2} Mo" -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return "{0:N2} Ko" -f ($Size / 1KB) }
    return "$Size o"
}

function Invoke-ListViewItemOpen {
    param([System.Windows.Forms.ListViewItem]$Item)

    if (-not $Item -or -not $Item.Tag) { return }

    $targetPath = [string]$Item.Tag
    if (-not (Test-Path -LiteralPath $targetPath)) {
        [System.Windows.Forms.MessageBox]::Show("L'element selectionne n'existe plus.", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    try {
        Start-Process -FilePath $targetPath | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Impossible d'ouvrir l'element selectionne : $_", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

function Invoke-ListViewItemFolderOpen {
    param([System.Windows.Forms.ListViewItem]$Item)

    if (-not $Item -or -not $Item.Tag) { return }

    $targetPath = [string]$Item.Tag
    if (-not (Test-Path -LiteralPath $targetPath)) {
        [System.Windows.Forms.MessageBox]::Show("L'element selectionne n'existe plus.", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    try {
        if ($Item.SubItems[1].Text -eq 'Dossier') {
            Start-Process -FilePath $targetPath | Out-Null
        } else {
            Start-Process -FilePath 'explorer.exe' -ArgumentList ('/select,"{0}"' -f $targetPath) | Out-Null
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Impossible d'ouvrir le dossier parent : $_", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
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
                    Type     = "Dossier"
                    Size     = [int64]$size
                }
            } else {
                $items += [PSCustomObject]@{
                    Name     = $child.Name
                    FullName = $child.FullName
                    Type     = "Fichier"
                    Size     = [int64]$child.Length
                }
            }
        }
    } else {
        $items += [PSCustomObject]@{
            Name     = $rootItem.Name
            FullName = $rootItem.FullName
            Type     = "Fichier"
            Size     = [int64]$rootItem.Length
        }
    }

    return $items
}

function Get-WorstAspectRatio {
    param(
        [object[]]$Row,
        [double]$ShortSide,
        [double]$Scale
    )

    if (-not $Row -or $Row.Count -eq 0 -or $ShortSide -le 0 -or $Scale -le 0) {
        return [double]::PositiveInfinity
    }

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

    if ($sumArea -le 0 -or $maxArea -le 0 -or $minArea -eq [double]::PositiveInfinity) {
        return [double]::PositiveInfinity
    }

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
        return [pscustomobject]@{
            X = $X
            Y = $Y
            Width = $Width
            Height = $Height
        }
    }

    $rowArea = 0.0
    foreach ($entry in $Row) {
        $rowArea += [double]$entry.Size * $Scale
    }

    if ($rowArea -le 0) {
        return [pscustomobject]@{
            X = $X
            Y = $Y
            Width = $Width
            Height = $Height
        }
    }

    if ($Width -ge $Height) {
        $rowHeight = [math]::Min($Height, $rowArea / $Width)
        if ($rowHeight -le 0) {
            $rowHeight = $Height
        }

        $offsetX = $X
        $remainingRowWidth = $Width
        for ($i = 0; $i -lt $Row.Count; $i++) {
            $entry = $Row[$i]
            $entryArea = [double]$entry.Size * $Scale
            if ($i -eq $Row.Count - 1) {
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

        return [pscustomobject]@{
            X = $X
            Y = $Y + $rowHeight
            Width = $Width
            Height = [math]::Max(0, $Height - $rowHeight)
        }
    }

    $rowWidth = [math]::Min($Width, $rowArea / $Height)
    if ($rowWidth -le 0) {
        $rowWidth = $Width
    }

    $offsetY = $Y
    $remainingRowHeight = $Height
    for ($i = 0; $i -lt $Row.Count; $i++) {
        $entry = $Row[$i]
        $entryArea = [double]$entry.Size * $Scale
        if ($i -eq $Row.Count - 1) {
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

    return [pscustomobject]@{
        X = $X + $rowWidth
        Y = $Y
        Width = [math]::Max(0, $Width - $rowWidth)
        Height = $Height
    }
}

function New-TreemapLayout {
    param(
        [System.Drawing.Rectangle]$Bounds,
        [object[]]$Items,
        [double]$TotalSize
    )

    $layout = New-Object System.Collections.ArrayList
    if (-not $Items -or $Items.Count -eq 0 -or $TotalSize -le 0 -or $Bounds.Width -le 0 -or $Bounds.Height -le 0) {
        return $layout
    }

    $scale = ([double]$Bounds.Width * [double]$Bounds.Height) / $TotalSize
    $available = [pscustomobject]@{
        X = [double]$Bounds.X
        Y = [double]$Bounds.Y
        Width = [double]$Bounds.Width
        Height = [double]$Bounds.Height
    }

    $row = @()
    foreach ($item in $Items) {
        if ($available.Width -le 0 -or $available.Height -le 0) {
            break
        }

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
        $Items
    )

    if (-not $Items) { return }

    $items = @(
        $Items |
        Where-Object { $_.Size -gt 0 } |
        ForEach-Object {
            [PSCustomObject]@{
                Name        = $_.Name
                FullName    = $_.FullName
                Type        = $_.Type
                Size        = [int64]$_.Size
                DisplaySize = [int64]$_.Size
            }
        }
    ) | Sort-Object Size -Descending

    if ($items.Count -eq 0) {
        $items = @(
            $Items |
            Where-Object { $_ } |
            ForEach-Object {
                [PSCustomObject]@{
                    Name        = $_.Name
                    FullName    = $_.FullName
                    Type        = $_.Type
                    Size        = 1
                    DisplaySize = [int64]$_.Size
                }
            }
        )
    }

    if ($items.Count -eq 0) { return }

    $total = ($items | Measure-Object Size -Sum).Sum
    if ($total -le 0) { return }

    $font = New-Object System.Drawing.Font("Arial", 9)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $layout = New-TreemapLayout -Bounds $Bounds -Items $items -TotalSize $total

    if ($layout.Count -eq 0 -and $items.Count -gt 0 -and $Bounds.Width -gt 0 -and $Bounds.Height -gt 0) {
        $fallbackLayout = New-Object System.Collections.ArrayList
        $offsetX = [double]$Bounds.X
        $remainingWidth = [double]$Bounds.Width

        for ($i = 0; $i -lt $items.Count; $i++) {
            if ($i -eq $items.Count - 1) {
                $itemWidth = $remainingWidth
            } else {
                $itemWidth = [double]$Bounds.Width / $items.Count
            }

            [void]$fallbackLayout.Add([pscustomobject]@{
                Item = $items[$i]
                Rect = [System.Drawing.RectangleF]::new(
                    [float]$offsetX,
                    [float]$Bounds.Y,
                    [float][math]::Max(0, $itemWidth),
                    [float]$Bounds.Height
                )
            })

            $offsetX += $itemWidth
            $remainingWidth -= $itemWidth
        }

        $layout = $fallbackLayout
    }

    $script:treemapHitRegions = @(
        $layout | ForEach-Object {
            [PSCustomObject]@{
                Rect = $_.Rect
                Item = $_.Item
            }
        }
    )

    for ($i = 0; $i -lt $layout.Count; $i++) {
        $entry = $layout[$i]
        $item = $entry.Item
        $rect = $entry.Rect
        $drawWidth = [float][math]::Max(1, $rect.Width)
        $drawHeight = [float][math]::Max(1, $rect.Height)
        $color = [System.Drawing.Color]::FromArgb(
            180,
            ((($i * 73) + 50) % 176) + 40,
            ((($i * 137) + 80) % 176) + 40,
            ((($i * 53) + 110) % 176) + 40
        )
        $brush = New-Object System.Drawing.SolidBrush $color
        $Graphics.FillRectangle($brush, [float]$rect.X, [float]$rect.Y, $drawWidth, $drawHeight)
        $Graphics.DrawRectangle([System.Drawing.Pens]::Black, [float]$rect.X, [float]$rect.Y, $drawWidth, $drawHeight)

        if ($drawWidth -gt 60 -and $drawHeight -gt 24) {
            $label = $item.Name
            if ($label.Length -gt 24) {
                $label = $label.Substring(0, 21) + "..."
            }
            $rectF = [System.Drawing.RectangleF]::new([float]$rect.X, [float]$rect.Y, $drawWidth, $drawHeight)
            $Graphics.DrawString($label, $font, [System.Drawing.Brushes]::Black, $rectF, $sf)
        }
        $brush.Dispose()
    }

    $font.Dispose()
    $sf.Dispose()
}

function Update-TreemapDisplay {
    if (-not $panelMap -or $panelMap.IsDisposed) { return }

    $width = $panelMap.ClientSize.Width
    $height = $panelMap.ClientSize.Height
    if ($width -le 0 -or $height -le 0) { return }

    if ($script:panelMapBitmap) {
        $panelMap.BackgroundImage = $null
        $script:panelMapBitmap.Dispose()
        $script:panelMapBitmap = $null
    }

    $bitmap = New-Object System.Drawing.Bitmap $width, $height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    try {
        $graphics.Clear([System.Drawing.Color]::White)
        $script:treemapHitRegions = @()
        $script:lastTreemapTooltipText = ""
        $treemapToolTip.SetToolTip($panelMap, "")
        if ($script:treemapItems -and @($script:treemapItems).Count -gt 0) {
            $bounds = [System.Drawing.Rectangle]::new(0, 0, $width, $height)
            Show-Treemap -Graphics $graphics -Bounds $bounds -Items $script:treemapItems
        }
    } finally {
        $graphics.Dispose()
    }

    $script:panelMapBitmap = $bitmap
    $panelMap.BackgroundImage = $script:panelMapBitmap
    $panelMap.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::None
    $panelMap.Invalidate()
}

$panelMap.Add_MouseMove({
    param($control, $e)

    [void]$control

    if (-not $script:treemapHitRegions -or $script:treemapHitRegions.Count -eq 0) {
        if ($script:lastTreemapTooltipText) {
            $treemapToolTip.SetToolTip($panelMap, "")
            $script:lastTreemapTooltipText = ""
        }
        return
    }

    $hoveredRegion = $null
    foreach ($region in $script:treemapHitRegions) {
        if ($region.Rect.Contains([float]$e.X, [float]$e.Y)) {
            $hoveredRegion = $region
            break
        }
    }

    if (-not $hoveredRegion) {
        if ($script:lastTreemapTooltipText) {
            $treemapToolTip.SetToolTip($panelMap, "")
            $script:lastTreemapTooltipText = ""
        }
        return
    }

    $item = $hoveredRegion.Item
    $displaySize = if ($item.PSObject.Properties['DisplaySize']) { [int64]$item.DisplaySize } else { [int64]$item.Size }
    $itemType = if ($item.Type) { [string]$item.Type } else { 'Element' }
    $tooltipText = "$($item.Name)`n$itemType - $(Format-Size $displaySize)"

    if ($tooltipText -ne $script:lastTreemapTooltipText) {
        $treemapToolTip.SetToolTip($panelMap, $tooltipText)
        $script:lastTreemapTooltipText = $tooltipText
    }
})

$panelMap.Add_MouseLeave({
    $treemapToolTip.SetToolTip($panelMap, "")
    $script:lastTreemapTooltipText = ""
})

function Start-Scan {
    param([bool]$setRoot = $true)

    $path = $txtPath.Text.Trim()
    if (-not $path) {
        [System.Windows.Forms.MessageBox]::Show("Veuillez selectionner un dossier ou un lecteur.", "Avertissement", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    if ($setRoot) {
        $global:RootPath = $path
    }

    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Le chemin d'acces n'existe pas.", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    $btnScan.Enabled = $false
    $btnBrowse.Enabled = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $lblStatus.Text = "Analyse en cours..."
    $progressBar.Value = 0
    $lv.Items.Clear()
    $script:treemapItems = @()
    $totalSize = 0

    try {
        $items = Get-ItemSizes -RootPath $path
        $totalSize = ($items | Measure-Object Size -Sum).Sum
        $items = $items | Sort-Object Size -Descending
        if ($items.Count -gt 50) {
            $items = $items | Select-Object -First 50
        }
        $script:treemapItems = $items
        $folderCount = ($items | Where-Object Type -eq 'Dossier').Count
        $fileCount = ($items | Where-Object Type -eq 'Fichier').Count

        $counter = 0
        foreach ($item in $items) {
            $percent = if ($totalSize -gt 0) { "{0:N2}" -f (($item.Size / $totalSize) * 100) } else { "0.00" }
            $imageKey = if ($item.Type -eq 'Dossier') { 'Folder' } else { 'File' }
            $row = New-Object System.Windows.Forms.ListViewItem($item.Name, $imageKey)
            $row.Tag = $item.FullName
            $row.SubItems.Add($item.Type) | Out-Null
            $row.SubItems.Add((Format-Size $item.Size)) | Out-Null
            $row.SubItems.Add($percent) | Out-Null
            if ($item.Type -eq 'Dossier') {
                $row.BackColor = [System.Drawing.Color]::FromArgb(255, 250, 235)
            } else {
                $row.BackColor = [System.Drawing.Color]::FromArgb(235, 242, 255)
            }
            $lv.Items.Add($row) | Out-Null
            $counter++
            if ($items.Count -gt 0) {
                $progressBar.Value = [math]::Min(100, [int]($counter / $items.Count * 100))
            }
        }
        $progressBar.Value = 100

        if ($items.Count -eq 0) {
            $lblStatus.Text = "Analyse terminee : aucun element trouve dans le dossier."
        } elseif ($totalSize -le 0) {
            $lblStatus.Text = "Analyse terminee - 0 o de taille mesurable. Treemap affichee par nombre d'elements."
        } else {
            $lblStatus.Text = "Analyse terminee - Total : $(Format-Size $totalSize) - $folderCount dossiers, $fileCount fichiers - $(($items.Count)) elements affiches."
        }
        Update-TreemapDisplay
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erreur pendant l'analyse : $_", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } finally {
        $btnScan.Enabled = $true
        $btnBrowse.Enabled = $true
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
}

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Choisissez un dossier ou un lecteur a analyser"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPath.Text = $dialog.SelectedPath
        if ($chkAutoScan.Checked) {
            Start-Scan
        }
    }
})

$btnScan.Add_Click({
    Start-Scan $true
})

$btnRoot.Add_Click({
    $currentPath = $txtPath.Text.Trim()
    if (-not $currentPath) {
        [System.Windows.Forms.MessageBox]::Show("Veuillez d'abord selectionner un dossier ou un lecteur.", "Avertissement", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    try {
        $parentPath = Split-Path -Path $currentPath -Parent
    } catch {
        $parentPath = $null
    }

    if (-not $parentPath) {
        [System.Windows.Forms.MessageBox]::Show("Aucun dossier parent disponible.", "Avertissement", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    $txtPath.Text = $parentPath
    Start-Scan $true
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
            [System.Windows.Forms.MessageBox]::Show("Documentation introuvable. Chemin attendu : $docsHtmlPath", "Avertissement", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Impossible d'ouvrir la documentation : $_", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$btnAbout.Add_Click({
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "A propos de WinDirStat PowerShell"
    $aboutForm.ClientSize = [System.Drawing.Size]::new(460, 310)
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false
    $aboutForm.BackColor = [System.Drawing.Color]::White

    # --- Banniere superieure (degrade bleu moderne) ---
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = [System.Drawing.Size]::new(460, 90)
    $headerPanel.Location = [System.Drawing.Point]::new(0, 0)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 50, 100)

    # Icone (logo disque dur stylise)
    $logoBitmap = New-Object System.Drawing.Bitmap(64, 64)
    $lg = [System.Drawing.Graphics]::FromImage($logoBitmap)
    $lg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $lg.Clear([System.Drawing.Color]::Transparent)
    # Corps du disque
    $diskBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 180, 255))
    $lg.FillEllipse($diskBrush, 4, 4, 56, 56)
    $diskPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 220, 255), 2)
    $lg.DrawEllipse($diskPen, 4, 4, 56, 56)
    # Graphique treemap miniature
    $miniBrush1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 60))
    $miniBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 100, 80))
    $miniBrush3 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 200, 120))
    $miniBrush4 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 120, 220))
    $lg.FillRectangle($miniBrush1, 18, 18, 20, 14)
    $lg.FillRectangle($miniBrush2, 38, 18, 12, 14)
    $lg.FillRectangle($miniBrush3, 18, 32, 16, 18)
    $lg.FillRectangle($miniBrush4, 34, 32, 16, 18)
    $lg.Dispose(); $diskBrush.Dispose(); $diskPen.Dispose()
    $miniBrush1.Dispose(); $miniBrush2.Dispose(); $miniBrush3.Dispose(); $miniBrush4.Dispose()

    $logoBox = New-Object System.Windows.Forms.PictureBox
    $logoBox.Image = $logoBitmap
    $logoBox.Size = [System.Drawing.Size]::new(64, 64)
    $logoBox.Location = [System.Drawing.Point]::new(15, 13)
    $logoBox.BackColor = [System.Drawing.Color]::Transparent
    $logoBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage

    # Titre et version dans le header
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "WinDirStat PowerShell"
    $lblTitle.Location = [System.Drawing.Point]::new(90, 12)
    $lblTitle.Size = [System.Drawing.Size]::new(350, 28)
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent

    $lblVersion = New-Object System.Windows.Forms.Label
    $lblVersion.Text = "Version 1.13  |  Juin 2026"
    $lblVersion.Location = [System.Drawing.Point]::new(90, 42)
    $lblVersion.Size = [System.Drawing.Size]::new(350, 20)
    $lblVersion.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $lblVersion.ForeColor = [System.Drawing.Color]::FromArgb(180, 200, 230)
    $lblVersion.BackColor = [System.Drawing.Color]::Transparent

    $lblSubtitle = New-Object System.Windows.Forms.Label
    $lblSubtitle.Text = "Analyse d'espace disque avec visualisation treemap"
    $lblSubtitle.Location = [System.Drawing.Point]::new(90, 62)
    $lblSubtitle.Size = [System.Drawing.Size]::new(350, 20)
    $lblSubtitle.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
    $lblSubtitle.ForeColor = [System.Drawing.Color]::FromArgb(150, 180, 220)
    $lblSubtitle.BackColor = [System.Drawing.Color]::Transparent

    $headerPanel.Controls.AddRange(@($logoBox, $lblTitle, $lblVersion, $lblSubtitle))

    # --- Contenu principal ---
    $contentY = 105

    # Developpeur
    $lblDev = New-Object System.Windows.Forms.Label
    $lblDev.Text = "Developpe par Gregory HARGOUS"
    $lblDev.Location = [System.Drawing.Point]::new(20, $contentY)
    $lblDev.Size = [System.Drawing.Size]::new(420, 22)
    $lblDev.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $lblDev.ForeColor = [System.Drawing.Color]::FromArgb(50, 50, 50)

    # Separateur
    $separator = New-Object System.Windows.Forms.Label
    $separator.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $separator.Size = [System.Drawing.Size]::new(420, 2)
    $separator.Location = [System.Drawing.Point]::new(20, 132)

    # Liens (LinkLabel pour un look natif)
    $lnkWebsite = New-Object System.Windows.Forms.LinkLabel
    $lnkWebsite.Text = "https://gregland.net"
    $lnkWebsite.Location = [System.Drawing.Point]::new(20, 142)
    $lnkWebsite.Size = [System.Drawing.Size]::new(420, 24)
    $lnkWebsite.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lnkWebsite.LinkColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $lnkWebsite.ActiveLinkColor = [System.Drawing.Color]::FromArgb(0, 80, 180)
    $lnkWebsite.LinkBehavior = [System.Windows.Forms.LinkBehavior]::HoverUnderline
    $lnkWebsite.Add_Click({ Start-Process "https://gregland.net" })

    $lnkGitHub = New-Object System.Windows.Forms.LinkLabel
    $lnkGitHub.Text = "github.com/gregland76/Windirstat"
    $lnkGitHub.Location = [System.Drawing.Point]::new(20, 168)
    $lnkGitHub.Size = [System.Drawing.Size]::new(420, 24)
    $lnkGitHub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lnkGitHub.LinkColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $lnkGitHub.ActiveLinkColor = [System.Drawing.Color]::FromArgb(0, 80, 180)
    $lnkGitHub.LinkBehavior = [System.Windows.Forms.LinkBehavior]::HoverUnderline
    $lnkGitHub.Add_Click({ Start-Process "https://github.com/gregland76/Windirstat" })

    $lnkEmail = New-Object System.Windows.Forms.LinkLabel
    $lnkEmail.Text = "gregory.hargous@gmail.com"
    $lnkEmail.Location = [System.Drawing.Point]::new(20, 194)
    $lnkEmail.Size = [System.Drawing.Size]::new(420, 24)
    $lnkEmail.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lnkEmail.LinkColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $lnkEmail.ActiveLinkColor = [System.Drawing.Color]::FromArgb(0, 80, 180)
    $lnkEmail.LinkBehavior = [System.Windows.Forms.LinkBehavior]::HoverUnderline
    $lnkEmail.Add_Click({ Start-Process "mailto:gregory.hargous@gmail.com" })

    # Separateur bas
    $separator2 = New-Object System.Windows.Forms.Label
    $separator2.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $separator2.Size = [System.Drawing.Size]::new(420, 2)
    $separator2.Location = [System.Drawing.Point]::new(20, 228)

    # Mentions legales / licence
    $lblLicense = New-Object System.Windows.Forms.Label
    $lblLicense.Text = "(c) 2026 Gregory HARGOUS - Distribue sous licence MIT  |  Ecrit en PowerShell"
    $lblLicense.Location = [System.Drawing.Point]::new(20, 236)
    $lblLicense.Size = [System.Drawing.Size]::new(420, 20)
    $lblLicense.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblLicense.ForeColor = [System.Drawing.Color]::Gray
    $lblLicense.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    # Bouton Fermer modernise
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Fermer"
    $btnClose.Location = [System.Drawing.Point]::new(180, 265)
    $btnClose.Size = [System.Drawing.Size]::new(100, 35)
    $btnClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnClose.BackColor = [System.Drawing.Color]::FromArgb(30, 50, 100)
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnClose.TabStop = $false
    $btnClose.Add_Click({ $aboutForm.Close() })

    $aboutForm.Controls.AddRange(@($headerPanel, $lblDev, $separator, $lnkWebsite, $lnkGitHub, $lnkEmail, $separator2, $lblLicense, $btnClose))
    $aboutForm.AcceptButton = $btnClose
    $aboutForm.CancelButton = $btnClose
    [void]$aboutForm.ShowDialog()
})

[void]$form.ShowDialog()