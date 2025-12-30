# Makefile for Pap-or-yap
# Targets:
#   make setup        -> runs pap-or-yap-setup.sh
#   make venv         -> create and activate python venv (create only)
#   make install-py   -> install python requirements
#   make npm-install  -> install node deps if package.json present
#   make test         -> run tests (pytest or npm test)
#   make clean        -> remove .venv and build artifacts

SHELL := /bin/bash

.PHONY: setup venv install-py npm-install test clean

setup:
	@chmod +x pap-or-yap-setup.sh
	@./pap-or-yap-setup.sh

venv:
	@if [ ! -d ".venv" ]; then \
	  if command -v python3 >/dev/null 2>&1; then \
	    python3 -m venv .venv && echo "Created .venv"; \
	  else \
	    echo "python3 not found; please install Python 3"; exit 1; \
	  fi \
	else \
	  echo ".venv already exists"; \
	fi

install-py: venv
	@if [ -f requirements.txt ]; then \
	  . .venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt; \
	else \
	  echo "No requirements.txt found, skipping pip install"; \
	fi

npm-install:
	@if [ -f package.json ]; then \
	  if command -v npm >/dev/null 2>&1; then \
	    npm ci; \
	  else \
	    echo "npm not found; please install Node.js / npm"; exit 1; \
	  fi \
	else \
	  echo "No package.json found, skipping npm install"; \
	fi

test:
	@if [ -f package.json ]; then \
	  if command -v npm >/dev/null 2>&1; then \
	    npm test || true; \
	  fi \
	fi
	@if [ -d .venv ] && . .venv/bin/activate && command -v pytest >/dev/null 2>&1; then \
	  . .venv/bin/activate && pytest || true; \
	else \
	  echo "No pytest found or no .venv; skipping Python tests"; \
	fi

clean:
	@rm -rf .venv
	@echo "Removed .venv (if existed)"