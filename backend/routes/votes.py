from fastapi import APIRouter
from pydantic import BaseModel
from typing import Dict, List
from fastapi.responses import JSONResponse

from .. import server
from ..utils.validators import validate_weight

router = APIRouter(prefix="/votes", tags=["votes"])


class VoteCreate(BaseModel):
    user_id: int
    destination_id: int
    weight: int


@router.post("")
def submit_vote(vote: VoteCreate):
    """Submit or update a vote.

    If a vote by the same user on the same destination exists, update its weight.
    Otherwise create a new vote.
    """
    try:
        # basic input validation
        if not isinstance(vote.user_id, int) or vote.user_id <= 0:
            return JSONResponse(content={"error": "Invalid user_id"}, status_code=400)
        if not isinstance(vote.destination_id, int) or vote.destination_id <= 0:
            return JSONResponse(content={"error": "Invalid destination_id"}, status_code=400)
        try:
            validate_weight(vote.weight)
        except ValueError as ve:
            return JSONResponse(content={"error": str(ve)}, status_code=400)

        cur = server.db.cursor(dictionary=True)
        # ensure destination exists
        cur.execute("SELECT id FROM destinations WHERE id=%s", (vote.destination_id,))
        dest = cur.fetchone()
        if not dest:
            return JSONResponse(content={"error": "Destination not found"}, status_code=404)

        # ensure user exists (basic check)
        cur.execute("SELECT id FROM users WHERE id=%s", (vote.user_id,))
        user = cur.fetchone()
        if not user:
            return JSONResponse(content={"error": "User not found"}, status_code=404)

        cur = server.db.cursor()
        cur.execute(
            "SELECT id FROM votes WHERE user_id=%s AND destination_id=%s",
            (vote.user_id, vote.destination_id),
        )
        existing = cur.fetchone()
        if existing:
            vote_id = existing[0]
            cur.execute("UPDATE votes SET weight=%s WHERE id=%s", (vote.weight, vote_id))
            server.db.commit()
            return {"message": "Vote updated", "vote_id": vote_id, "user_id": vote.user_id, "destination_id": vote.destination_id, "weight": vote.weight}

        cur.execute(
            "INSERT INTO votes (user_id, destination_id, weight) VALUES (%s, %s, %s)",
            (vote.user_id, vote.destination_id, vote.weight),
        )
        server.db.commit()
        new_id = cur.lastrowid
        return {"message": "Vote recorded", "vote_id": new_id, "user_id": vote.user_id, "destination_id": vote.destination_id, "weight": vote.weight}
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


@router.get("/{group_id}")
def get_votes(group_id: int):
    """Return all votes for a given group (joins destinations)."""
    try:
        cur = server.db.cursor(dictionary=True)
        cur.execute("SELECT id FROM `groups` WHERE id=%s", (group_id,))
        grp = cur.fetchone()
        if not grp:
            return JSONResponse(content={"error": "Group not found"}, status_code=404)

        cur.execute(
            """
            SELECT v.id, v.user_id, v.destination_id, v.weight, d.name as destination_name
            FROM votes v
            JOIN destinations d ON v.destination_id = d.id
            WHERE d.group_id = %s
            """,
            (group_id,),
        )
        rows = cur.fetchall() or []
        return rows
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)
