# Research: Article Language Toggle

## Decision: Implementation Strategy

### What was chosen
- **Technology**: Google Cloud Translation API via a **Google Apps Script (GAS) Proxy**.
- **UI Component**: A custom floating action button in the post meta header.
- **Persistence**: `localStorage` to remember language preference.
- **Security**: The API key is stored in the GAS project / CI secrets and never shipped to the browser. Access is protected via a shared token.

### Rationale
- The user specifically requested "Google Translate API capabilities".
- GitHub Pages is a static host, so we use an external GAS-based proxy/workflow to handle secrets and stay keyless.
- Build-time translation (Markdown -> JSON) avoids real-time latency and costs.
- Custom implementation provides a premium, integrated feel compared to the legacy Google Translate widget.

### Alternatives Considered
- **Client-Side API calls**: Rejected because embedding API keys in a public repo is insecure (even with domain restriction).
- **Google Translate Element (Dropdown)**: Rejected because it's deprecated and looks "cheap".
- **Jekyll-Polyglot (Manual translation)**: Rejected as the user explicitly asked for automated Google Translation.

## Decision: Chirpy Theme Integration

### What was chosen
- **Hook Point**: `_includes/metadata-hook.html` for loading the translation JS/CSS and configuration.
- **Article Selection**: Target `.post-content` for replacement.
- **Button Placement**: Injected after the `.post-meta` header.

### Rationale
- `metadata-hook.html` is the standard Chirpy extension point.
- Placing the toggle near the title ensures high discoverability.

## Decision: Translation Logic

### What was chosen
- **Build-time Extraction**: A Node.js script extracts translatable bits from Markdown using a robust regex.
- **GAS Atomic Call**: Entire articles are sent in one request to ensure consistency and quality.
- **Client-side Rendering**: `marked.js` renders the translated Markdown into the browser DOM to preserve styles.

### Rationale
- Preserving styles while ensuring high-quality translation is critical.
- Client-side rendering avoids having to parse Markdown in a complex way during the build phase without a standard library.
