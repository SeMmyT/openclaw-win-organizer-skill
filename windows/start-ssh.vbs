' OpenClaw Windows Organizer - Startup Script
' Place in: shell:startup (Windows Startup folder)
' Starts WSL SSH and configures port forwarding silently

Set WshShell = CreateObject("WScript.Shell")

' Start WSL SSH service
WshShell.Run "wsl -u root service ssh start", 0, True

' Update port forwarding (WSL IP can change on reboot)
WshShell.Run "powershell -ExecutionPolicy Bypass -Command ""$wslIP = (wsl hostname -I).Trim().Split(' ')[0]; netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0 2>$null; netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=2222 connectaddress=$wslIP""", 0, False
