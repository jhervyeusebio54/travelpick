"""Voting engine service implementing Weighted Approval Voting logic.

Functions:
- compute_scores(votes): returns {destination_id: total_weighted_score}
- count_votes(votes): returns {destination_id: vote_count}
- vote_distribution(votes): returns {destination_id: {weight: count}}
- rank_destinations(scores, dest_map): returns sorted list of destinations with scores
- get_winner(scores): returns destination_id of highest-scoring destination (or None)

The functions accept simple Python structures (lists/dicts) so they are easy to test.
"""
from typing import List, Dict, Any, Optional


def compute_scores(votes: List[Dict[str, Any]]) -> Dict[int, int]:
    """Compute total weighted score per destination.

    votes: list of {'destination_id': int, 'weight': int}
    returns: {destination_id: total_score}
    """
    scores: Dict[int, int] = {}
    for vote in votes:
        dest = vote.get("destination_id")
        weight = vote.get("weight", 0) or 0
        try:
            weight = int(weight)
        except Exception:
            weight = 0
        if dest is None:
            continue
        scores[dest] = scores.get(dest, 0) + weight
    return scores


def count_votes(votes: List[Dict[str, Any]]) -> Dict[int, int]:
    """Count number of votes per destination."""
    counts: Dict[int, int] = {}
    for vote in votes:
        dest = vote.get("destination_id")
        if dest is None:
            continue
        counts[dest] = counts.get(dest, 0) + 1
    return counts


def vote_distribution(votes: List[Dict[str, Any]]) -> Dict[int, Dict[int, int]]:
    """Return distribution of weights per destination.

    Example: { dest_id: {1:2, 2:1, 5:3} }
    """
    dist: Dict[int, Dict[int, int]] = {}
    for vote in votes:
        dest = vote.get("destination_id")
        weight = vote.get("weight", 0) or 0
        try:
            weight = int(weight)
        except Exception:
            continue
        if dest is None:
            continue
        if dest not in dist:
            dist[dest] = {}
        dist[dest][weight] = dist[dest].get(weight, 0) + 1
    return dist


def rank_destinations(scores: Dict[int, int], dest_map: Dict[int, str]) -> List[Dict[str, Any]]:
    """Produce a ranking list sorted by total_score desc.

    dest_map: {destination_id: destination_name} ensures we can display names.
    Returns: [ {destination_id, destination, total_score}, ... ]
    """
    # ensure every destination in dest_map appears in ranking (zero default)
    items = [(dest_id, scores.get(dest_id, 0)) for dest_id in dest_map.keys()]
    # sort by score desc, then by name asc for deterministic order on ties
    items.sort(key=lambda kv: (-kv[1], dest_map.get(kv[0], "")))
    return [
        {"destination_id": dest_id, "destination": dest_map.get(dest_id, ""), "total_score": total}
        for dest_id, total in items
    ]


def get_winner(scores: Dict[int, int]) -> Optional[int]:
    """Return the destination_id with the highest score, or None if empty."""
    if not scores:
        return None
    # max by score (ties: first one encountered)
    return max(scores.keys(), key=lambda k: scores.get(k, 0))
