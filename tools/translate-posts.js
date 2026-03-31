/**
 * Build-time Translation Tool (GAS Proxy Version)
 * Purpose: Translate Markdown posts into JSON deltas using Google Apps Script.
 * Features: SHA-256 Fingerprint checking, Skip identical content, GAS fallback.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Configuration
const postsDir = path.join(__dirname, '..', '_posts');
const outputDir = path.join(__dirname, '..', 'assets', 'translations');
const GAS_URL = process.env.GOOGLE_APPS_SCRIPT_URL; // Hiden endpoint
const TARGET_LANG = 'en';

if (!GAS_URL) {
  console.warn('Warning: GOOGLE_APPS_SCRIPT_URL not found. Skipping translation phase.');
  process.exit(0);
}

if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

/**
 * SHA-256 Content Fingerprint
 */
function getHash(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

/**
 * GAS API Wrapper with Retry logic (T024 update)
 */
async function fetchTranslation(textArray, target, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(GAS_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          q: textArray,
          target: target
        })
      });
      
      const data = await response.json();
      if (data.error) throw new Error(data.error);
      return data.data.translations.map(t => t.translatedText);
    } catch (err) {
      console.warn(`Retry ${i+1}/${retries} failed for translation: ${err.message}`);
      if (i === retries - 1) throw err;
      await new Promise(r => setTimeout(r, 2000)); // Wait 2s
    }
  }
}

/**
 * Identified translatable blocks in Markdown (Skip code / Mermaid)
 */
function getTranslatableBlocks(markdown) {
  const blocks = [];
  // Split by code blocks and mermaid tags
  const parts = markdown.split(/(```[\s\S]*?```|\{% mermaid %\}[\s\S]*?\{% endmermaid %\})/g);
  
  parts.forEach(part => {
    if (part.startsWith('```') || part.startsWith('{% mermaid %}')) {
      blocks.push({ type: 'code', content: part });
    } else {
      blocks.push({ type: 'text', content: part });
    }
  });
  return blocks;
}

/**
 * Standard Markdown Parser
 */
function parsePost(content) {
  const fmMatch = content.match(/^---([\s\S]*?)---/);
  const frontMatter = fmMatch ? fmMatch[1] : '';
  const body = fmMatch ? content.slice(fmMatch[0].length) : content;
  
  const title = (frontMatter.match(/title:\s*(.*)/) || [])[1]?.replace(/['"]/g, '').trim() || '';
  const desc = (frontMatter.match(/description:\s*(.*)/) || [])[1]?.replace(/['"]/g, '').trim() || '';
  
  return { title, desc, body: body.trim() };
}

async function processFile(filename) {
  const filePath = path.join(postsDir, filename);
  const slug = filename.replace(/^\d{4}-\d{2}-\d{2}-/, '').replace(/\.md$/, '');
  const outPath = path.join(outputDir, `${slug}.json`);
  
  const rawContent = fs.readFileSync(filePath, 'utf8');
  const currentHash = getHash(rawContent);

  // Check if translation exists and matches hash
  if (fs.existsSync(outPath)) {
    const existing = JSON.parse(fs.readFileSync(outPath, 'utf8'));
    if (existing.hash === currentHash) {
      console.log(`✓ [Skip] ${filename} (Hash matches)`);
      return;
    }
  }

  console.log(`🌐 [Translating] ${filename}...`);
  const parsed = parsePost(rawContent);
  const blocks = getTranslatableBlocks(parsed.body);
  const textBlocks = blocks.filter(b => b.type === 'text' && b.content.trim().length > 0);
  
  const toTranslate = [parsed.title, parsed.desc, ...textBlocks.map(b => b.content)];
  
  try {
    const translated = await fetchTranslation(toTranslate, TARGET_LANG);
    
    let transIndex = 2; // Offset for title and desc
    const resultBody = blocks.map(b => {
      if (b.type === 'text' && b.content.trim().length > 0) {
        return translated[transIndex++];
      }
      return b.content;
    }).join('');

    const result = {
      title: translated[0],
      description: translated[1],
      content: resultBody,
      hash: currentHash, // Store hash for future comparisons
      timestamp: new Date().toISOString()
    };

    fs.writeFileSync(outPath, JSON.stringify(result, null, 2));
    console.log(`✓ [Success] Generated: ${outPath}`);
  } catch (err) {
    console.error(`✗ [Error] ${filename}: ${err.message}`);
  }
}

async function main() {
  const files = fs.readdirSync(postsDir).filter(f => f.endsWith('.md'));
  console.log(`Checking ${files.length} posts for translation update...`);
  for (const file of files) {
    await processFile(file);
  }
}

main().catch(console.error);
