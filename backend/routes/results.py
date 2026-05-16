from fastapi import APIRouter
from fastapi.responses import JSONResponse
from typing import Dict, List

from .. import server
from ..services.voting_engine import compute_scores, rank_destinations, get_winner, vote_distribution, count_votes

router = APIRouter(prefix="/results", tags=["results"])


@router.get("/{group_id}")
def get_results(group_id: int):
    """Compute weighted approval voting results for a group.

    Returns ranking, winner, total_votes and a breakdown per destination.
    """
    try:
        cur = server.db.cursor(dictionary=True)
        cur.execute("SELECT id, name FROM `groups` WHERE id=%s", (group_id,))
        grp = cur.fetchone()
        if not grp:
            return JSONResponse(content={"error": "Group not found"}, status_code=404)

        # fetch destinations
        cur.execute("SELECT id, name FROM destinations WHERE group_id=%s", (group_id,))
        dests = cur.fetchall() or []
        if not dests:
            return {"winner": None, "total_votes": 0, "ranking": [], "breakdown": []}

        dest_map = {d["id"]: d["name"] for d in dests}

        # fetch votes for those destinations
        cur.execute(
            """
            SELECT v.destination_id, v.weight
            FROM votes v
            JOIN destinations d ON v.destination_id = d.id
            WHERE d.group_id = %s
            """,
            (group_id,),
        )
        votes = cur.fetchall() or []
        total_votes = len(votes)

        # normalize votes to dictionaries for the voting engine
        vote_list = [{"destination_id": v["destination_id"], "weight": v["weight"]} for v in votes]

        scores = compute_scores(vote_list)
        ranking = rank_destinations(scores, dest_map)
        winner_id = get_winner(scores)
        winner = dest_map.get(winner_id) if winner_id is not None else None

        # build breakdown with counts and distribution
        counts = count_votes(vote_list)
        distributions = vote_distribution(vote_list)
        breakdown = []
        for dest_id, name in dest_map.items():
            breakdown.append(
                {
                    "destination_id": dest_id,
                    "destination": name,
                    "total_score": scores.get(dest_id, 0),
                    "vote_count": counts.get(dest_id, 0),
                    "weight_distribution": distributions.get(dest_id, {}),
                }
            )

        return {"winner": winner, "total_votes": total_votes, "ranking": ranking, "breakdown": breakdown}
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)
