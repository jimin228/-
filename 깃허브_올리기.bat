@echo off
chcp 65001 > nul
echo ==============================================
echo   GitHub 원격 저장소로 외근대장 업로드 (Push)
echo ==============================================
echo.
echo 원격 저장소: https://github.com/jimin228/-.git
echo 브랜치: main
echo.
echo 깃허브로 업로드를 시작합니다...
echo (처음 실행 시 브라우저 로그인 창이 뜨면 로그인을 진행해주세요)
echo.

"C:\Program Files\Git\cmd\git.exe" push -u origin main

echo.
if %ERRORLEVEL% equ 0 (
    echo ==============================================
    echo   성공적으로 깃허브에 업로드되었습니다!
    echo ==============================================
) else (
    echo ==============================================
    echo   업로드 중 오류가 발생했습니다.
    echo ==============================================
)
echo.
pause
