# English Translation Context Repair — 2026-10-23

## Root cause

The generator submitted individual Kramdown text nodes to the translation
proxy. Inline code, emphasis, and links split sentences into disconnected
requests. Values such as `12%` and `0.15s` were absent from the corresponding
sentence fragments. The cached English contained invented missing-value
phrases, incorrect units, and words joined at inline element boundaries.
Table cells outside the old text-container allowlist were also left in Chinese.

## Generator repair

Translation units now cover entire paragraphs, headings, and table cells.
Inline AST nodes are surrounded by numbered markers, with their readable
content included in the request. Code blocks and Mermaid blocks are never
submitted. Inline code and other protected nodes are validated and restored
from the original AST, including their attributes. Generated HTML is rendered
by Kramdown; provider-supplied text is not interpreted as new HTML or Markdown.

Before a cache can be replaced, validation requires:

- Exactly one nonempty response per request, including title and description.
  Empty optional source metadata is excluded from requests and retained empty
  (10 historical posts have missing title/description fields).
- The original marker sequence and nesting, with no dropped/duplicated nodes.
- Exact protected literals, including inline code values and punctuation.
- No newly introduced `[value missing]` placeholder.
- No newly joined English words across inline boundaries that originally
  separated words. Intentional existing intra-word formatting is retained.

A failed validation leaves the previous cache intact. A validated result is
written to a temporary file in the same directory and atomically renamed,
preserving file permissions. The proxy request fields and cache schema remain
unchanged. Existing source-hash queue behavior is retained; this does not
schedule a wholesale retranslation of unrelated posts.

## Reviewed cache corrections

Both October 19 English translations were reviewed against their canonical
Markdown, including the 82 prose units, titles, and descriptions. Corrections
cover sentence boundaries, inline identifier spacing, numeric context, device
size punctuation, technical terminology, and the audio verification table.
Reviewed response fixtures are in `tools/fixtures/translation-context/` and
are tied to SHA-256 hashes of their source posts.

The English repair preserves code and Mermaid content. Before committing,
remote translation commit `35da4f9` was fast-forwarded into the local branch.
Its creative-cache update already incorporates the canonical `[RUN_ID]`
diagram correction. The final creative cache combines reviewed English prose
with that upstream version's Chinese payload, source hash, and exact code and
Mermaid nodes. The audio cache retains its original protected nodes and Chinese
payload. Neither canonical Markdown file was modified.

## Verification

```bash
ruby tools/test-translation-context.rb
ruby -c tools/translate-posts.rb
JEKYLL_ENV=production bundle exec jekyll build --future
python3 tools/check-static-assets.py
node tools/test-translation-mermaid.js
```

The regression suite covers nested inline structure, literal values, entities,
links and attributes, table coverage, missing/duplicate markers, malformed
responses, joined words, atomic cache replacement, and invalid-result cache
preservation. It also regenerates both reviewed English fixtures and compares
all code and Mermaid nodes with the source-language output. All 79 posts pass
an identity round trip without any rendered HTML changes.
The full generation path also passes identity translation for all 79 posts,
including those with empty optional metadata.

Production-build browser checks on `127.0.0.1:4187` confirmed:

- Audio attack/release paragraphs display complete values and spaces, without
  `[value missing]`; the verification table is English.
- Creative device sizes and `.xcstrings` sentences display intact punctuation
  and word boundaries.
- Both articles retain code text, diagrams, and valid TOC targets after language
  switches. Dark/light diagram text follows the selected theme.
- The creative English page remains 390 pixels wide on a 390-pixel viewport,
  with both diagrams inside 358-pixel containers.
- No captured browser warnings or errors during these article checks.

The local environment has no `GOOGLE_APPS_SCRIPT_URL`. The real proxy was not
called: reviewed response fixtures exercised the generation and validation
path offline. These checks establish structural protection and rejection of
the observed corruption patterns, not perfect future machine translation or
verified compatibility of the live provider with the marker protocol. If the
provider changes markers or protected values, generation rejects its response
and retains the previous cache rather than publishing corrupted content.

Git LFS remains enabled for normal translation-file handling. Publication
status is reported separately from these local verification results.
