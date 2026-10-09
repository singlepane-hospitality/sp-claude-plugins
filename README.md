# Singlepane for Claude

Official [Singlepane](https://www.singlepaneapp.com) plugin marketplace for Claude.

## The `singlepane` plugin

One plugin, three pieces:

- **Singlepane MCP connector** (`https://ai.singlepaneapp.com/mcp`) — lets Claude look
  up your hotels and query Singlepane data directly. On first use you'll be prompted
  to sign in to Singlepane to authorize the connection.
- **Excel modeling skill** — teaches Claude to build Excel financial models with the
  Singlepane Excel add-in's `SP.*` functions: summary P&Ls and department schedules on
  canonical USALI layouts, variance reports, portfolio rollups, STR comp-set
  dashboards, and OTB/pace reports. Requires the Singlepane Excel add-in (and a
  Singlepane login) for workbooks to populate with data.
- **Docs skill (PowerPoint & Word)** — teaches Claude to build slide decks and
  documents whose numbers refresh through the Singlepane Docs add-in: `<<Variable>>`
  tags in slides/paragraphs/tables backed by financials, STR, and OTB query
  variables — monthly performance decks, board and owner reports, lender updates.
  Requires the Singlepane Docs add-in (and a Singlepane login) for documents to
  populate with data.

More skills will ship in this same plugin over time — installed users get them
automatically on update.

The step-by-step guide with screenshots lives on the website:
[Installing Singlepane for Claude](https://www.singlepaneapp.com/resources/installing-singlepane-for-claude/).

## Install for yourself (any plan)

**Claude desktop app or claude.ai** — Customize → Plugins → Add → Add marketplace →
Add from a repository, paste `https://github.com/singlepane-hospitality/sp-claude-plugins`,
Sync, then open the Singlepane plugin and click Install. On a Team or Enterprise plan
this works as long as your admin has left the "User-created skills" policy on.

**Claude Code** (terminal or the desktop app's Code tab):

```
/plugin marketplace add singlepane-hospitality/sp-claude-plugins
/plugin install singlepane@singlepane
```

When adding the marketplace, Claude shows a standard notice about third-party
sources — that's expected for any non-Anthropic marketplace.

**Updates**: `/plugin update singlepane` in Claude Code, or let Claude's periodic
marketplace refresh pick it up.

## Install for your whole organization (Team / Enterprise admins)

claude.ai no longer accepts a public GitHub repository as an organization marketplace,
so org admins deploy the plugin from a zip instead. No GitHub account is needed.

### claude.ai, the desktop app and Cowork

1. Download the current plugin zip:
   **[singlepane.zip](https://github.com/singlepane-hospitality/sp-claude-plugins/releases/download/latest/singlepane.zip)**
   (always the newest build; versioned copies are on the
   [releases page](https://github.com/singlepane-hospitality/sp-claude-plugins/releases)).
2. In claude.ai, go to **Organization settings → Plugins & skills**, click **Add**, then
   **Upload a plugin**, and pick the zip. (Requires the Owner role.)
3. In the plugin's row menu choose **Default access** and pick **Installed by default**
   (members can turn it off) or **Required** (they can't). **Available to install** lists
   it under Discover for members to opt in.
4. Done. The Singlepane connector is bundled in the plugin and shows on its
   **Connectors** tab after upload; members connect it with their own Singlepane
   login. To manage it centrally, or if members can't see it, it can also be added
   under **Organization settings → Connectors** (`https://ai.singlepaneapp.com/mcp`).

Members get the plugin in chat and Cowork, and in Claude Code sessions signed in with
their claude.ai account (synced plugins, Claude Code 2.1.273+).

**Updates are manual**: uploaded plugins don't auto-update. When Singlepane announces a
new version, download the zip again and use **Upload new version** from the plugin's
menu in the Inventory tab.

### Claude Code managed settings (developers whose terminal sessions don't sync)

Paste this into **Organization settings → Claude Code → Managed settings**, or ship it
via MDM / `managed-settings.json`. It registers a hosted catalog whose plugin source is
a sha256-pinned zip on this repo's releases, so machines need no git credentials.

```json
{
  "extraKnownMarketplaces": {
    "singlepane": {
      "source": {
        "source": "url",
        "url": "https://github.com/singlepane-hospitality/sp-claude-plugins/releases/download/latest/marketplace.json"
      },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "singlepane@singlepane": true
  }
}
```

If you use a `strictKnownMarketplaces` allowlist, add the same `url` source to it (and
`{ "source": "skills-dir" }`, or skills-directory plugins stop loading). With
`autoUpdate` on, new versions install at the start of the next session.

## claude.ai and Microsoft 365 add-in users (Claude for Excel / Word / PowerPoint)

Skills enabled in a user's claude.ai account carry into the Claude for Excel, Word and
PowerPoint sidebars. The plugin above covers this once it's installed; if you'd rather
distribute a single skill on its own, every merge to `main` also republishes the
skills as `.skill` files:

- [singlepane-excel-modeling.skill](https://github.com/singlepane-hospitality/sp-claude-plugins/releases/download/latest/singlepane-excel-modeling.skill)
- [singlepane-docs.skill](https://github.com/singlepane-hospitality/sp-claude-plugins/releases/download/latest/singlepane-docs.skill)

Upload them under claude.ai → Settings → Capabilities → Skills (individuals) or
Organization settings → Plugins & skills → Add → Upload a skill (admins). A `.skill`
file does not include the Singlepane connector; add that separately if Claude should
query Singlepane data directly (inside the Office add-ins the add-ins themselves provide
the live data, so the connector is optional there).

## Releasing (maintainers)

Every push to `main` that touches `plugins/` runs
[`release.yml`](.github/workflows/release.yml), which calls
[`scripts/build-release.sh`](scripts/build-release.sh) and publishes:

| Asset | Where | Used by |
| --- | --- | --- |
| `singlepane-<ver>.zip` | release `v<ver>` (immutable) | `archive` source in the hosted `marketplace.json` |
| `singlepane.zip` | rolling release `latest` | org admin upload link on the website |
| `marketplace.json` | rolling release `latest` | Claude Code managed settings (`url` marketplace source) |
| `*.skill` | rolling release `latest` | standalone skill uploads |

**Bump `version` in `plugins/singlepane/.claude-plugin/plugin.json` with every plugin
change.** Claude Code only offers an update when that string changes, and the workflow
refuses to overwrite an existing `v<ver>` release with different contents. The zip is
built deterministically (fixed mtimes, sorted entries), so the same source always
yields the same sha256. Run `scripts/build-release.sh` locally to preview `dist/`.

The in-repo `.claude-plugin/marketplace.json` keeps the relative `./plugins/singlepane`
source for people who add the GitHub repo directly; the hosted copy swaps that for the
archive source because a URL-sourced marketplace can't resolve relative paths.
