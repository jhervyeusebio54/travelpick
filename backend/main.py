"""FastAPI application bootstrap for TravelPick backend.

This module wires route modules and exposes the FastAPI `app` instance.
Run with: `uvicorn backend.main:app --reload` from repository root.
"""
from fastapi import FastAPI

from .routes.groups import router as groups_router
from .routes.destinations import router as destinations_router
from .routes.votes import router as votes_router
from .routes.results import router as results_router

app = FastAPI(title="TravelPick Backend")

# register routers (each router defines its own prefix)
app.include_router(groups_router)
app.include_router(destinations_router)
app.include_router(votes_router)
app.include_router(results_router)


@app.get("/")
def root():
    return {"message": "TravelPick Backend. Visit /docs for API documentation."}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)
