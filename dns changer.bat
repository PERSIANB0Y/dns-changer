@echo off
setlocal enabledelayedexpansion

rem Fetch the network adapters
for /f "tokens=*" %%A in ('powershell -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -ExpandProperty Name"') do (
    set "adapterList=!adapterList!%%A,"
)

rem Remove the trailing comma
set "adapterList=%adapterList:~0,-1%"

rem Auto-select the first adapter if only one is available
for /f "tokens=*" %%A in ('powershell -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -ExpandProperty Name | Measure-Object | Select-Object -ExpandProperty Count"') do set adapterCount=%%A

if "%adapterCount%"=="1" (
    for %%A in (%adapterList%) do set selectedAdapter=%%A
) else (
    call :SelectAdapter
)

goto :MainMenu

:SelectAdapter
cls
echo ===================================================
echo      DNS Configuration Utility by saadi
echo ===================================================
echo.
echo Available Network Adapters:
set count=0
for %%A in (%adapterList%) do (
    set /a count+=1
    echo   !count! - %%A
)
echo.
set /p selectedAdapterNumber=Enter the number of the adapter: 

rem Map selected number to adapter name
set count=0
for %%A in (%adapterList%) do (
    set /a count+=1
    if "!count!"=="!selectedAdapterNumber!" set selectedAdapter=%%A
)

if not defined selectedAdapter (
    echo Invalid selection. Please try again.
    pause
    goto :SelectAdapter
)
goto :MainMenu

:MainMenu
cls
echo ===================================================
echo      DNS Configuration Utility by saadi
echo ===================================================
echo.
echo Current Network Adapter: %selectedAdapter%
echo Current DNS Settings:
powershell -Command "Get-DnsClientServerAddress -InterfaceAlias '%selectedAdapter%' | Select-Object -ExpandProperty ServerAddresses"
if errorlevel 1 (
    rem Fallback method to retrieve DNS servers using netsh
    echo Using fallback method to get DNS settings...
    netsh interface ip show dns | findstr /i "%selectedAdapter%"
)

rem Ping each DNS server and store the average response time
for /f "tokens=2 delims==," %%G in ('ping -n 1 178.22.122.100 ^| findstr /i "Average"') do set shekanPing=%%G
for /f "tokens=2 delims==," %%G in ('ping -n 1 10.202.10.202 ^| findstr /i "Average"') do set dns403Ping=%%G
for /f "tokens=2 delims==," %%G in ('ping -n 1 78.157.42.100 ^| findstr /i "Average"') do set electroPing=%%G
for /f "tokens=2 delims==," %%G in ('ping -n 1 10.202.10.10 ^| findstr /i "Average"') do set radarPing=%%G
for /f "tokens=2 delims==," %%G in ('ping -n 1 8.8.8.8 ^| findstr /i "Average"') do set googlePing=%%G
for /f "tokens=2 delims==," %%G in ('ping -n 1 1.1.1.1 ^| findstr /i "Average"') do set cloudflarePing=%%G
for /f "tokens=2 delims==," %%G in ('ping -n 1 208.67.222.222 ^| findstr /i "Average"') do set openDnsPing=%%G

echo.
echo Options:
echo.
echo  1 - Shekan DNS (178.22.122.100, 185.51.200.2)     - Ping: %shekanPing%
echo  2 - 403 DNS (10.202.10.202, 10.202.10.102)        - Ping: %dns403Ping%
echo  3 - Electro 1 DNS (78.157.42.100, 78.157.42.101)  - Ping: %electroPing%
echo  4 - Radar Game DNS (10.202.10.10, 10.202.10.11)   - Ping: %radarPing%
echo  5 - Google DNS (8.8.8.8, 8.8.4.4)                 - Ping: %googlePing%
echo  6 - Cloudflare DNS (1.1.1.1, 1.0.0.1)             - Ping: %cloudflarePing%
echo  7 - OpenDNS (208.67.222.222, 208.67.220.220)      - Ping: %openDnsPing%
echo.
echo  8 - Custom DNS (Enter your own DNS addresses)
echo  9 - Clear DNS and Restore Default Settings
echo  0 - Exit
echo  00 - Select Network Adapter
echo.
set /p choice=Enter your choice: 

if "%choice%"=="1" set DNS1=178.22.122.100 & set DNS2=185.51.200.2 & goto :SetDNS
if "%choice%"=="2" set DNS1=10.202.10.202 & set DNS2=10.202.10.102 & goto :SetDNS
if "%choice%"=="3" set DNS1=78.157.42.100 & set DNS2=78.157.42.101 & goto :SetDNS
if "%choice%"=="4" set DNS1=10.202.10.10 & set DNS2=10.202.10.11 & goto :SetDNS
if "%choice%"=="5" set DNS1=8.8.8.8 & set DNS2=8.8.4.4 & goto :SetDNS
if "%choice%"=="6" set DNS1=1.1.1.1 & set DNS2=1.0.0.1 & goto :SetDNS
if "%choice%"=="7" set DNS1=208.67.222.222 & set DNS2=208.67.220.220 & goto :SetDNS
if "%choice%"=="8" goto :CustomDNS
if "%choice%"=="9" goto :ClearDNS
if "%choice%"=="00" goto :SelectAdapter
if "%choice%"=="0" goto :Exit

echo Invalid choice. Please try again.
pause
goto :MainMenu

:SetDNS
powershell -Command "Set-DnsClientServerAddress -InterfaceAlias '%selectedAdapter%' -ServerAddresses @('%DNS1%', '%DNS2%')"
goto :MainMenu

:CustomDNS
set /p DNS1=Enter the Primary DNS: 
set /p DNS2=Enter the Secondary DNS: 
goto :SetDNS

:ClearDNS
powershell -Command "Set-DnsClientServerAddress -InterfaceAlias '%selectedAdapter%' -ResetServerAddresses"
goto :MainMenu

:Exit
endlocal
exit
