/**
 * Article Language Toggle Logic (Build-time Cache Version)
 * Fetches pre-translated JSON delta from /assets/translations/[slug].json
 */

(function() {
  const CONFIG = window.translationConfig;
  if (!CONFIG || !CONFIG.slug) return;

  const selectors = {
    article: '.content, .post-content, article',
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

  /**
   * T008 (Revised): Fetch Local Translation JSON
   */
  async function loadTranslation() {
    if (translatedData) return translatedData;
    
    // Construct the path, considering baseurl (PR-20 Fix)
    const base = CONFIG.baseurl || '';
    const url = `${base}/assets/translations/${CONFIG.slug}.json`;
    
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error('Translation data not found.');
    }
    translatedData = await response.json();
    return translatedData;
  }

  /**
   * Switch to English
   */
  async function applyTranslation() {
    if (isLoading) return;
    
    try {
      isLoading = true;
      toggleLoadingUI(true);

      const data = await loadTranslation();

      // Store original on first run
      if (!originalContent.title) {
        originalContent.title = document.querySelector(selectors.title)?.innerHTML || '';
        originalContent.desc = document.querySelector(selectors.desc)?.innerHTML || '';
        originalContent.content = document.querySelector(selectors.article)?.innerHTML || '';
      }

      // Apply
      const titleEl = document.querySelector(selectors.title);
      const descEl = document.querySelector(selectors.desc);
      const contentEl = document.querySelector(selectors.article);

      if (titleEl) titleEl.innerHTML = data.title;
      if (descEl) descEl.innerHTML = data.description;
      
      // Render Markdown to HTML if marked is available (PR-20 Fix)
      if (contentEl) {
        if (window.marked) {
          // Use marked for high-quality rendering
          contentEl.innerHTML = window.marked.parse(data.content);
        } else {
          // Fallback to raw injection
          contentEl.innerHTML = data.content;
        }
      }

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

  /**
   * Switch back to Chinese
   */
  function revertToOriginal() {
    if (!originalContent.title) return;

    const titleEl = document.querySelector(selectors.title);
    const descEl = document.querySelector(selectors.desc);
    const contentEl = document.querySelector(selectors.article);

    if (titleEl) titleEl.innerHTML = originalContent.title;
    if (descEl) descEl.innerHTML = originalContent.desc;
    if (contentEl) contentEl.innerHTML = originalContent.content;

    currentLang = CONFIG.sourceLang || 'zh-CN';
    updateUI();
    savePreference(currentLang);
  }

  /**
   * UI Helpers
   */
  function toggleLoadingUI(show) {
    const btn = document.querySelector(selectors.btn);
    const article = document.querySelector(selectors.article);
    
    if (btn) {
      btn.disabled = show;
      btn.innerHTML = show ? '<i class="fas fa-spinner fa-spin"></i><span>...</span>' : getBtnContent();
    }
    
    if (article) {
      article.classList.toggle('translation-loading', show); // PR-20 Fix
    }
  }

  function getBtnContent() {
    return currentLang === 'en' 
      ? '<i class="fas fa-undo"></i><span class="btn-text">中文</span>' 
      : '<i class="fas fa-language"></i><span class="btn-text">English</span>';
  }

  function updateUI() {
    const btn = document.querySelector(selectors.btn);
    if (btn) {
      btn.innerHTML = getBtnContent();
      btn.classList.toggle('active', currentLang === 'en');
      const attr = btn.parentElement.querySelector('.translation-attribution');
      if (attr) attr.style.display = (currentLang === 'en') ? 'block' : 'none';
    }
  }

  function injectToggle() {
    // Try multiple possible locations for injection (PR-20 Resiliency)
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

    document.querySelector(selectors.btn).addEventListener('click', () => {
      if (currentLang === 'en') revertToOriginal();
      else applyTranslation();
    });
  }

  function savePreference(lang) {
    localStorage.setItem('user-language', lang); // PR-20 Fix (Key Name)
  }

  function loadPreference() {
    return localStorage.getItem('user-language'); // PR-20 Fix (Key Name)
  }

  function init() {
    if (document.querySelector(selectors.article)) {
      injectToggle();
      if (loadPreference() === 'en') applyTranslation();
    }
  }

  // Init
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
