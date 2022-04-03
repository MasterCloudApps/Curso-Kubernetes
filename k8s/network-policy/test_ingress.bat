@ECHO OFF
@REM GET HOST FROM ARGUMENT
set HOST=%1

@REM GET INGRESS PORT FROM KUBECTL COMMAND OUTPUT
for /f %%i in ('kubectl get service ingress-nginx-controller -n ingress-nginx --output="jsonpath={.spec.ports[0].nodePort}"') do set PORT_INGRESS=%%i

echo IP: %HOST%
echo INGRESS PORT: %PORT_INGRESS%

@REM TEST ServiceA External Ingress
curl.exe --max-time 1 -Isf  "http://%HOST%:%PORT_INGRESS%/servicea/internalvalue" | findstr /IR "200 301" >nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceA External Ingress [OK]"
) ELSE (
    ECHO "ServiceA External Ingress [FAIL]"
)

@REM TEST ServiceB External Ingress
curl.exe --max-time 1 -Isf "http://%HOST%:%PORT_INGRESS%/servicea/externalvalue" | findstr /IR "200 301" >nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceA External Egress [OK]"
) ELSE (
    ECHO "ServiceA External Egress [FAIL]"
)

@REM TEST ServiceA External Egress
curl.exe --max-time 1 -Isf "http://%HOST%:%PORT_INGRESS%/servicea/servicebvalue-internal" | findstr /IR "200 301" >nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceA to ServiceB [OK]"
) ELSE (
    ECHO "ServiceA to ServiceB [FAIL]"
)

@REM TEST ServiceA to ServiceB
curl.exe --max-time 1 -Isf "http://%HOST%:%PORT_INGRESS%/servicea/servicebvalue-external" | findstr /IR "200 301" >nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceB External Egress (through ServiceA) [OK]"
) ELSE (
    ECHO "ServiceB External Egress (through ServiceA) [FAIL]"
)

