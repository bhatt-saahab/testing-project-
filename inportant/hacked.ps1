Add-Type -AssemblyName PresentationFramework

# Create Fullscreen WPF Window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        WindowStyle="None" ResizeMode="NoResize"
        WindowState="Maximized" Background="Black" Topmost="True">
    <Grid>
        <!-- Main Big Text -->
        <TextBlock Text="JAY MAHAKAL"
                   Foreground="Red"
                   FontSize="130"
                   FontWeight="Bold"
                   HorizontalAlignment="Center"
                   VerticalAlignment="Center"/>
        <!-- Sub Headline at Bottom -->
        <TextBlock Text="This Hacked"
                   Foreground="White"
                   FontSize="40"
                   FontWeight="Bold"
                   HorizontalAlignment="Center"
                   VerticalAlignment="Bottom"
                   Margin="0,0,0,40"/>
    </Grid>
</Window>
"@

# Load XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Block manual close
$script:allowClose = $false
$window.Add_Closing({ if (-not $script:allowClose) { $_.Cancel = $true } })

# Auto-close timer (30s)
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(10)         
$timer.Add_Tick({
    $timer.Stop()
    $script:allowClose = $true
    $window.Close()
})

# Start timer when window shows
$window.Add_SourceInitialized({ $timer.Start() })

# Show window
$window.ShowDialog() | Out-Null