from __future__ import annotations

import base64
import json
import os
import sys
from pathlib import Path
from typing import Any

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from magrun.models import StepMeta, StepOutputs
from magrun.runner import load_steps

app = FastAPI(title="RunCenter API", version="0.1.0")


def _cors_origins() -> list[str]:
    """本地默认 Vite；线上设置环境变量 CORS_ORIGINS，逗号分隔，如 https://xxx.tcloudbaseapp.com"""
    raw = os.getenv("CORS_ORIGINS", "").strip()
    if raw:
        return [x.strip() for x in raw.split(",") if x.strip()]
    return ["http://127.0.0.1:5173", "http://localhost:5173"]


app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class StepParamOut(BaseModel):
    key: str
    label: str
    kind: str
    default: Any
    options: list[str] | None = None
    help: str | None = None


class StepMetaOut(BaseModel):
    id: str
    name: str
    category: str
    description: str
    file_types: list[str]
    params: list[StepParamOut]


def _meta_out(meta: StepMeta) -> StepMetaOut:
    return StepMetaOut(
        id=meta.id,
        name=meta.name,
        category=meta.category,
        description=meta.description,
        file_types=list(meta.file_types),
        params=[
            StepParamOut(
                key=p.key,
                label=p.label,
                kind=p.kind,
                default=p.default,
                options=p.options,
                help=p.help,
            )
            for p in meta.params
        ],
    )


@app.get("/api/steps", response_model=list[StepMetaOut])
def list_steps() -> list[StepMetaOut]:
    return [_meta_out(x.step.meta) for x in load_steps()]


def _find_step(step_id: str):
    for item in load_steps():
        if item.step.meta.id == step_id:
            return item.step
    raise HTTPException(status_code=404, detail="Unknown step_id")


def _coerce_params(meta: StepMeta, raw: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for p in meta.params:
        if p.key not in raw:
            out[p.key] = p.default
            continue
        v = raw[p.key]
        if p.kind == "int":
            out[p.key] = int(v)
        elif p.kind == "float":
            out[p.key] = float(v)
        elif p.kind == "bool":
            if isinstance(v, bool):
                out[p.key] = v
            else:
                out[p.key] = str(v).lower() in ("1", "true", "yes", "on")
        elif p.kind == "select":
            out[p.key] = str(v)
        else:
            out[p.key] = str(v)
    return out


def _outputs_to_json(outputs: StepOutputs) -> dict[str, Any]:
    tables: dict[str, Any] = {}
    for name, df in outputs.tables.items():
        tables[name] = json.loads(df.to_json(orient="records", date_format="iso"))

    def _b64_blob(fname: str, payload: bytes, mime: str) -> dict[str, str]:
        return {
            "filename": fname,
            "mime": mime,
            "base64": base64.b64encode(payload).decode("ascii"),
        }

    downloads = {
        k: _b64_blob(fname, payload, mime) for k, (fname, payload, mime) in outputs.downloads.items()
    }
    images = {k: _b64_blob(fname, payload, mime) for k, (fname, payload, mime) in outputs.images.items()}

    return {
        "notes": outputs.notes,
        "tables": tables,
        "downloads": downloads,
        "images": images,
    }


@app.post("/api/runs")
async def run_step(
    step_id: str = Form(...),
    params_json: str = Form(default="{}"),
    files: list[UploadFile] = File(default=[]),
) -> dict[str, Any]:
    step = _find_step(step_id)
    meta = step.meta
    try:
        raw_params = json.loads(params_json) if params_json.strip() else {}
        if not isinstance(raw_params, dict):
            raise ValueError("params must be a JSON object")
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid params_json: {e}") from e
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e

    params = _coerce_params(meta, raw_params)

    needs_upload = bool(meta.file_types)
    file_tuples: list[tuple[str, bytes]] = []
    for f in files:
        if f.filename:
            file_tuples.append((f.filename, await f.read()))

    if needs_upload and not file_tuples:
        raise HTTPException(status_code=400, detail="This step requires at least one uploaded file.")

    outputs = step.run(files=file_tuples, params=params)
    return _outputs_to_json(outputs)


FRONTEND_DIST = ROOT / "frontend" / "dist"
FRONTEND_INDEX = FRONTEND_DIST / "index.html"


@app.get("/")
async def serve_root():
    if FRONTEND_INDEX.is_file():
        return FileResponse(FRONTEND_INDEX)
    raise HTTPException(status_code=503, detail="Frontend not built. Run: npm run build")


@app.get("/{full_path:path}")
async def serve_frontend(full_path: str):
    if ".." in full_path:
        raise HTTPException(status_code=404)
    file_path = FRONTEND_DIST / full_path
    if file_path.is_file():
        return FileResponse(file_path)
    if FRONTEND_INDEX.is_file():
        return FileResponse(FRONTEND_INDEX)
    raise HTTPException(status_code=503, detail="Frontend not built. Run: npm run build")
