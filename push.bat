@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
title Git 一键推送（SSH方式 - 仓库名自动取文件夹名）

echo ==============================================
echo    Git 一键推送到 GitHub (Loulizse/文件夹名)
echo ==============================================
echo.

:: 1. 检查 Git 是否可用
where git >nul 2>nul
if errorlevel 1 (
    echo [错误] 未找到 Git，请先安装 Git 并确保已添加到 PATH。
    pause
    exit /b 1
)

:: 2. 获取当前文件夹名作为仓库名
for %%I in (.) do set "REPO_NAME=%%~nxI"
echo [信息] 当前文件夹名: %REPO_NAME%
echo [信息] 将推送到: git@github.com:Loulizse/%REPO_NAME%.git
echo.

:: 3. 询问是否继续
set /p confirm="确认使用以上仓库名？(Y/n): "
if /i "!confirm!"=="n" (
    echo 已取消操作。
    pause
    exit /b 0
)

:: 4. 处理已存在的 .git 仓库
if exist ".git" (
    echo [警告] 当前目录已是 Git 仓库。
    set /p choice="是否重新初始化（会删除原 .git 目录）？(y/N): "
    if /i "!choice!"=="y" (
        echo 正在删除 .git ...
        rmdir /s /q .git
        if errorlevel 1 (
            echo 删除失败，请手动删除或使用管理员权限运行。
            pause
            exit /b 1
        )
        echo 已删除原有仓库。
    ) else (
        echo 将使用现有仓库，并更新远程地址。
    )
    echo.
)

:: 5. 初始化仓库（如果 .git 不存在）
if not exist ".git" (
    echo [1/5] 初始化本地仓库...
    git init
    if errorlevel 1 (
        echo 初始化失败。
        pause
        exit /b 1
    )
) else (
    echo [1/5] 仓库已存在，跳过初始化。
)

:: 6. 添加所有文件
echo [2/5] 添加当前目录下所有文件...
git add .
if errorlevel 1 (
    echo 添加文件失败。
    pause
    exit /b 1
)

:: 7. 检查并设置用户信息（如果未设置）
echo [3/5] 检查用户信息...
git config --global user.name >nul 2>nul
if errorlevel 1 (
    echo 未设置 Git 用户信息，请输入：
    set /p user_name="用户名（GitHub 用户名）: "
    set /p user_email="邮箱: "
    git config --global user.name "!user_name!"
    git config --global user.email "!user_email!"
    echo 已设置全局用户信息。
) else (
    echo 已存在用户信息，跳过。
)

:: 8. 提交
echo [4/5] 提交文件...
git commit -m "Initial commit"
if errorlevel 1 (
    echo 提交失败，可能没有文件变更。
    pause
    exit /b 1
)

:: 9. 获取当前分支名
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%i"
if "%BRANCH%"=="" set "BRANCH=master"
echo 当前分支: %BRANCH%

:: 10. 处理远程仓库 origin
set "REMOTE_URL=git@github.com:Loulizse/%REPO_NAME%.git"

echo [5/5] 配置远程仓库并推送...
git remote get-url origin >nul 2>nul
if not errorlevel 1 (
    echo 检测到已存在的远程 origin，正在移除...
    git remote remove origin
)

echo 添加远程仓库 origin -> %REMOTE_URL%
git remote add origin "%REMOTE_URL%"
if errorlevel 1 (
    echo 添加远程仓库失败。
    pause
    exit /b 1
)

:: 11. 测试 SSH 连接（可选）
echo 正在测试 SSH 连接（确保已配置 SSH 密钥）...
ssh -T git@github.com -o ConnectTimeout=5 >nul 2>nul
if errorlevel 1 (
    echo [警告] SSH 连接测试失败，可能未配置 SSH 密钥。
    echo 请先配置 SSH 密钥：https://docs.github.com/zh/authentication/connecting-to-github-with-ssh
    echo 按任意键继续尝试推送...
    pause >nul
) else (
    echo SSH 连接正常。
)

:: 12. 推送
echo 正在推送至 %BRANCH% 分支...
git push -u origin "%BRANCH%"
if errorlevel 1 (
    echo.
    echo [错误] 推送失败。可能原因：
    echo   - 远程仓库 %REPO_NAME% 不存在于 GitHub 账户 Loulizse 下
    echo   - SSH 密钥未正确配置
    echo   - 网络问题
    echo.
    echo 请先在 GitHub 上创建空仓库（不要勾选任何初始化文件）：
    echo https://github.com/Loulizse/%REPO_NAME%
    echo.
    echo 或者手动执行以下命令查看详细错误：
    echo   git push -u origin %BRANCH%
) else (
    echo.
    echo ==============================================
    echo    恭喜！推送成功！
    echo    仓库地址: https://github.com/Loulizse/%REPO_NAME%
    echo ==============================================
)

echo.
echo 按任意键退出...
pause >nul
exit /b 0