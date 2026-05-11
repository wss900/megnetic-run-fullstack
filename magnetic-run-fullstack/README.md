# Magnetic Run / RunCenter（磁性测量数据处理中心）

全栈应用：**Vue 3 + Vite** 前端、`magrun` 插件式步骤库、**FastAPI** 后端。支持本地一键跑通，以及部署到 **腾讯云开发 CloudBase**（HTTP 云函数 + 静态网站托管）。

---

## 主要功能

- **步骤中心（RunCenter）**：在网页上选择「数据处理步骤」、填写参数、上传文件（如 PPMS/谐波相关 `txt`、`xlsx`），一键运行并得到表格下载、图片、说明文本。
- **可扩展步骤库**：业务逻辑在 `magrun/steps/` 下以 Python 模块注册，后端自动发现；前端通过 `GET /api/steps` 拉元数据、`POST /api/runs` 执行。
- **当前内置步骤示例**（随仓库迭代，以 `magrun/steps/` 为准）：
  - 谐波：跳点清洗、上升/下降段提取、斜率曲率分析等  
  - PPMS：角度扫描拟合、B 列线性拟合等  
  - 辅助：Ni4Mo 工艺时间表等  
- **本地开发**：后端 `start-backend.cmd`（Vite 代理 `/api`）；前端 `frontend` 目录 `npm run dev`。
- **线上形态**：静态站托管前端子路径 **`/magnetic-run/`**；API 走 **HTTP 云函数**，网关前缀 **`/my-api`**（与 `HTTP_ROUTE_PREFIX` 一致）。

---

## 仓库结构（给人类与 AI 定位代码）

| 路径 | 作用 |
|------|------|
| `frontend/` | Vue 3 单页应用；生产构建读 `VITE_BASE_PATH`、`VITE_API_BASE`。 |
| `backend/` | FastAPI：`/api/steps`、`/api/runs`、静态首页（可选带 `frontend/dist`）。 |
| `magrun/` | 步骤协议与实现：`models.py`、`runner.py`、`steps/*.py`。 |
| `deploy/cloudbase/` | 云端打包与部署脚本（见下文）。 |
| `scf-deploy.zip` | **生成物**，勿提交（已在 `.gitignore`）。 |
| `deploy/cloudbase/scf_site_packages/` | **生成物**，Linux 依赖 wheel 目录，勿提交。 |

---

## 本地运行

### 后端

1. 安装 **Python 3.10+**。  
2. 双击或在仓库根目录执行 **`start-backend.cmd`**：会在 `backend/.venv` 安装依赖并启动 Uvicorn（默认 `http://127.0.0.1:8000`）。

### 前端

```bash
cd frontend
npm install
npm run dev
```

默认通过 Vite 代理把 `/api` 转到本机后端。若需显式指定 API 根，可设环境变量 **`VITE_API_BASE`**（例如 `http://127.0.0.1:8000`）。

---

## 云端部署（腾讯云开发 CloudBase）

> **与推 GitHub / 本地推送云端的关系**  
> 本节命令示例中的 **环境 ID、域名一律用占位符**（`<YOUR_ENV_ID>` 等），方便公开仓库、避免把个人环境写进文档。  
> **`deploy/cloudbase/` 下的 `*.ps1` 部署脚本未随 README 替换**；你本机继续用脚本里已配置的真实 `EnvId`、API 域名即可，**不影响**你平时的 `pack-scf-zip`、`tcb fn code update`、`deploy-hosting` 等云端推送流程。

以下假设（请把占位符换成你在控制台里的真实值）：

- 环境 ID：**`<YOUR_ENV_ID>`**（CloudBase 环境 `EnvId`）。  
- HTTP 云函数名 **`apihd`**（若不同，命令里一并替换）。  
- 网关路由前缀 **`/my-api`**（云函数环境变量 **`HTTP_ROUTE_PREFIX=/my-api`**）。  
- 静态托管子目录 **`magnetic-run`**，与构建里的 **`VITE_BASE_PATH=/magnetic-run/`** 一致（若你改用根路径，需同步改脚本与控制台）。

### 0. 前置条件

- 安装 **Node.js**、**Python 3.x（带 pip）**、已安装 **CloudBase CLI** 或允许 **`npx @cloudbase/cli`**。  
- 在终端执行过一次 **`tcb login`**（或等价登录），能选择目标环境。

### 1. Windows：修补 CLI 打 zip 的路径（强烈建议，每台机器 / 每次 npx 更新 CLI 后执行一次）

`npx` 拉下的 `@cloudbase/cli` 在 Windows 上打 zip 可能使用 **反斜杠**，Linux 云函数解压后 **`import backend` 失败**（网关常表现为 **443**）。

```powershell
cd deploy\cloudbase
.\patch-cloudbase-cli-zip.ps1
```

### 2. 安装云函数用 Linux 依赖目录（改了 `backend/requirements.txt` 后必须重做）

```powershell
cd deploy\cloudbase
.\install-scf-site-packages.ps1
```

### 3. 打云函数包并上传

```powershell
cd deploy\cloudbase
.\pack-scf-zip.ps1
```

在 **`%TEMP%`** 建空目录，把仓库根目录生成的 **`scf-deploy.zip`** 解压进去，再执行（**注意管道**，避免 `tcb` 卡在交互菜单）：

```powershell
$dest = Join-Path $env:TEMP "magrun-scf-upload"
Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $dest | Out-Null
Expand-Archive -LiteralPath "..\..\scf-deploy.zip" -DestinationPath $dest -Force
cmd /c "echo.| npx --yes --package=@cloudbase/cli tcb fn code update apihd --dir $dest -e <YOUR_ENV_ID> --yes --json"
```

（路径请按你本机 `scf-deploy.zip` 的实际位置调整。）

### 4. 云函数控制台环境变量（需与前端一致）

| 变量名 | 示例值 | 说明 |
|--------|--------|------|
| `HTTP_ROUTE_PREFIX` | `/my-api` | 与网关暴露路径一致；后端中间件会剥掉此前缀。 |
| `CORS_ORIGINS` | `https://<你的默认域名>.tcloudbaseapp.com` | 多个用英文逗号分隔；需包含静态站完整来源（含路径末级时按控制台要求配置）。 |

超时、内存建议在控制台适当加大；大依赖包冷启动可能较慢。

### 5. 部署前端到静态网站托管

```powershell
cd deploy\cloudbase
.\deploy-hosting.ps1
```

仓库里的 **`deploy-hosting.ps1`** 已写好 **`$envId`、`$CloudPath`、`$ViteBase`、`$ViteApi`**（与你自己云端一致即可）；README 不重复真实 ID。脚本会执行 **`npm run build`** + **`tcb hosting deploy`**。

**访问关系简述**

- 静态页：`https://<默认域名>.tcloudbaseapp.com/magnetic-run/`  
- API：`https://<HTTP访问服务域名>/my-api/api/steps` 等（与控制台「HTTP 访问」里实际域名一致）。

---

## 接下来要加的功能（维护者在此维护列表）

> 提交到 GitHub 前请更新本节，便于排期与 AI 对齐目标。

- [ ] （在此填写：例如「用户登录」「运行历史落库」「新步骤：xxx」）
- [ ] （在此填写）

---

## AI 实施说明（加新功能时请严格按契约改）

以下格式便于 **Cursor / Copilot 等 AI** 直接读取并改代码、再按「云端部署」一节验证。

### A. 只加「新的数据处理步骤」（最常见）

1. **新建文件** `magrun/steps/<唯一英文 id>.py`（文件名建议与 `StepMeta.id` 一致）。  
2. 模块内必须暴露顶层变量 **`step`**，类型满足 **`Step`** 协议（见 `magrun/models.py`）：  
   - **`step.meta`**：`StepMeta`，包含 `id`、`name`、`category`、`description`、`file_types`（扩展名不含点，如 `["txt","xlsx"]`，无文件则 `[]`）、`params`（`StepParam` 列表）。  
   - **`step.run(self, *, files, params)`**：返回 **`StepOutputs`**（`tables` / `downloads` / `images` / `notes`）。  
3. **导入模块不得有副作用**（禁止在 import 时跑 Streamlit、读大文件、连网等）。  
4. 若使用 **新的第三方库**：把依赖写入 **`backend/requirements.txt`**，然后必须 **`.\install-scf-site-packages.ps1`** → **`.\pack-scf-zip.ps1`** → 再按上文上传云函数。  
5. **不要改** `GET /api/steps`、`POST /api/runs` 的 URL 形状，除非同步改 `frontend/src/composables/useRunCenter.js` 与文档。

### B. 改前端 UI / 调用方式

- 主逻辑在 **`frontend/src`**；API 基址仅通过 **`VITE_API_BASE`**（及构建时 **`VITE_BASE_PATH`**）注入。  
- 子路径部署时，**不要随意写死绝对路径** `/assets/...`，应依赖 Vite 的 `base`。

### C. 改后端路由或中间件

- 入口 **`backend/main.py`**；CloudBase 下注意 **`HTTP_ROUTE_PREFIX`** 与 **`CORS_ORIGINS`**。  
- 若新增依赖，同 **A.4**。

### D. 改云端路由或环境 ID

- 同步修改 **`deploy/cloudbase/deploy-hosting.ps1`**（以及你本机实际用来 `tcb` 的命令）里的 **`$envId` / API 根域名**；README 里只用占位符即可。  
- 在控制台更新云函数环境变量与静态托管路径后，再执行构建与部署脚本。

### E. 自检清单（AI 或人类发版前）

- [ ] `magrun` 下 `python -c "from magrun.runner import load_steps; print(len(load_steps()))"` 无异常  
- [ ] 本地 `start-backend.cmd` + `npm run dev` 能跑通步骤  
- [ ] 云端：已 **`patch-cloudbase-cli-zip.ps1`**（Windows）、已 **`install-scf-site-packages`**（若改过 requirements）、已 **`pack-scf-zip`**、已 **`tcb fn code update`**、已 **`deploy-hosting.ps1`**（若改前端）

---

## 许可证与贡献

若需补充 License / CONTRIBUTING，可在本目录追加 `LICENSE`、`CONTRIBUTING.md` 并在此链过去。
