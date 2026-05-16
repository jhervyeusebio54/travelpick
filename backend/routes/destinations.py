from fastapi import APIRouter
from pydantic import BaseModel
from typing import List, Dict, Optional
from fastapi.responses import JSONResponse

from .. import server

router = APIRouter(prefix="/destinations", tags=["destinations"])


class DestinationCreate(BaseModel):
    group_id: int
    name: str
    description: Optional[str] = None


@router.get("/{group_id}")
def list_destinations(group_id: int):
    """List all destinations for a given group."""
    try:
        cur = server.db.cursor(dictionary=True)
        cur.execute("SELECT id FROM `groups` WHERE id=%s", (group_id,))
        grp = cur.fetchone()
        if not grp:
            return JSONResponse(content={"error": "Group not found"}, status_code=404)

        cur.execute("SELECT id, name, description FROM destinations WHERE group_id=%s", (group_id,))
        rows = cur.fetchall() or []
        return rows
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


@router.post("")
def create_destination(dest: DestinationCreate):
    """Create a new destination belonging to a group."""
    name = (dest.name or "").strip()
    if not name:
        return JSONResponse(content={"error": "Destination name is required"}, status_code=400)
    try:
        cur = server.db.cursor(dictionary=True)
        cur.execute("SELECT id FROM `groups` WHERE id=%s", (dest.group_id,))
        grp = cur.fetchone()
        if not grp:
            return JSONResponse(content={"error": "Group not found"}, status_code=404)

        cur = server.db.cursor()
        cur.execute(
            "INSERT INTO destinations (group_id, name, description) VALUES (%s, %s, %s)",
            (dest.group_id, name, dest.description),
        )
        server.db.commit()
        dest_id = cur.lastrowid
        return {"id": dest_id, "group_id": dest.group_id, "name": name, "description": dest.description}
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)
