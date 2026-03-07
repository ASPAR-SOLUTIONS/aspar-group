# CLAUDE.md — AI Assistant Guide for aspar-group

This file provides context for AI assistants (such as Claude) working in this repository.

---

## Project Overview

**Aspar Group Platform** is a citizen franchise platform for Tunisia ("Plateforme de franchises citoyennes en Tunisie"). The repository is in an early MVP phase and uses a no-code/low-code stack rather than traditional software development frameworks.

The working language for documentation is **French**. Code comments and commit messages may also be in French.

---

## Repository Structure

```
aspar-group/
├── CLAUDE.md          # This file — AI assistant guide
├── README.md          # Project overview (French)
├── /docs              # (planned) Analyses, specs, mockups
├── /data              # (planned) Sample data files (CSV, JSON)
├── /backend           # (planned) Scripts or advanced backend logic
└── /frontend          # (planned) Scripts or frontend mockups
```

> Note: Only `README.md` and `CLAUDE.md` exist as of the initial MVP phase. The directory structure above reflects what is planned per the README.

---

## Current Tech Stack

| Layer     | Technology           | Notes                              |
|-----------|----------------------|------------------------------------|
| Data      | Airtable             | Imported via CSV                   |
| Frontend  | Softr                | Connected to Airtable              |
| Docs      | Markdown             | Stored in `/docs` (planned)        |
| Version control | Git / GitHub  | Private repository                 |

There are currently **no code dependencies**, build tools, package managers, test runners, or CI/CD pipelines configured.

---

## Development Conventions

### Language & Naming
- Documentation and comments are primarily in **French**
- File and directory names use lowercase kebab-case (e.g., `aspar-group`)

### Git Workflow
- The `master` branch is the main stable branch
- Feature/AI work branches follow the pattern: `claude/<description>-<session-id>`
- Commits should be clear and descriptive; French commit messages are acceptable
- The repository is **private** during the initial phase — do not expose or share access

### Adding New Directories
When creating the planned directories (`/docs`, `/data`, `/backend`, `/frontend`), follow the structure outlined in the README. Add a brief `README.md` inside each directory explaining its purpose.

---

## No Build Process

There is no build system. Do not attempt to run `npm install`, `pip install`, or any package manager commands — none are configured.

---

## Working with Airtable & Softr

- Airtable is used as the backend database. Data is managed through the Airtable web interface or via CSV imports.
- Softr is the frontend platform, connected to Airtable. UI changes are made in the Softr interface, not in this repository.
- This repository is for **documentation, data examples, and any custom scripts** that supplement the no-code stack.

---

## When Future Code Is Added

If backend or frontend code is introduced (e.g., in `/backend` or `/frontend`), update this file with:
- Language/framework used
- How to install dependencies
- How to run the project locally
- How to run tests
- Relevant environment variables (add a `.env.example`)

---

## Key Contacts & Access

- Keep this repository **private** during the initial phase
- Refer to project maintainers for Airtable and Softr access credentials

---

## AI Assistant Notes

- This is an early-stage project; there is very little code to analyze or modify
- When adding files, respect the planned directory structure (`/docs`, `/data`, `/backend`, `/frontend`)
- Prefer French for documentation files unless the team specifies otherwise
- Do not introduce unnecessary complexity — the MVP philosophy is to use no-code tools wherever possible
- Do not add dependencies, configs, or boilerplate unless explicitly requested
