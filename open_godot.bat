@echo off
set GODOT_EXE="C:\Users\Eyu\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64.exe"
set PROJECT_DIR="D:\DMWWork\GD_WG26"

REM 检查 Godot 是否存在
if not exist %GODOT_EXE% (
    echo [错误] 找不到 Godot 可执行文件: %GODOT_EXE%
    echo 请确认 Godot 路径是否正确。
    pause
    exit /b 1
)

echo 正在用 Godot 打开项目: %PROJECT_DIR%
%GODOT_EXE% --path %PROJECT_DIR%
