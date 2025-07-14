<powershell>
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Set-Content -Path \"C:\\inetpub\\wwwroot\\index.html\" -Value \"<h1>Hello from Amruta's Terraform IIS</h1>\"
</powershell>

