"""Basic input validators used by route handlers."""

from typing import Any


def validate_weight(weight: Any) -> bool:
    """Validate that weight is an integer between 1 and 5.

    Raises ValueError on invalid input.
    """
    try:
        w = int(weight)
    except Exception:
        raise ValueError("Weight must be an integer between 1 and 5")
    if w < 1 or w > 5:
        raise ValueError("Weight must be between 1 and 5")
    return True


def validate_positive_int(value: Any, name: str = "value") -> bool:
    try:
        v = int(value)
    except Exception:
        raise ValueError(f"{name} must be a positive integer")
    if v <= 0:
        raise ValueError(f"{name} must be a positive integer")
    return True
