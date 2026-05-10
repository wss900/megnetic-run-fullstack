"""
Production launcher: build frontend, free port 8000, start uvicorn, open browser after delay.
Use this from start-prod.cmd so paths with non-ASCII characters and CRLF batch issues are avoided.
"""
from __future__ import annotations

import shutil
import subprocess
import sys
import threading
import time
import webbrowser
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FRONTEND = ROOT / "frontend"
BACKEND = ROOT / "backend"
VENV_PY = BACKEND / ".venv" / "Scripts" / "python.exe"
PORT = 8000


def _which_or_die(name: str, hint: str) -> str:
    path = shutil.which(name)
    if not path:
        print(f"[ERROR] '{name}' not found in PATH. {hint}", flush=True)
        sys.exit(1)
    return path


def _resolve_cli(name: str) -> str:
    """Windows: subprocess needs npm.cmd / npx.cmd, not bare 'npm' (not a .exe)."""
    if sys.platform == "win32":
        w = shutil.which(f"{name}.cmd") or shutil.which(name)
        if w:
            return w
    return _which_or_die(name, f"Install {name} and add it to PATH.")


def _run(cmd: list[str], *, cwd: Path, env: dict | None = None) -> None:
    print(f"[exec] {' '.join(cmd)}", flush=True)
    r = subprocess.run(cmd, cwd=str(cwd), env=env)
    if r.returncode != 0:
        sys.exit(r.returncode)


def _ensure_backend_venv() -> Path:
    pip = BACKEND / ".venv" / "Scripts" / "pip.exe"
    if not VENV_PY.is_file():
        py = _which_or_die("python", "Install Python 3 and add it to PATH.")
        print("[backend] Creating venv and installing dependencies...", flush=True)
        _run([py, "-m", "venv", str(BACKEND / ".venv")], cwd=BACKEND)
        if not pip.is_file():
            print("[ERROR] venv pip missing after creation.", flush=True)
            sys.exit(1)
        req = BACKEND / "requirements.txt"
        _run([str(pip), "install", "-r", str(req)], cwd=BACKEND)
    elif not pip.is_file():
        print("[ERROR] Broken venv: pip.exe missing. Delete backend/.venv and retry.", flush=True)
        sys.exit(1)
    return VENV_PY


def _kill_listeners_on_port_windows(port: int) -> None:
    if sys.platform != "win32":
        return
    try:
        out = subprocess.check_output(
            ["netstat", "-ano"],
            text=True,
            errors="replace",
            creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, "CREATE_NO_WINDOW") else 0,
        )
    except (OSError, subprocess.CalledProcessError):
        return
    pids: set[int] = set()
    needle = f":{port}"
    for line in out.splitlines():
        line = line.strip()
        if needle not in line:
            continue
        if "LISTENING" not in line and "监听" not in line:
            continue
        parts = line.split()
        if not parts:
            continue
        last = parts[-1]
        if last.isdigit():
            pids.add(int(last))
    for pid in pids:
        print(f"[info] Stopping old listener on port {port} (PID {pid})...", flush=True)
        subprocess.run(
            ["taskkill", "/F", "/PID", str(pid)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, "CREATE_NO_WINDOW") else 0,
        )
    if pids:
        time.sleep(1.0)


def _open_browser_later() -> None:
    time.sleep(3.5)
    url = f"http://127.0.0.1:{PORT}/"
    print(f"[info] Opening {url}", flush=True)
    webbrowser.open(url)


def main() -> None:
    print("========================================", flush=True)
    print("  Magnetic Run - Production Mode", flush=True)
    print("========================================", flush=True)

    npm = _resolve_cli("npm")
    _which_or_die("python", "Install Python 3 and add it to PATH.")

    if not FRONTEND.is_dir():
        print("[ERROR] frontend directory not found.", flush=True)
        sys.exit(1)
    if not BACKEND.is_dir():
        print("[ERROR] backend directory not found.", flush=True)
        sys.exit(1)

    print("[1/3] Building frontend...", flush=True)
    if not (FRONTEND / "node_modules").is_dir():
        print("[frontend] npm install ...", flush=True)
        _run([npm, "install"], cwd=FRONTEND)
    _run([npm, "run", "build"], cwd=FRONTEND)
    print("[1/3] Frontend build complete.", flush=True)

    print("[2/3] Preparing backend...", flush=True)
    venv_python = _ensure_backend_venv()

    dist_index = FRONTEND / "dist" / "index.html"
    if not dist_index.is_file():
        print("[ERROR] frontend/dist/index.html missing after build.", flush=True)
        sys.exit(1)

    print("[2/3] Backend ready.", flush=True)
    print("", flush=True)
    print("[3/3] Starting server...", flush=True)
    print("", flush=True)
    print(f"  Local:  http://127.0.0.1:{PORT}/", flush=True)
    print(f"  LAN:    http://<this-PC-IP>:{PORT}/", flush=True)
    print("  Press Ctrl+C to stop", flush=True)
    print("========================================", flush=True)
    print("", flush=True)

    _kill_listeners_on_port_windows(PORT)

    threading.Thread(target=_open_browser_later, daemon=True).start()

    r = subprocess.run(
        [
            str(venv_python),
            "-m",
            "uvicorn",
            "main:app",
            "--host",
            "0.0.0.0",
            "--port",
            str(PORT),
        ],
        cwd=str(BACKEND),
    )
    sys.exit(r.returncode)


if __name__ == "__main__":
    main()
