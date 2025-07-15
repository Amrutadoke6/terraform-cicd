<powershell>
# Allow script execution
Set-ExecutionPolicy Unrestricted -Force

# Install IIS Web Server
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Create a default web page
New-Item -Path "C:\inetpub\wwwroot\index.html" -ItemType File -Force
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value "<h1>Hello from Amruta's Terraform IIS</h1>"

# Start SSM Agent if already present
Try {
    Start-Service AmazonSSMAgent -ErrorAction Stop
    Write-Output "SSM Agent started."
} Catch {
    Write-Output "SSM Agent not found. Installing..."

    $ssmUrl = "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/Windows/SSMAgentSetup.exe"
    $dest = "$env:TEMP\SSMAgentSetup.exe"
    Invoke-WebRequest -Uri $ssmUrl -OutFile $dest -UseBasicParsing
    Start-Process -FilePath $dest -ArgumentList "/quiet" -Wait

    Start-Service AmazonSSMAgent
    Write-Output "SSM Agent installed and started."
}

# Set SSM agent to auto start
Set-Service -Name AmazonSSMAgent -StartupType Automatic
</powershell>

