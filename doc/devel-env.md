# VSCode配置（MacOS）

## 安装XCode
确保`lldb`正确安装。

## 安装lazarus
```bash
brew install --cask lazarus
```

## 编译安装jcf代码格式化工具
https://github.com/git-bee/jcf-cli
github上说的不全对，按以下方式调整步骤。
1. You must have both Free Pascal compiler and VS Code already installed on your system.
2. Clone or download this jcf-cli GitHub repo into your own folder.
```bash
cd ~/Documents/DelphiProject/
git clone https://github.com/git-bee/jcf-cli.git
```
3. Start your VS Code and open diretory of `~/Documents/DelphiProject/jfc-cli/`
4. Build it via VS Code's Tasks → Run Task... → JCF: Build Release menu.
5. Wait while FPC is building the JCF project.
6. Open test.pas file from jcf-cli folder.
7. Test JCF program using Tasks → Run Task... → JCF: Test CLI Program menu and you should see the result in the test.pas file.

## VSCode中安装好插件
- CodeLLDB
- C/C++

## VSCode中安装OminiPascal插件
修改配置：
```json
{
    "omnipascal.defaultDevelopmentEnvironment": "FreePascal",
    "omnipascal.freePascalSourcePath": "/usr/local/share/fpcsrc",
    "omnipascal.searchPath": "/Applications/Lazarus/lcl/*",
    "omnipascal.lazbuildPath": "/Applications/Lazarus/lazbuild",
}
```

## 项目环境配置
1. 使用Lazarus新建空白项目并且保存，如`ASTBuilder/ASTBuilder.lpi`。
2. 用VSCode打开项目所在目录，如`$ASTBuilder/`。
3. Cmd-Shift-P：选择OmniPascal Load Project，然后选择加载对应的lpi项目文件路径。 
4. 修改或创建`.vscode/CompileOmniPascalServerProject.sh`
```bash
#!/bin/bash

LAZBUILD="/Applications/Lazarus/lazbuild"
PROJECT="/Users/exsystem/DelphiProject/ASTBuilder/ASTBuilder.lpi"

# Modify .lpr file in order to avoid nothing-to-do-bug (http://lists.lazarus.freepascal.org/pipermail/lazarus/2016-February/097554.html)
# echo. >> "/Users/exsystem/DelphiProject/ASTBuilder/ASTBuilder.lpr"

if $LAZBUILD $PROJECT; then

  if [ $1 = "test" ]; then
    "/Users/exsystem/DelphiProject/ASTBuilder/ASTBuilder" 
  fi
fi
```
5. 修改或创建`.vscode/tasks.json`
```json
{
    "version": "2.0.0",
    "runner": "terminal",
    "tasks": [
        {
            "command": "/Users/exsystem/DelphiProject/jcf/JCF",
            "args": [
                "-config=/Users/exsystem/.lazarus/jcfsettings.cfg",
                "-inplace",
                "-y",
                "-F",
                "${file}"
            ],
            "problemMatcher": [],
            "label": "format code"
        },
        {
            "command": ".vscode/CompileOmniPascalServerProject.sh",
            "args": [
                "build"
            ],
            "type": "shell",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "label": "build",
            "problemMatcher": {
                "owner": "external",
                "fileLocation": ["absolute"],
                "pattern": {
                   "regexp": "(\\/?(?:[^\\/:*?\\\"<>|\\r\\n]+\\/)*[^\\/\\s\\(:*?\\\"<>|\\r\\n]*)\\((\\d+),(\\d+)\\)\\s.*(Fatal|Error|Warning|Hint|Note):\\s\\((\\d+)\\)\\s(.*)$",
                   "file": 1,
                   "line": 2,
                   "column": 3,
                   "severity": 4,
                   "code": 5,
                   "message": 6
                },
                "severity": "info"
            },
            "group": {
                "kind": "build",
                "isDefault": true
            }
        },
        {
            "command": ".vscode/CompileOmniPascalServerProject.sh",
            "args": [
                "test"
            ],
            "type": "shell",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "label": "test",
            "problemMatcher": {
                "owner": "external",
                 "fileLocation": ["absolute"],
                 "pattern": {
                   "regexp": "(\\/?(?:[^\\/:*?\\\"<>|\\r\\n]+\\/)*[^\\/\\s\\(:*?\\\"<>|\\r\\n]*)\\((\\d+),(\\d+)\\)\\s.*(Fatal|Error|Warning|Hint|Note):\\s\\((\\d+)\\)\\s(.*)$",
                   "file": 1,
                   "line": 2,
                   "column": 3,
                   "severity": 4,
                   "code": 5,
                   "message": 6
                },
                "severity": "info"
            },
            "group": {
                "kind": "test",
                "isDefault": true
            }
        }
    ]
}
```
6. 修改或创建`.vscode/launch.json`
```json
{
  // 使用 IntelliSense 以得知可用的屬性。
  // 暫留以檢視現有屬性的描述。
  // 如需詳細資訊，請瀏覽: https://go.microsoft.com/fwlink/?linkid=830387
  "version": "0.2.0",
  "configurations": [
    {
      "type": "lldb",
      "request": "launch",
      "name": "Debug",
      "program": "${workspaceFolder}/ASTBuilder",
      "args": [],
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

## 注意事项
- VSCode中暂时不安装Pascal插件，不知道是否好用。
- VSCode中不要安装Pascal Formatter插件，因为代码里面有bug，无法正确调用JCF。
- 不要设置OmniPascal中的自动创建tasks.json的选项，是有bug的，只能按照上述手工编辑tasks.json文件。

## 使用
- Cmd-Shift-P，Run Task：
  - `build`：编译项目
  - `test`：编译并运行项目
  - `format code`：对当前文件进行代码格式化。
- 正常Debug
- 若发生找不到项目中unit的问题：重启VSCode可解决。
- 代码格式化选项可以从Lazarus中进行调整，得到新的xml配置文件后在`tasks.json`中引用即可。