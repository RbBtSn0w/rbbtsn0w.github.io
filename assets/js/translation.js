/**
 * Article language toggle logic.
 * Switches the post body between build-time bilingual HTML fragments.
 */

(function(global) {
  const LANGUAGE_LABELS = {
    bash: 'Shell',
    shell: 'Shell',
    sh: 'Shell',
    zsh: 'Shell',
    console: 'Console',
    plaintext: 'Text',
    text: 'Text',
    objc: 'Objective-C',
    'objective-c': 'Objective-C',
    js: 'JavaScript',
    ts: 'TypeScript',
    yml: 'YAML',
    md: 'Markdown'
  };

  function sanitizeMermaidSource(rawText) {
    return String(rawText || '')
      .replace(/^\uFEFF/, '')
      .replace(/\r\n/g, '\n')
      .trim()
      .replace(/^mermaid\n+/i, '')
      .trim();
  }

  function scheduleMermaidRender(callback) {
    if (typeof global.requestAnimationFrame === 'function') {
      global.requestAnimationFrame(function() {
        global.requestAnimationFrame(callback);
      });
      return;
    }

    global.setTimeout(callback, 50);
  }

  function normalizeTranslatedMarkdown(markdown) {
    const source = String(markdown || '');
    const lines = source.split('\n');
    const output = [];
    let inFence = false;

    lines.forEach(function(line) {
      if (!inFence) {
        output.push(line);
        if (/^```/.test(line)) {
          inFence = true;
        }
        return;
      }

      const gluedFenceMatch = line.match(/^```(\S.*)$/);
      if (gluedFenceMatch) {
        output.push('```');
        output.push(gluedFenceMatch[1]);
        inFence = false;
        return;
      }

      output.push(line);
      if (/^```$/.test(line)) {
        inFence = false;
      }
    });

    return output.join('\n');
  }

  function normalizeLanguageCode(lang) {
    return String(lang || '').toLowerCase();
  }

  function getLanguagePayload(data, lang, config) {
    if (!data || !lang) return null;

    if (data.format === 'bilingual_html' && data.translations) {
      const target = normalizeLanguageCode(lang);
      const matchedKey = Object.keys(data.translations).find(function(key) {
        return normalizeLanguageCode(key) === target;
      });
      return matchedKey ? data.translations[matchedKey] : null;
    }

    if (config && normalizeLanguageCode(lang) === normalizeLanguageCode(config.targetLang || 'en')) {
      return {
        title: data.title,
        description: data.description,
        content: data.content,
        format: data.format || 'html'
      };
    }

    return null;
  }

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
      getLanguagePayload: getLanguagePayload,
      normalizeTranslatedMarkdown: normalizeTranslatedMarkdown,
      sanitizeMermaidSource: sanitizeMermaidSource,
      scheduleMermaidRender: scheduleMermaidRender
    };
  }

  const CONFIG = global.translationConfig;
  if (!global.document || !CONFIG || !CONFIG.slug) return;

  const selectors = {
    article: '.content, .post-content',
    meta: '.post-meta',
    title: 'h1',
    desc: '.post-desc',
    btn: '#article-translate-btn'
  };

  const originalContent = {
    title: '',
    desc: '',
    content: ''
  };

  let translatedData = null;
  let currentLang = CONFIG.sourceLang || 'zh-CN';
  let isLoading = false;

  function inferCodeLanguage(highlightEl) {
    if (!highlightEl) return '';
    const wrapper = highlightEl.closest('[class*="language-"]');
    if (!wrapper || !wrapper.className) return '';
    const match = wrapper.className.match(/language-([A-Za-z0-9_+.-]+)/);
    return match ? match[1].toLowerCase() : '';
  }

  function codeLabelText(highlightEl) {
    const fileWrapper = highlightEl && highlightEl.closest('[file]');
    const fileName = fileWrapper && fileWrapper.getAttribute('file');
    if (fileName) return fileName;

    const language = inferCodeLanguage(highlightEl);
    if (!language) return 'Code';

    return LANGUAGE_LABELS[language] || language.split(/[-_+]/).map(function(part) {
      return part ? part.charAt(0).toUpperCase() + part.slice(1) : '';
    }).join(' ');
  }

  function copySourceForButton(button) {
    const highlight = button && button.parentElement && button.parentElement.nextElementSibling;
    if (!highlight) return '';

    const rougeCode = highlight.querySelector('code .rouge-code');
    if (rougeCode) return rougeCode.textContent;

    const code = highlight.querySelector('code');
    return code ? code.textContent : '';
  }

  function bindCopyButton(button) {
    if (!button || button.dataset.copyBound === 'true') return;
    button.dataset.copyBound = 'true';

    button.addEventListener('click', async function() {
      const text = copySourceForButton(button);
      if (!text) return;

      try {
        await navigator.clipboard.writeText(text);
        const icon = button.querySelector('i');
        if (!icon) return;
        icon.className = 'fas fa-check';
        global.setTimeout(function() {
          icon.className = 'far fa-clipboard';
        }, 2000);
      } catch (error) {
        console.warn('Copy code failed:', error);
      }
    });
  }

  function ensureCodeHeaders(container) {
    container.querySelectorAll('div.highlight').forEach(function(highlight) {
      const existingHeader = highlight.previousElementSibling;
      if (existingHeader && existingHeader.classList.contains('code-header')) {
        bindCopyButton(existingHeader.querySelector('button'));
        return;
      }

      if (!highlight.querySelector('code')) return;

      const header = document.createElement('div');
      header.className = 'code-header';

      const label = document.createElement('span');
      label.setAttribute('data-label-text', codeLabelText(highlight));
      const labelIcon = document.createElement('i');
      labelIcon.className = highlight.closest('[file]') ? 'far fa-file-code fa-fw' : 'fas fa-code fa-fw small';
      label.appendChild(labelIcon);

      const button = document.createElement('button');
      button.setAttribute('aria-label', 'copy');
      button.setAttribute('data-title-succeed', 'Copied!');
      const buttonIcon = document.createElement('i');
      buttonIcon.className = 'far fa-clipboard';
      button.appendChild(buttonIcon);

      header.appendChild(label);
      header.appendChild(button);
      highlight.parentNode.insertBefore(header, highlight);
      bindCopyButton(button);
    });
  }

  function ensureHeadingAnchors(container) {
    container.querySelectorAll('h2[id], h3[id], h4[id], h5[id]').forEach(function(heading) {
      if (heading.querySelector('a.anchor')) return;

      const wrapper = document.createElement('span');
      wrapper.className = 'me-2';
      while (heading.firstChild) {
        wrapper.appendChild(heading.firstChild);
      }

      const anchor = document.createElement('a');
      anchor.href = `#${heading.id}`;
      anchor.className = 'anchor text-muted';
      const icon = document.createElement('i');
      icon.className = 'fas fa-hashtag';
      anchor.appendChild(icon);

      heading.appendChild(wrapper);
      heading.appendChild(anchor);
    });
  }

  function refreshToc() {
    if (!global.tocbot || typeof global.tocbot.refresh !== 'function') return;

    try {
      global.tocbot.refresh();
    } catch (error) {
      console.warn('TOC refresh failed:', error);
    }
  }

  async function loadTranslation() {
    if (translatedData) return translatedData;

    const base = CONFIG.baseurl || '';
    const url = `${base}/assets/translations/${CONFIG.slug}.json`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error('Translation data not found.');
    }

    translatedData = await response.json();
    return translatedData;
  }

  function renderPayload(payload, fallback) {
    const titleEl = document.querySelector(selectors.title);
    const descEl = document.querySelector(selectors.desc);
    const contentEl = document.querySelector(selectors.article);

    if (!payload) {
      if (titleEl) titleEl.innerHTML = fallback.title;
      if (descEl) descEl.innerHTML = fallback.desc;
      if (contentEl) contentEl.innerHTML = fallback.content;
      return;
    }

    if (titleEl) titleEl.innerHTML = payload.title || '';
    if (descEl) descEl.innerHTML = payload.description || '';

    if (!contentEl) return;

    if (payload.format === 'html' || translatedData.format === 'bilingual_html') {
      contentEl.innerHTML = payload.content || '';
    } else {
      const normalizedMarkdown = normalizeTranslatedMarkdown(payload.content);
      if (global.marked) {
        contentEl.innerHTML = global.marked.parse(normalizedMarkdown);
      } else {
        contentEl.innerHTML = basicMarkdownToHtml(normalizedMarkdown);
      }
    }

    postRenderEnhance(contentEl);
  }

  async function applyTranslation() {
    if (isLoading) return;

    try {
      isLoading = true;
      toggleLoadingUI(true);

      const data = await loadTranslation();
      const targetPayload = getLanguagePayload(data, CONFIG.targetLang || 'en', CONFIG);

      if (!originalContent.title) {
        originalContent.title = document.querySelector(selectors.title)?.innerHTML || '';
        originalContent.desc = document.querySelector(selectors.desc)?.innerHTML || '';
        originalContent.content = document.querySelector(selectors.article)?.innerHTML || '';
      }

      if (!targetPayload) {
        throw new Error('Target language payload not found.');
      }

      renderPayload(targetPayload, originalContent);
      currentLang = CONFIG.targetLang || 'en';
      updateUI();
      savePreference(currentLang);
    } catch (err) {
      console.error('Translation error:', err.message);
      alert('English version is currently unavailable for this post.');
    } finally {
      isLoading = false;
      toggleLoadingUI(false);
    }
  }

  function revertToOriginal() {
    if (!originalContent.title) return;

    const sourcePayload = getLanguagePayload(translatedData, CONFIG.sourceLang || 'zh-CN', CONFIG);
    renderPayload(sourcePayload, originalContent);

    currentLang = CONFIG.sourceLang || 'zh-CN';
    updateUI();
    savePreference(currentLang);
  }

  function toggleLoadingUI(show) {
    const btn = document.querySelector(selectors.btn);
    const article = document.querySelector(selectors.article);

    if (btn) {
      btn.disabled = show;
      btn.innerHTML = show ? '<i class="fas fa-spinner fa-spin"></i><span>...</span>' : getBtnContent();
    }

    if (article) {
      article.classList.toggle('translation-loading', show);
    }
  }

  function getBtnContent() {
    return currentLang === 'en'
      ? '<i class="fas fa-undo"></i><span class="btn-text">中文</span>'
      : '<i class="fas fa-language"></i><span class="btn-text">English</span>';
  }

  function updateUI() {
    const btn = document.querySelector(selectors.btn);
    if (!btn) return;

    btn.innerHTML = getBtnContent();
    btn.classList.toggle('active', currentLang === 'en');

    const attr = btn.parentElement.querySelector('.translation-attribution');
    if (attr) {
      attr.style.display = currentLang === 'en' ? 'block' : 'none';
    }
  }

  function injectToggle() {
    if (document.querySelector(selectors.btn)) return;

    const meta = document.querySelector(selectors.meta)
      || document.querySelector(selectors.desc)
      || document.querySelector(selectors.title);
    if (!meta) return;

    const btnHtml = `
      <div class="translation-toggle-wrapper mt-3 mb-2">
        <div class="d-flex flex-column align-items-start">
          <button class="translation-toggle" id="article-translate-btn" title="Translate Toggle">
            <i class="fas fa-language"></i>
            <span class="btn-text">English</span>
          </button>
          <div class="translation-attribution mt-1" style="display: none; font-size: 0.65rem; color: var(--text-muted); opacity: 0.8;">
            Powered by Google Translate
          </div>
        </div>
      </div>
    `;

    meta.insertAdjacentHTML('afterend', btnHtml);
    document.querySelector(selectors.btn).addEventListener('click', function() {
      if (currentLang === 'en') {
        revertToOriginal();
      } else {
        applyTranslation();
      }
    });
  }

  function savePreference(lang) {
    localStorage.setItem('user-language', lang);
  }

  function loadPreference() {
    return localStorage.getItem('user-language');
  }

  function init() {
    if (!document.querySelector(selectors.article)) return;

    injectToggle();
    if (loadPreference() === 'en') {
      applyTranslation();
    }
  }

  function postRenderEnhance(container) {
    if (!container) return;

    ensureCodeHeaders(container);
    ensureHeadingAnchors(container);

    const mermaidBlocks = Array.from(container.querySelectorAll('code.language-mermaid'));
    mermaidBlocks.forEach(function(codeEl) {
      const pre = codeEl.parentElement;
      if (!pre) return;

      const rawText = sanitizeMermaidSource(codeEl.textContent);
      pre.classList.add('d-none');

      const existingDiagram = pre.nextElementSibling;
      if (existingDiagram && existingDiagram.classList.contains('mermaid')) {
        existingDiagram.textContent = rawText;
        existingDiagram.removeAttribute('data-processed');
        existingDiagram.removeAttribute('aria-roledescription');
        existingDiagram.removeAttribute('role');
        existingDiagram.removeAttribute('id');
        return;
      }

      const mermaidPre = document.createElement('pre');
      mermaidPre.className = 'mermaid';
      mermaidPre.textContent = rawText;
      pre.insertAdjacentElement('afterend', mermaidPre);
    });

    if (mermaidBlocks.length > 0 && global.mermaid) {
      scheduleMermaidRender(function() {
        try {
          const mermaidTheme = document.documentElement.classList.contains('dark') ? 'dark' : 'default';
          global.mermaid.initialize({
            startOnLoad: false,
            theme: mermaidTheme
          });
          global.mermaid.init(undefined, container.querySelectorAll('.mermaid'));
        } catch (error) {
          console.warn('Mermaid re-render failed:', error);
        }
      });
    }

    if (global.Prism) {
      global.Prism.highlightAllUnder(container);
    } else if (global.hljs) {
      container.querySelectorAll('pre code').forEach(function(block) {
        global.hljs.highlightElement(block);
      });
    }

    refreshToc();
  }

  function basicMarkdownToHtml(md) {
    var html = md
      .replace(/```(\w*)\n([\s\S]*?)```/g, function(_, lang, code) {
        var cls = lang ? ' class="language-' + lang + '"' : '';
        return '<pre><code' + cls + '>' + escapeHtml(code) + '</code></pre>';
      })
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/^#### (.+)$/gm, '<h4>$1</h4>')
      .replace(/^### (.+)$/gm, '<h3>$1</h3>')
      .replace(/^## (.+)$/gm, '<h2>$1</h2>')
      .replace(/^# (.+)$/gm, '<h1>$1</h1>')
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>')
      .replace(/^- (.+)$/gm, '<li>$1</li>')
      .replace(/\n\n/g, '</p><p>')
      .replace(/\n/g, '<br>');

    return '<p>' + html + '</p>';
  }

  function escapeHtml(str) {
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})(typeof globalThis !== 'undefined' ? globalThis : window);
