# Tasks: Article Language Toggle

**Input**: Design documents from `/specs/003-article-lang-toggle/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths included in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create `assets/js/translation.js` for core translation logic
- [x] T002 Create `assets/css/translation.css` for component styling
- [x] T003 [P] Update `_config.yml` with `google_translate` configuration placeholders

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure for DOM manipulation and API communication

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Implement the Google Translate API wrapper (REST client) in `assets/js/translation.js`
- [x] T005 [P] Define CSS classes for translation loading states in `assets/css/translation.css`
- [x] T006 Implement the recursive DOM walker in `assets/js/translation.js` to identify translatable text while excluding `code`, `pre`, and `mermaid` blocks
- [x] T007 Register the custom JS/CSS in `_includes/metadata-hook.html` to ensure they load on all pages

**Checkpoint**: Foundation ready - translation engine and integration points are established

---

## Phase 3: User Story 1 - One-Click Translation (Priority: P1) 🎯 MVP

**Goal**: Allow readers to translate a Chinese article into English with a single click

**Independent Test**: Manually trigger the translation function in the console and verify the article body text (excluding code) becomes English.

### Implementation for User Story 1

- [x] T008 [US1] Implement the `translateArticle()` function in `assets/js/translation.js` to send text nodes to Google API and update the DOM
- [x] T009 [US1] Add the `showLoading()` and `hideLoading()` UI feedback in `assets/js/translation.js` using styles from `assets/css/translation.css`
- [x] T010 [US1] Implement the `revertToOriginal()` function in `assets/js/translation.js` to restore the content from the original DOM source

**Checkpoint**: User Story 1 is functional via manual triggers/console

---

## Phase 4: User Story 2 - UI Integration (Priority: P2)

**Goal**: Provide a visible, theme-consistent toggle button for the translation feature

**Independent Test**: Verify the toggle button appears in the post header on both desktop and mobile, and correctly triggers the functions from US1.

### Implementation for User Story 2

- [x] T011 [US2] Create a new include file `_includes/translation-toggle.html` with the button HTML structure
- [x] T012 [US2] Inject `_includes/translation-toggle.html` into the post layout (via `_includes/metadata-hook.html` DOM injection or layout override)
- [x] T013 [US2] Apply Chirpy-integrated styles to the toggle button in `assets/css/translation.css`
- [x] T014 [US2] Bind the toggle button click events to the translation logic in `assets/js/translation.js`

**Checkpoint**: The feature is now usable via the UI button

---

## Phase 5: User Story 3 - Persistence (Priority: P3)

**Goal**: Remember the user's language preference across different articles

**Independent Test**: Set frequency to English, navigate to a different post, and verify it automatically translates (or shows the English state) on load.

### Implementation for User Story 3

- [x] T015 [US3] Implement `localStorage` get/set logic in `assets/js/translation.js` for the `user-language` key
- [x] T016 [US3] Implement the `autoTranslateOnLoad()` logic in `assets/js/translation.js` that checks for saved preference on `DOMContentLoaded`

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T017 [P] Implement in-memory caching for translated segments in `assets/js/translation.js` to minimize redundant API calls during a session
- [x] T018 [P] Add a "Translation provided by Google" attribution per API requirements in `_includes/translation-toggle.html`
- [x] T019 Final testing for content preservation (ensuring no Markdown or Mermaid syntax is corrupted)
- [x] T020 Run `quickstart.md` validation and document the final configuration steps

---

## Phase P: GitHub Actions Pivot (Secure & Fast)

**Goal**: Move translation logic to build-time using GitHub Actions to hide API keys and improve loading speed.

- [x] T021 Create `tools/translate-posts.js` for build-time Markdown translation
- [x] T022 Integrate translation step into `.github/workflows/pages-deploy.yml` with `GOOGLE_TRANSLATE_API_KEY` secret
- [x] T023 Update `_includes/metadata-hook.html` to remove API Key and pass `page.slug` to JS
- [x] T024 Rewrite `assets/js/translation.js` to fetch pre-translated JSON deltas from `/assets/translations/`
- [ ] T025 Final end-to-end verification of the GitHub Action pipeline

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Blocks all other phases.
- **Phase 2 (Foundational)**: Depends on Phase 1. Blocks all User Stories.
- **Phase 3 (User Story 1)**: Core MVP logic.
- **Phase 4 (User Story 2)**: Depends on US1 functionality.
- **Phase 5 (User Story 3)**: Enhances US1/US2 experience.

### Parallel Opportunities

- T003 (Config) can be done in parallel with T001/T002.
- T005 (CSS states) can be done in parallel with T004 (API wrapper).
- T012 and T013 (UI structure/styles) can be done in parallel once the foundation is set.
- T017, T018 can be done in parallel at the end.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 & 2.
2. Complete US1 (T008-T010).
3. Validate translation via console.

### Incremental Delivery

1. Foundation ready (Phase 2).
2. Translation logic (US1) -> Value: Core capability works.
3. UI Toggle (US2) -> Value: Users can trigger it.
4. Persistence (US3) -> Value: Improved UX.
5. Polish -> Value: Efficiency and compliance.
