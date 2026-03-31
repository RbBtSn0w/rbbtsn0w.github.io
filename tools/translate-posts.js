/**
 * Build-time Translation Tool (Priority-Drip Version)
 * Purpose: Always prioritize NEW/MODIFIED posts, then drip-feed history.
 * Ensures fresh content is live while backfilling archive without hitting quotas.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Configuration
const postsDir = path.join(__dirname, '..', '_posts');
const outputDir = path.join(__dirname, '..', 'assets', 'translations');
const GAS_URL = process.env.GOOGLE_APPS_SCRIPT_URL; // Hidden endpoint
const GAS_TOKEN = process.env.GOOGLE_APPS_SCRIPT_TOKEN;

const SLEEP_BETWEEN_POSTS = 3000;
const HISTORY_DRIP_LIMIT = 8;    // Number of OLD posts to backfill per run
const NEW_PRIORITY_LIMIT = 15;   // Max NEW/MODIFIED posts per run (guardrail)

if (!GAS_URL) {
  process.exit(0);
}

if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

function getHash(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function translateAtomic(textArray, target) {
  try {
    const response = await fetch(GAS_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ q: textArray, target: target, token: GAS_TOKEN })
    });
    const data = await response.json();
    if (data.error) throw new Error(data.error);
    return data.data.translations.map(t => t.translatedText);
  } catch (err) {
    throw err;
  }
}

/**
 * Identified translatable blocks in Markdown (Skip code / Mermaid / inline code / Liquid)
 */
function getTranslatableBlocks(markdown) {
  const blocks = [];
  // Split by fenced code blocks, mermaid tags, inline code spans, and Liquid tags
  const parts = markdown.split(
    /(```[\s\S]*?```|\{\% mermaid \%\}[\s\S]*?\{\% endmermaid \%\}|`[^`\n]+`|\{\%[\s\S]*?\%\}|\{\{[\s\S]*?\}\})/g
  );

  parts.forEach(part => {
    if (!part) {
      return; // skip empty segments
    }

    const isFencedCode = /^```[\s\S]*?```$/.test(part);
    const isMermaidBlock = /^\{\% mermaid \%\}[\s\S]*?\{\% endmermaid \%\}$/.test(part);
    const isInlineCode = /^`[^`\n]+`$/.test(part);
    const isLiquidTag = /^\{\%[\s\S]*?\%\}$/.test(part) || /^\{\{[\s\S]*?\}\}$/.test(part);

    if (isFencedCode || isMermaidBlock || isInlineCode || isLiquidTag) {
      blocks.push({ type: 'code', content: part });
    } else {
      blocks.push({ type: 'text', content: part });
    }
  });
  return blocks;
}

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

  console.log(`🌐 [Translating] ${filename}`);
  const parsed = parsePost(rawContent);
  const blocks = getTranslatableBlocks(parsed.body);
  const textBlocks = blocks.filter(b => b.type === 'text' && b.content.trim().length > 0);
  const toTranslate = [parsed.title, parsed.desc, ...textBlocks.map(b => b.content)];

  try {
    const translated = await translateAtomic(toTranslate, 'en');
    let transIndex = 2;
    const resultBody = blocks.map(b => {
      if (b.type === 'text' && b.content.trim().length > 0) return translated[transIndex++];
      return b.content;
    }).join('');

    const result = {
      title: translated[0],
      description: translated[1],
      content: resultBody,
      hash: currentHash,
      timestamp: new Date().toISOString()
    };
    fs.writeFileSync(outPath, JSON.stringify(result, null, 2));
    return true;
  } catch (err) {
    console.error(`✗ [Fail] ${filename}: ${err.message}`);
    return false;
  }
}

async function main() {
  const files = fs.readdirSync(postsDir).filter(f => f.endsWith('.md'));

  const modifiedQueue = [];
  const untranslatedQueue = [];

  for (const file of files) {
    const filePath = path.join(postsDir, file);
    const slug = file.replace(/^\d{4}-\d{2}-\d{2}-/, '').replace(/\.md$/, '');
    const outPath = path.join(outputDir, `${slug}.json`);
    const rawContent = fs.readFileSync(filePath, 'utf8');
    const currentHash = getHash(rawContent);

    if (!fs.existsSync(outPath)) {
      untranslatedQueue.push(file);
    } else {
      const existing = JSON.parse(fs.readFileSync(outPath, 'utf8'));
      if (existing.hash !== currentHash) {
        modifiedQueue.push(file);
      }
    }
  }

  console.log(`Found: ${modifiedQueue.length} modified, ${untranslatedQueue.length} untranslated history.`);

  let totalProcessed = 0;

  // Level 1: Modified/New Posts (Limit 15 per run as safety)
  for (const file of modifiedQueue.slice(0, NEW_PRIORITY_LIMIT)) {
    if (await processFile(file)) {
      totalProcessed++;
      await sleep(SLEEP_BETWEEN_POSTS);
    }
  }

  // Level 2: Random Drip History (Only if we have budget left)
  if (totalProcessed < NEW_PRIORITY_LIMIT) {
    const budgetLeft = Math.min(HISTORY_DRIP_LIMIT, NEW_PRIORITY_LIMIT - totalProcessed);
    console.log(`Backfilling history (Budget: ${budgetLeft})...`);
    for (const file of untranslatedQueue.slice(0, budgetLeft)) {
      if (await processFile(file)) {
        totalProcessed++;
        await sleep(SLEEP_BETWEEN_POSTS);
      }
    }
  }

  console.log(`Total translated this run: ${totalProcessed}`);
}

main().catch(console.error);
