const assert = require('node:assert/strict');
const path = require('node:path');

const translation = require(path.join(__dirname, '..', 'assets', 'js', 'translation.js'));

function run() {
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

  console.log('translation mermaid sanitation tests passed');
}

run();
