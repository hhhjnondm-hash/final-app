@echo off
echo Generating Android keystore for release signing...
echo.

REM Check if keytool is available
where keytool >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: keytool not found. Please ensure Java JDK is installed and in PATH.
    exit /b 1
)

REM Generate keystore
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release ^
    -dname "CN=Islamic App, OU=Development, O=Islamyat, L=Cairo, ST=Egypt, C=EG" ^
    -storepass KA323159#d ^
    -keypass KA323159#d

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS: Keystore generated successfully!
    echo.
    echo IMPORTANT: 
    echo 1. Keystore password already set to: KA323159#d
    echo 2. Update android/key.properties with your actual passwords
    echo 3. Add keystore.jks to .gitignore
    echo 4. Keep this file secure and never commit it to git
) else (
    echo.
    echo ERROR: Failed to generate keystore
    exit /b 1
)
