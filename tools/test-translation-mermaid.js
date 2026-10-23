const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const vm = require('node:vm');

const translation = require(path.join(__dirname, '..', 'assets', 'js', 'translation.js'));

function run() {
  function themeFor(environment) {
    const context = { module: { exports: {} }, ...environment };
    const source = fs.readFileSync(path.join(__dirname, '..', 'assets', 'js', 'translation.js'), 'utf8');
    vm.runInNewContext(source, context);
    return context.module.exports.getMermaidTheme();
  }

  assert.equal(themeFor({ Theme: { resolvedTheme: 'dark' } }), 'dark');
  assert.equal(themeFor({ Theme: { resolvedTheme: 'light' } }), 'default');
  assert.equal(themeFor({
    Theme: { resolvedTheme: 'light' },
    document: { documentElement: { dataset: { bsTheme: 'dark' } } }
  }), 'default');
  assert.equal(themeFor({ document: { documentElement: { dataset: { bsTheme: 'dark' } } } }), 'dark');
  assert.equal(themeFor({ document: { documentElement: { dataset: { mode: 'dark' } } } }), 'dark');
  assert.equal(themeFor({
    document: { documentElement: { dataset: { bsTheme: 'light' } } },
    matchMedia: () => ({ matches: true })
  }), 'default');
  assert.equal(themeFor({ matchMedia: () => ({ matches: true }) }), 'dark');
  assert.equal(themeFor({ matchMedia: () => ({ matches: false }) }), 'default');
  assert.equal(themeFor({}), 'default');

  const bilingualPayload = {
    format: 'bilingual_html',
    translations: {
      'zh-CN': { title: '中文标题', description: '中文描述', content: '<p>中文</p>' },
      en: { title: 'English title', description: 'English description', content: '<p>English</p>' }
    }
  };

  assert.deepEqual(
    translation.getLanguagePayload(bilingualPayload, 'en', { targetLang: 'en' }),
    bilingualPayload.translations.en
  );

  assert.deepEqual(
    translation.getLanguagePayload(bilingualPayload, 'zh-CN', { targetLang: 'en' }),
    bilingualPayload.translations['zh-CN']
  );

  assert.equal(
    translation.normalizeTranslatedMarkdown('```mermaid\ngraph TD\nA-->B\n```*Image: caption'),
    '```mermaid\ngraph TD\nA-->B\n```\n*Image: caption'
  );

  assert.equal(
    translation.normalizeTranslatedMarkdown('```bash\necho ok\n```\n\nnext'),
    '```bash\necho ok\n```\n\nnext'
  );

  assert.equal(
    translation.sanitizeMermaidSource('mermaid\ngraph TD\nA-->B\n'),
    'graph TD\nA-->B'
  );

  assert.equal(
    translation.sanitizeMermaidSource('\r\nmermaid\r\ngraph LR\r\nA-->B\r\n'),
    'graph LR\nA-->B'
  );

  assert.equal(
    translation.sanitizeMermaidSource('\uFEFFmermaid\nflowchart TB\nA-->B\n'),
    'flowchart TB\nA-->B'
  );

  assert.equal(
    translation.sanitizeMermaidSource('graph TD\nA-->B\n'),
    'graph TD\nA-->B'
  );

  console.log('translation Mermaid source and theme tests passed');
}

run();
