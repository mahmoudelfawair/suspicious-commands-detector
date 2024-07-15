# fill out these variables
$From = 'sender@example.com'  
$To = 'recipient@example.com'   

$Subject = "Suspicious Command Execution"

$SMTPServer = 'smtp.example.com'
$SMTPPort = 587
$SMTPUsername = 'smtp_username' 
$SMTPPassword = 'smtp_password'    


function Send-Email {
    param(
        [string]$From,
        [string]$To,
        [string]$Subject,
        [string]$Body,
        [string]$SMTPServer,
        [int]$SMTPPort,
        [string]$SMTPUsername,
        [string]$SMTPPassword
    )

    $SMTPMessage = @{
        To = $To
        From = $From
        Subject = $Subject
        Body = $Body
        BodyAsHtml = $true
        SmtpServer = $SMTPServer
        Port = $SMTPPort
        UseSSL = $true
        Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SMTPUsername, (ConvertTo-SecureString $SMTPPassword -AsPlainText -Force)
    }

    Send-MailMessage @SMTPMessage
}


# add commands you want to monitor
$suspicious = @('whoami', 'ipconfig')

while ($true) {
    $currentTime = Get-Date
    $fiveMinutesAgo = $currentTime.AddMinutes(-5)

    $filterHashTable = @{
        LogName = 'Security'
        ID = 4688
        StartTime = $fiveMinutesAgo
    }

    $events = Get-WinEvent -FilterHashtable $filterHashTable

    $htmlContent = ""

    foreach ($event in $events){
        $property = $event.Properties
        $cont = $false
        $emailBody = ""
        
        foreach ($sus in $suspicious){
            if (($property[5].Value -match $sus)){
                $cont = $true
            }
        }

        if ($cont){
            $emailBody += "<p><strong>SID:</strong> $($property[0].Value)</p>"
            $emailBody += "<p><strong>Account Name:</strong> $($property[1].Value)</p>"
            $emailBody += "<p><strong>Account Domain:</strong> $($property[2].Value)</p>"
            $emailBody += "<p><strong>Process ID:</strong> $($property[4].Value)</p>"
            $emailBody += "<p><strong>Process Name:</strong> $($property[5].Value)</p>"
            $emailBody += "<p><strong>Parent Process ID:</strong> $($property[7].Value)</p>"
            $emailBody += "<p><strong>Parent Process Name:</strong> $($property[13].Value)</p>"
            $emailBody += "<p><strong>Created Time:</strong> $($event.timeCreated)</p>"
            

            $htmlContent += "<div style='margin-bottom: 20px; padding: 10px; border: 1px solid #ccc;'>$emailBody</div>"
        }
    }

    if ($htmlContent -ne "") {
        $htmlOutput = @"
<!DOCTYPE html>
<html>
<head>
    <title>Suspicious Command Execution</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            padding: 20px;
        }
        .email-container {
            margin-bottom: 20px;
            padding: 10px;
            border: 1px solid #ccc;
            background-color: #f9f9f9;
        }
        p {
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <h2>Event Details</h2>
    $htmlContent
</body>
</html>
"@
        
        Send-Email -From $From -To $To -Subject $Subject -Body $htmlOutput -SMTPServer $SMTPServer -SMTPPort $SMTPPort -SMTPUsername $SMTPUsername -SMTPPassword $SMTPPassword
    }

    # Sleep for 5 minutes before checking again
    Start-Sleep -Seconds (5 * 60)
}
