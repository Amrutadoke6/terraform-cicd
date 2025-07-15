# bootstrap.ps1

# Allow script execution (just in case)
Set-ExecutionPolicy Unrestricted -Force

# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Add custom index.html
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value "<h1>Hello from Amruta's Terraform IIS</h1>"

# Start SSM Agent (safe for AMI with preinstalled agent)
Try {
    Start-Service AmazonSSMAgent -ErrorAction Stop
    Write-Output "SSM Agent started."
} Catch {
    Write-Output "SSM Agent not found. Downloading and installing..."

    $ssmUrl = "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/Windows/SSMAgentSetup.exe"
    $dest = "$env:TEMP\SSMAgentSetup.exe"
    Invoke-WebRequest -Uri $ssmUrl -OutFile $dest -UseBasicParsing
    Start-Process -FilePath $dest -ArgumentList "/quiet" -Wait

    Start-Service AmazonSSMAgent
    Write-Output "SSM Agent installed and started."
}

# Set SSM Agent to start automatically
Set-Service -Name AmazonSSMAgent -StartupType Automatic

