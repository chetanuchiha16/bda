# =============================================================================
# Assignment 2 Makefile (Track B Part 2: Practical Extension)
# =============================================================================

.DEFAULT_GOAL := run
UVICORN := uv run uvicorn

.PHONY: run dev

run:
	$(UVICORN) backend.main:app --reload --host 0.0.0.0 --port 8000

dev: run
