from fastapi import APIRouter
from pydantic import BaseModel
from typing import List, Dict
from fastapi.responses import JSONResponse

from .. import server

router = APIRouter(prefix="/groups", tags=["groups"])


class GroupCreate(BaseModel):
    name: str


@router.get("", response_model=List[Dict])
def get_groups():
    """Return all groups."""
    try:
        cur = server.db.cursor(dictionary=True)
        cur.execute("SELECT id, name FROM `groups`")
        rows = cur.fetchall() or []
        return rows
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


@router.post("")
def create_group(group: GroupCreate):
    """Create a new group."""
    name = (group.name or "").strip()
    if not name:
        return JSONResponse(content={"error": "Group name is required"}, status_code=400)
    try:
        cur = server.db.cursor()
        cur.execute("INSERT INTO `groups` (name) VALUES (%s)", (name,))
        server.db.commit()
        group_id = cur.lastrowid
        return {"id": group_id, "name": name}
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


@router.get("/{group_id}")
def get_group(group_id: int):
    """Return a single group's details."""
    try:
        cur = server.db.cursor(dictionary=True)
        cur.execute("SELECT id, name FROM `groups` WHERE id=%s", (group_id,))
        row = cur.fetchone()
        if not row:
            return JSONResponse(content={"error": "Group not found"}, status_code=404)
        return row
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)
