@ECHO OFF
@REM GET HOST FROM ARGUMENT
set HOST=%1

@REM GET SERVICES PORTS FROM KUBECTL COMMAND OUTPUT
for /f %%i in ('kubectl get service servicea-service --output="jsonpath={.spec.ports[0].nodePort}"') do set PORT_SERV_A=%%i
for /f %%i in ('kubectl get service serviceb-service --output="jsonpath={.spec.ports[0].nodePort}"') do set PORT_SERV_B=%%i

echo IP: %HOST%
echo SERVICE A PORT: %PORT_SERV_A%
echo SERVICE B PORT: %PORT_SERV_B%

@REM TEST ServiceA External Ingress
curl.exe --max-time 1 -Isf  "http://%HOST%:%PORT_SERV_A%/internalvalue" | findstr /IR "200 301">nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceA External Ingress [OK]"
) ELSE (
    ECHO "ServiceA External Ingress [FAIL]"
)

@REM TEST ServiceB External Ingress
curl.exe --max-time 1 -Isf "http://%HOST%:%PORT_SERV_B%/internalvalue" | findstr /IR "200 301">nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceB External Ingress [OK]"
) ELSE (
    ECHO "ServiceB External Ingress [FAIL]"
)

@REM TEST ServiceA External Egress
curl.exe --max-time 1 -Isf "http://%HOST%:%PORT_SERV_A%/externalvalue" | findstr /IR "200 301">nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceA External Egress [OK]"
) ELSE (
    ECHO "ServiceA External Egress [FAIL]"
)

@REM TEST ServiceA to ServiceB
curl.exe --max-time 1 -Isf "http://%HOST%:%PORT_SERV_A%/servicebvalue-internal" | findstr /IR "200 301">nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceA to ServiceB [OK]"
) ELSE (
    ECHO "ServiceA to ServiceB [FAIL]"
)

@REM TEST ServiceB External Egress (direct)
curl.exe --max-time 1 -Isf "http://%HOST%:%PORT_SERV_B%/externalvalue" | findstr /IR "200 301">nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceB External Egress (direct) [OK]"
) ELSE (
    ECHO "ServiceB External Egress (direct) [FAIL]"
)

@REM TEST ServiceB External Egress (through ServiceA)
curl.exe --max-time 1 -Isf "http://%HOST%:%PORT_SERV_A%/servicebvalue-external" | findstr /IR "200 301">nul
IF %ERRORLEVEL% EQU 0 (
    ECHO "ServiceB External Egress (through ServiceA) [OK]"
) ELSE (
    ECHO "ServiceB External Egress (through ServiceA) [FAIL]"
)
