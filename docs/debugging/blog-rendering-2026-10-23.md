# Blog Rendering Investigation — 2026-10-23

## Scope and evidence

The live pages checked were:

- <https://rbbtsn0w.me/posts/avfoundation-smooth-audio-ducking-mixing/>
- <https://rbbtsn0w.me/posts/app-store-creative-provenance-audit-architecture/>

Both pages rendered their Mermaid diagrams in Chinese and English. The four
Swift blocks and two JSON/Markdown blocks matched the canonical Markdown
exactly in both languages, including punctuation, quotes, arrows, and brackets.
The Markdown audit-report example intentionally displays Markdown syntax.

## Confirmed defect: theme lost during translation

Reproduction: open either live page in dark mode, switch to English, then back
to Chinese. The translation script reinitializes Mermaid with `default` because
it tests `document.documentElement.classList.contains('dark')`. Chirpy 7.6.0
uses `data-bs-theme="dark"`, so the check returns false. Sequence-message text
becomes dark on a dark background even though an SVG exists and no syntax
error is reported.

The fix reads Chirpy's `Theme.resolvedTheme`, with attribute and system-theme
fallbacks. Browser checks of the local fix confirmed light-grey sequence text
in dark mode and `#333` text in light mode after language changes. Returning
to Chinese also restores the canonical page snapshot and rebinds its controls,
instead of restoring potentially older source-language translation HTML.

## Component-version investigation

| Component | Observed evidence | Conclusion |
| --- | --- | --- |
| Chirpy | Repository commit `44b16e1` upgraded 7.5.0 to 7.6.0 on June 22. No subsequent theme dependency change was found. | The theme interface changed, but the incorrect `.dark` check already existed in `877d3ab` on April 4. |
| Mermaid | The live combined CDN URL specifies `mermaid@11`. An individual CDN fetch returned `x-jsd-version: 11.17.2`. The untracked local bundle reports 11.15.0. | Local and current CDN assets differ. This does not establish the version served when the issue was first reported. |
| Ruby dependencies | The latest lockfile commit, `62918c3`, upgrades bigdecimal to 4.1.3. | No evidence connects that update to the browser-side theme defect. |

A browser comparison rendered six fixtures with each of Mermaid 11.15.0 and
11.17.2: all three diagrams from initial publication commit `46ba8d0` and all
three current diagrams. All twelve renders passed. Original `fadeDuration:`
labels, `quietDelay:` labels, `<ID>`, and current `[RUN_ID]` all rendered. These
results do **not** support attributing the observed contrast defect to special
characters becoming invalid after a Mermaid upgrade.

The CDN major-version alias remains a reproducibility concern; no dependency,
CDN configuration, lockfile, or existing local asset was changed during this
investigation.

## Verification and deployment boundary

- The theme unit regression first failed before the helper was implemented,
  then passed for Chirpy's theme API, current/legacy attributes, explicit light
  overriding system dark, and system-theme fallbacks.
- Local browser checks used the same CDN references as production through a
  temporary build override, leaving the existing `_config.yml` edit untouched.
- Both local article pages preserved diagrams through English/Chinese round
  trips in dark mode; the creative article was also checked in light mode.
- At a 390-pixel viewport, the creative page remained 390 pixels wide, and both
  diagrams fit within the article width.
- The existing translation round-trip regression and Mermaid source tests pass.
- Jekyll build and both pre-publish checks pass. The pre-publish checks retain
  the existing advisory that `og:description` is missing.

The live behavior was observed; the JavaScript/CSS repair is local and uncommitted.
It has not been deployed or verified as a production fix.

## Broader framework audit

The three October 23 Build and Deploy runs succeeded. The latest run
[39948316548](https://github.com/RbBtSn0w/rbbtsn0w.github.io/actions/runs/39948316548)
started from `39a72a1`, used Ruby 3.2.11, Jekyll 4.4.1, Chirpy 7.6.0,
and bigdecimal 4.1.3, and passed HTML-Proofer (1,183 internal links,
74 files with hash checks). Local Ruby is 3.2.9; this runtime difference
did not prevent either build from succeeding.

### Shared CDN dependency failure

At approximately 12:34–12:38 UTC, the live homepage and archives raised
`dayjs is not defined` and `SimpleJekyllSearch is not defined`.
The homepage still failed after a reload; entering `AVFoundation` and
dispatching a real keyboard event produced no results. The archives retained
79 static article links, despite the client-side errors.

The failing shared dependencies are loaded from one jsDelivr `/combine/` URL.
Opening that exact resource in the same browser failed with
`net::ERR_TUNNEL_CONNECTION_FAILED`; a separate command-line fetch failed
during TLS connection establishment. This demonstrates a failure on the
current access path, **not** a proven worldwide CDN outage or a package
version incompatibility. The older Xcode 27 article rendered two diagrams
and emitted no captured warnings/errors, so failure is not uniform across
resource URLs/cache states.

A temporary production build used the existing untracked `assets/lib/`
files with `assets.self_host.enabled: true` and `env: production`, without
editing the repository configuration. At localhost:4184, the same search
returned the audio article and produced no captured errors. All 16 distinct
library files directly referenced by generated HTML exist in that build.
This is a working candidate, not a deployed fix or an exhaustive audit of
transitive font/module assets.

At the initial audit, the existing `_config.yml` edit enabled self-hosting only
for `development`. The maintainer subsequently authorized production
self-hosting. The final configuration retains `enabled: true` and uses YAML
null (`env:`), enabling both environments. An empty string (`env: ""`) is
truthy in Liquid and incorrectly keeps CDN selection; the initial suggestion
to use an empty string was disproved by the generated HTML and corrected.
Existing library versions were retained, without an upgrade/rollback.

### Development appearance, metadata, and cache findings

- Chirpy 7.6 development output separately requests Bootstrap CSS from
  jsDelivr; the current connection failure produces a visibly broken layout
  even when the other assets are self-hosted. Production output includes
  Bootstrap in the generated theme stylesheet and the candidate layout is
  normal. Use a production-mode preview for release validation.
- Translation loading CSS also used an incompatible `[data-theme='dark']`
  selector. It now uses Chirpy's `[data-bs-theme='dark']`.
- `og:description` is present alongside `name="twitter:description"` on one
  meta element. The pre-publish parser records `name` **or** `property`, so
  its warning is a false positive, not missing production metadata.
- The generated service-worker config is `const swconf = { purge: true };`
  because `pwa.cache.enabled` is absent. `pwa.enabled: true` alone does not
  enable caching in this theme. No evidence establishes service-worker
  caching as the cause of the observed CDN failures. The official v7.5.0
  configuration already required the same `pwa.cache.enabled` setting;
  this is not a newly introduced 7.6 requirement.

Node regressions, JavaScript syntax validation, Jekyll build, both individual
pre-publish gates, and `git diff --check` passed after the scoped fixes.
During that initial audit, no dependency, lockfile, workflow, or existing
configuration edit was changed.

## Authorized production configuration and final validation

The repository configuration now enables self-hosting in production as well
as development. The build below uses the real configuration, without a
temporary override:

```bash
JEKYLL_ENV=production bundle exec jekyll build --future
python3 tools/check-static-assets.py
node tools/test-translation-mermaid.js
```

`check-static-assets.py` first failed against the empty-string configuration,
then passed after the YAML-null correction. It checks generated HTML for
jsDelivr/Google Fonts dependencies and follows library CSS font/image URLs.
The final result is 316 HTML pages, 16 directly referenced library files,
and 35 local files including CSS dependencies, with no missing files or
external theme dependencies found. This is not a guarantee that every optional
JavaScript feature's dynamic imports were exercised. Analytics, advertising,
and comment services remain external integrations.

The existing `assets/lib/` directory is an ordinary untracked directory, not
an initialized Git submodule or an indexed gitlink. It must be included with
the eventual authorized commit; publishing the configuration alone would
omit the dependencies. No staging, commit, push, or deployment was performed.
The deployed website therefore still has the old configuration until release.

Browser verification used `http://127.0.0.1:4185` and the production output:

| Check | Result |
| --- | --- |
| Homepage search | `AVFoundation` finds the audio article; `证据闭环` finds the creative article; an unmatched query shows the no-results message. |
| Audio article | Four code blocks match canonical Markdown exactly across seven desktop language/theme states; one Mermaid sequence diagram renders in each state. |
| Creative article | Two code blocks match canonical Markdown exactly across six desktop language/theme states; both diagrams render in each state. |
| Themes | Sequence text is `rgb(211, 211, 211)` in dark mode and `rgb(51, 51, 51)` in light mode, including after language changes. |
| Repeated switching | Audio passed two dark-mode round trips plus a light-mode round trip; creative passed light/dark round trips. |
| Refresh | Creative retained English preference and both diagrams after reload. |
| Navigation | All recorded TOC hashes resolve to actual headings after each desktop language change; a TOC click scrolls to its section. |
| Narrow screens | At 390 pixels, both articles remain 390 pixels wide, with diagram containers at 358 pixels; audio checked in both languages and creative in both languages. |
| Assets and errors | No broken completed article images or captured article console warnings/errors in the final browser checks. |

HTML-Proofer passed 1,188 internal links across 316 files and hash checks in
74 files. Jekyll doctor, JavaScript syntax validation, source/theme regressions,
both pre-publish checks, and diff whitespace validation also passed. The
pre-publish `og:description` warnings remain the parser false positive
described above.

### Separate translation-content finding

Update: the subsequently authorized content and generator repair is recorded
in [Translation Context Repair](translation-context-repair-2026-10-23.md).
The paragraph below records the initial finding before that repair.

Visual review also exposed English word-boundary corruption and invented
`[value missing]` text. The follow-up generator and reviewed-cache repair is
included in this change; see [Translation Context Repair](translation-context-repair-2026-10-23.md)
for the root cause, protected-code contract, regression evidence, and live
provider verification limitation.

## Primary sources

- [Chirpy 7.5.0 theme source](https://github.com/cotes2020/jekyll-theme-chirpy/blob/v7.5.0/_javascript/theme.js)
- [Chirpy 7.6.0 changelog](https://github.com/cotes2020/jekyll-theme-chirpy/blob/v7.6.0/docs/CHANGELOG.md)
- [Mermaid sequence-diagram entity syntax](https://mermaid.js.org/syntax/sequenceDiagram.html#entity-codes-to-escape-characters)
