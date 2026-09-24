# Schemas — Project Reference

> Reference doc for team members joining the project. Read this first, then the
> JSON schemas in `cdf/` and the `README.md` at the repo root.

## One-line summary

This repository holds **TTRPG JSON schemas** meant to be served as one static
content collection that builds into a **single Docker container** and is reachable
under **multiple domain names** at once. Any schema can be fetched from any of
those domain names.

## What this project is

- It is a **single git repository** that holds static schema files. No server
  application code, no API endpoints — the container just **serves static files**.
- The schemas describe table-top role-playing "rulesets" (e.g. `open5e`, `dnd5e`)
  and the data that flows from them (rulesets, entity definitions, entity
  instances). They are JSON Schema documents used by a downstream app to render and
  validate that data.
- The whole tree is shipped as **one static website image** and served behind a
  web server. Because all domains resolve to the same served tree, **any schema is
  readable from any domain name** — that is intentional, not a bug.

## Repository layout (current `develop` / `main`)

```
.
├── Dockerfile                     # how the container is built (see below)
├── README.md                      # short one-paragraph project intent
├── Project.md                     # this file
├── package.json                   # package name/version + packageManager (yarn 4.9.2)
├── .env                           # gitignored; holds DOCKER_REGISTRY (local/secret)
├── .env.example                   # committed template for .env
├── tools/
│   └── build-docker-release.sh    # build + tag + push + version bump
└── cdf/
    └── v1/
        ├── manifest.json          # RulesetManifest schema
        ├── entity-definition.json # RulesetEntityDefinition schema
        └── entity.json            # Entity instance schema
```

## The schemas (`cdf/v1/`)

All three are **JSON Schema (draft 2020-12)**. Their `$id` lives under the
`https://schemas.ttrpgwith.me/` base and is the canonical URL a consumer would
fetch. All of them use `additionalProperties: true`, so they are **open/extensible**
— new domain-specific keys are expected rather than an error.

| File | `$id` / title | Purpose |
|------|---------------|---------|
| `cdf/v1/manifest.json` | `RulesetManifest` | Declares a whole ruleset package: identity (`id`/`uuid`, `name`, `version`), metadata (`author`/`authors`, `license`, `homepage`), the `entities` and `templates` it provides, `assets`, inter-`dependencies` on other rulesets, and `settings`. Required: `id`, `name`, `version`, `entities`. |
| `cdf/v1/entity-definition.json` | `RulesetEntityDefinition` | Defines an entity *type* within a ruleset (e.g. `character`, `monster`, `spell`, `item`): its property `schema`, `calculated_properties` (derived fields via expressions), `default_values`, and an optional recursive `ui` descriptor that drives edit-mode editors. Required: `id`, `name`, `schema`. |
| `cdf/v1/entity.json` | `Entity` | A concrete stored entity *instance* (character, monster, …): `uuid`, `ruleset_id`, `entity_type`, `display_name`, and a `properties` bag that supports an extended value syntax (primitives, arrays, nested objects, and `extendedProperty` with `value`/`base`/`expr`/`modifiers`/`min`/`max`/`override`). Required: `uuid`, `ruleset_id`, `entity_type`, `display_name`, `properties`. |

How the three fit together: a **`manifest`** lists the `entities` (each referencing
an `entity-definition`) and the `templates` that render/edit them; an
**`entity-definition`** describes one entity type's shape and its editor `ui`; an
**`entity`** is a stored instance that a consumer validates/renders using the
definition named in its `entity_type`.

### Template & editor notes (from the schemas)

- A **template descriptor** (in `manifest.json`) carries a `mode`: `sheet`/`view`/
  `card`/`print` are read-only display templates; `edit` is a full editor form;
  `widget` is a reusable field-level editor partial (referenced from entity
  definitions via `ui.widget` and from other templates by id) rather than a
  directly requestable page. Default `mode` is `sheet`; default `engine` is `html`.
- An **`entity-definition.ui`** (and each of its nested `fields`) can set
  `widget`, `label`, `placeholder`, `hidden`, `readonly`, `order`, and free-form
  `config` — this is the metadata app uses to build editor forms.

## How it is served

- **`Dockerfile`**: multi-line but minimal — `FROM lipanski/docker-static-website:latest`
  then `COPY . .`. The base image is a ready-made static web server; the build just
  copies the static tree (schemas + any assets) into the web root.
- **Domain routing**: because every domain resolves to the same served static tree,
  a single nginx (or equivalent) config with `server_name` for each domain pointing
  at the one tree is enough — **no per-domain directory is required**, and any
  schema is fetchable from any domain.
- **Registry**: images are pushed to the Docker registry named in `.env`
  (`DOCKER_REGISTRY`, e.g. `registry.tomusan.com`). `.env` is **gitignored**
  (it is a local/secret file); `.env.example` is the committed template.

## Build & release

`tools/build-docker-release.sh` is the release entry point:

1. Sources `.env` for `DOCKER_REGISTRY`.
2. Reads `version` and `name` from `package.json` (via `jq`).
3. `docker build -t <name>:<version> -t <name>:latest .`
4. Tags for the registry and **pushes** both `<version>` and `latest`.
5. Bumps the **patch** version in `package.json`, commits `Bump version to <version>`,
   tags `v<version>`, and pushes the tag and `main`.

Requires `docker` and `jq` on the PATH, plus a working `.env`.

### Versioning

- Package version lives in `package.json` (`"version"`; current `0.1.3`).
- Each release is also a `git` tag `vX.Y.Z` (tags `v0.1.0`…`v0.1.2` exist;
  `0.1.3` is the current in-progress version, not yet tagged).

## Environment

- **package.json**: name `ttrpg-schemas`, `private: true`,
  `packageManager: yarn@4.9.2` (Yarn 4 via Corepack).
- **`.env`** → `DOCKER_REGISTRY=registry.tomusan.com`. **Do not commit `.env`**
  (it is ignored); start a new machine from `.env.example`.

## Branching & where things live

- **`main` and `develop`** currently point at the same head and carry the live
  served content above (schemas + Dockerfile + build tooling).
- **Older per-domain content** (e.g. a `demo/2048` grid game, and `starter/jquery`,
  `starter/react`, `starter/node` web-starters) lives in a **local mirror at
  `/Users/tom/Projects/base.git`**, not in the current `develop`/`main` tree. Treat
  that mirror as historical/legacy; the current project is the `cdf/v1` schema set.
- **Worktree layout**: this repo uses git worktrees; `.worktrees` and `.env` are
  both in `.gitignore`.

## What is NOT in this repo

- No application / API server code (the `Dockerfile` only serves static files).
- No CI/CD config (release is driven by `tools/build-docker-release.sh`).
- No secrets committed — `.env` is gitignored; only `.env.example` is tracked.
- No nginx config committed (routing is done by the host serving one tree under
  several `server_name`s).

## Open items

- [ ] Add an `nginx.conf` (or equivalent) that maps each domain name to the single
      served static tree, so the "any schema from any domain" behavior is explicit.
- [ ] Decide whether the older per-domain content in `base.git` (demo/starter) should
      be archived, removed, or kept as reference.
- [ ] Consider a `main` `README.md` line that points new team members here.
