/**
 * Build-time Translation Tool (Robust Version)
 * Purpose: Translate Markdown posts into JSON deltas using Google Apps Script with Batching & Rate Limiting.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Configuration
const postsDir = path.join(__dirname, '..', '_posts');
const outputDir = path.join(__dirname, '..', 'assets', 'translations');
const GAS_URL = process.env.GOOGLE_APPS_SCRIPT_URL;

const CHUNK_SIZE = 10; // Max segments per GAS request
const SLEEP_BETWEEN_CHUNKS = 1500; // 1.5s
const SLEEP_BETWEEN_POSTS = 2000; // 2s
const MAX_POSTS_PER_RUN = 15; // To prevent hitting daily quotas in one go

if (!GAS_URL) {
  console.warn('Warning: GOOGLE_APPS_SCRIPT_URL not found. Skipping translation.');
  process.exit(0);
}

if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

function getHash(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

/**
 * Robust Translation Request (with Internal Chunking)
 */
async function translateInChunks(textArray, target) {
  const allResults = [];
  
  for (let i = 0; i < textArray.length; i += CHUNK_SIZE) {
    const chunk = textArray.slice(i, i + CHUNK_SIZE);
    console.log(`  - Sub-batch ${Math.floor(i/CHUNK_SIZE) + 1}/${Math.ceil(textArray.length/CHUNK_SIZE)}...`);
    
    let retries = 2;
    let success = false;
    
    while (retries >= 0 && !success) {
      try {
        const response = await fetch(GAS_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ q: chunk, target: target })
        });
        
        const data = await response.json();
        if (data.error) throw new Error(data.error);
        
        allResults.push(...data.data.translations.map(t => t.translatedText));
        success = true;
      } catch (err) {
        console.warn(`    ! Attempt failed: ${err.message}. Retries left: ${retries}`);
        retries--;
        if (retries >= 0) await sleep(3000); // Wait longer on error
      }
    }
    
    if (!success) {
      throw new Error(`Critical failure translating chunk starting at index ${i}`);
    }
    
    if (i + CHUNK_SIZE < textArray.length) {
      await sleep(SLEEP_BETWEEN_CHUNKS);
    }
  }
  
  return allResults;
}

function getTranslatableBlocks(markdown) {
  const blocks = [];
  const parts = markdown.split(/(```[\s\S]*?```|\{% mermaid %\}[\s\S]*?\{% endmermaid %\})/g);
  parts.forEach(part => {
    if (part.startsWith('```') || part.startsWith('{% mermaid %}')) blocks.push({ type: 'code', content: part });
    else blocks.push({ type: 'text', content: part });
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

  if (fs.existsSync(outPath)) {
    const existing = JSON.parse(fs.readFileSync(outPath, 'utf8'));
    if (existing.hash === currentHash) return false; // Already done
  }

  console.log(`🌐 [Processing] ${filename}`);
  const parsed = parsePost(rawContent);
  const blocks = getTranslatableBlocks(parsed.body);
  const textBlocks = blocks.filter(b => b.type === 'text' && b.content.trim().length > 0);
  
  const toTranslate = [parsed.title, parsed.desc, ...textBlocks.map(b => b.content)];
  
  try {
    const translated = await translateInChunks(toTranslate, 'en');
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
    console.log(`✓ [Done] ${filename}`);
    return true;
  } catch (err) {
    console.error(`✗ [Fail] ${filename}: ${err.message}`);
    return false;
  }
}

async function main() {
  const files = fs.readdirSync(postsDir).filter(f => f.endsWith('.md'));
  let processedCount = 0;
  
  console.log(`Starting translation pipeline. Active files: ${files.length}, Max this run: ${MAX_POSTS_PER_RUN}`);

  for (const file of files) {
    if (processedCount >= MAX_POSTS_PER_RUN) {
      console.log(`Reached limit of ${MAX_POSTS_PER_RUN} posts. Stopping for this run.`);
      break;
    }
    
    const wasProcessed = await processFile(file);
    if (wasProcessed) {
      processedCount++;
      await sleep(SLEEP_BETWEEN_POSTS);
    }
  }
  
  console.log(`Pipeline finished. Processed: ${processedCount} posts.`);
}

main().catch(console.error);
