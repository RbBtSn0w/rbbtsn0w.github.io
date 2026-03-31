# Feature Specification: Article Language Toggle

**Feature Branch**: `003-article-lang-toggle`  
**Created**: 2026-03-31  
**Status**: Draft  
**Input**: User description: "利用jykyii平台的能力, 提供一个在页面显示中英文切换的按钮, 当读者阅读需要翻译就点击按钮, 然后将文章翻译为英文阅读模式。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One-Click Translation to English (Priority: P1)

As a non-Chinese speaking reader, I want to click a button on a Chinese article so that I can read its content translated into English without leaving the page.

**Why this priority**: Focuses on the core requirement of enabling English reading mode for articles.

**Independent Test**: Can be tested by opening a post, clicking the "English" button, and verifying the content becomes English.

**Acceptance Scenarios**:

1. **Given** I am viewing a blog post in Chinese, **When** I click the "English" toggle button, **Then** the article body text is replaced with an English translation.
2. **Given** an article is already translated, **When** I click the "Chinese" toggle button, **Then** the article content reverts to the original Chinese text.

---

### User Story 2 - UI Integration and Layout (Priority: P2)

As a reader, I want the translation button to be consistently located and clearly labeled so that I can easily find it on any device.

**Why this priority**: Ensures the feature is discoverable and usable across the site.

**Independent Test**: Verification of the button position in sidebar or header across different screen sizes.

**Acceptance Scenarios**:

1. **Given** any article page, **When** the page loads, **Then** a language switch button or toggle is visible in a prominent location (e.g., sidebar or top navigation).
2. **Given** a mobile device, **When** viewing an article, **Then** the language switch remains accessible (not hidden or overlapping other UI elements).

---

### User Story 3 - Reading State Persistence (Priority: P3)

As a reader, I want my language preference to persist while I navigate other articles so that I don't have to click the button for every page.

**Why this priority**: Enhances user experience for multi-article reading sessions.

**Independent Test**: Clicking translate on one post, navigating to another, and seeing it automatically translated (if possible).

**Acceptance Scenarios**:

1. **Given** I have enabled English mode on post A, **When** I navigate to post B, **Then** post B should automatically attempt to display in English (or show the English toggle active).

---

### Edge Cases

- **What happens when the translation service is unavailable?** The system should show a friendly error message and keep the original content.
- **How does the system handle code blocks or technical terms?** Code blocks and inline code should remain untranslated to preserve technical accuracy.
- **What if an article already has a manual English version?** The system should prioritize the manual translation if available, otherwise use AI translation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a UI toggle button (CN/EN) on all article pages.
- **FR-002**: The system MUST integrate with the **Google Translate API** to perform on-the-fly text translation of the article content.
- **FR-003**: The translation process MUST preserve the formatting (Markdown/HTML) of the article.
- **FR-004**: The system MUST provide a loading indicator while translation is in progress.
- **FR-005**: The system MUST allow users to switch back to the original language immediately without reloading the page if possible.

### Key Entities *(include if feature involves data)*

- **Article Content**: The source Markdown/HTML content of the post.
- **Translation Cache**: Temporary storage of translated text to avoid redundant API calls (optional/performance).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Translation starts within 500ms of clicking the button.
- **SC-002**: Page layout remains stable (no layout shifts) after translation content is injected.
- **SC-003**: 100% of the main article body is covered by the translation service.
- **SC-004**: Code blocks are excluded from translation in 100% of cases to prevent syntax corruption.

## Assumptions

- **Assumption 1**: 'jykyii' is confirmed as the **Jekyll** platform where the site logic resides. Translation will be handled externally via an API.
- **Assumption 2**: Digital translation via **Google Translate API** is the primary method for enabling "English reading mode".
- **Assumption 3**: The user will provide or configure the necessary **Google Translate API Key** in the project settings or environment.
- **Assumption 4**: The theme (Chirpy) can be extended with a custom JavaScript-based translation injector that identifies article content selectors.
