#!/usr/bin/env node
/**
 * ASPAR Franchise — Slides to PDF Generator
 * Assemble des images PNG en PDF multi-pages via Puppeteer
 *
 * Usage:
 *   node aspar-slides-to-pdf.js --input /path/to/slides/ --output /path/to/output/ --formats linkedin,instagram,stories,pinterest
 *   node aspar-slides-to-pdf.js --input ./slides/ --output ./output/ --subject "franchise-2024" --formats all
 */

const path = require('path');
const fs = require('fs');
const { parseArgs } = require('util');

// ─── Configuration des formats ────────────────────────────────────────────────

const FORMATS = {
  linkedin:  { width: 1080, height: 1350, label: 'LinkedIn Portrait 4:5' },
  instagram: { width: 1080, height: 1080, label: 'Instagram Carré 1:1' },
  stories:   { width: 1080, height: 1920, label: 'Stories/TikTok 9:16' },
  pinterest: { width: 1000, height: 1500, label: 'Pinterest Portrait 2:3' },
};

const SLIDE_ORDER = [
  { file: 'slide-01-cover',    label: 'Cover Majdi/Business' },
  { file: 'slide-02-probleme', label: 'Problème/Hook' },
  { file: 'slide-03-solution', label: 'Solution ASPAR' },
  { file: 'slide-04-preuve',   label: 'Preuve Sociale' },
  { file: 'slide-05-cta',      label: 'CTA/Action' },
];

// ─── Utilitaires ──────────────────────────────────────────────────────────────

function log(level, message) {
  const timestamp = new Date().toISOString();
  const prefix = { INFO: 'ℹ', SUCCESS: '✅', ERROR: '❌', WARN: '⚠️' }[level] || '•';
  console.log(`${timestamp} ${prefix} [${level}] ${message}`);
}

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

function findSlideImages(inputDir, format) {
  const formatDir = path.join(inputDir, format);

  if (!fs.existsSync(formatDir)) {
    log('WARN', `Dossier format introuvable : ${formatDir}`);
    return [];
  }

  const images = [];
  for (const slide of SLIDE_ORDER) {
    const extensions = ['png', 'jpg', 'jpeg', 'webp'];
    let found = false;

    for (const ext of extensions) {
      const filePath = path.join(formatDir, `${slide.file}.${ext}`);
      if (fs.existsSync(filePath)) {
        images.push({ path: filePath, label: slide.label });
        found = true;
        break;
      }
    }

    if (!found) {
      log('WARN', `Slide introuvable : ${slide.file} dans ${formatDir}`);
    }
  }

  return images;
}

// ─── Génération PDF via Puppeteer ─────────────────────────────────────────────

async function generatePDF(images, outputPath, formatConfig) {
  let puppeteer;
  try {
    puppeteer = require('puppeteer');
  } catch {
    log('ERROR', 'Puppeteer non installé. Lancez : npm install puppeteer');
    throw new Error('puppeteer_not_found');
  }

  const { width, height } = formatConfig;

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width, height, deviceScaleFactor: 1 });

    const pdfBuffers = [];

    for (const image of images) {
      const imgBuffer = fs.readFileSync(image.path);
      const base64 = imgBuffer.toString('base64');
      const ext = path.extname(image.path).slice(1).toLowerCase();
      const mimeType = ext === 'jpg' ? 'image/jpeg' : `image/${ext}`;

      const html = `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    width: ${width}px;
    height: ${height}px;
    background: #1B2A4A;
    overflow: hidden;
  }
  img {
    width: ${width}px;
    height: ${height}px;
    object-fit: cover;
    display: block;
  }
</style>
</head>
<body>
  <img src="data:${mimeType};base64,${base64}" alt="${image.label}" />
</body>
</html>`;

      await page.setContent(html, { waitUntil: 'networkidle0' });

      const pdfBuffer = await page.pdf({
        width: `${width}px`,
        height: `${height}px`,
        printBackground: true,
        margin: { top: 0, right: 0, bottom: 0, left: 0 },
      });

      pdfBuffers.push(pdfBuffer);
      log('INFO', `  Slide "${image.label}" converti`);
    }

    // Fusionner les PDFs avec pdf-lib
    let PDFDocument;
    try {
      ({ PDFDocument } = require('pdf-lib'));
    } catch {
      log('WARN', 'pdf-lib non installé — sauvegarde du premier PDF uniquement');
      fs.writeFileSync(outputPath, pdfBuffers[0]);
      return outputPath;
    }

    const mergedPdf = await PDFDocument.create();

    for (const pdfBuffer of pdfBuffers) {
      const pdf = await PDFDocument.load(pdfBuffer);
      const pages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
      pages.forEach(p => mergedPdf.addPage(p));
    }

    const mergedBytes = await mergedPdf.save();
    fs.writeFileSync(outputPath, mergedBytes);

    return outputPath;

  } finally {
    await browser.close();
  }
}

// ─── Point d'entrée principal ─────────────────────────────────────────────────

async function main() {
  // Parse arguments
  let args;
  try {
    args = parseArgs({
      options: {
        input:   { type: 'string', short: 'i' },
        output:  { type: 'string', short: 'o' },
        formats: { type: 'string', short: 'f', default: 'all' },
        subject: { type: 'string', short: 's', default: 'aspar' },
        help:    { type: 'boolean', short: 'h' },
      },
      strict: false,
    });
  } catch (err) {
    console.error('Erreur de parsing :', err.message);
    process.exit(1);
  }

  if (args.values.help) {
    console.log(`
Usage: node aspar-slides-to-pdf.js [OPTIONS]

Options:
  --input, -i    Dossier contenant les slides (requis)
  --output, -o   Dossier de sortie des PDFs (requis)
  --formats, -f  Formats à générer : linkedin,instagram,stories,pinterest ou all (défaut: all)
  --subject, -s  Nom du sujet pour nommer les fichiers (défaut: aspar)
  --help, -h     Affiche cette aide
    `);
    process.exit(0);
  }

  const inputDir = args.values.input;
  const outputDir = args.values.output;
  const subject = args.values.subject;

  if (!inputDir || !outputDir) {
    log('ERROR', '--input et --output sont requis');
    process.exit(1);
  }

  // Déterminer les formats à générer
  const formatsArg = args.values.formats;
  const targetFormats = formatsArg === 'all'
    ? Object.keys(FORMATS)
    : formatsArg.split(',').map(f => f.trim()).filter(f => FORMATS[f]);

  if (targetFormats.length === 0) {
    log('ERROR', `Formats invalides : ${formatsArg}. Formats valides : ${Object.keys(FORMATS).join(', ')}`);
    process.exit(1);
  }

  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const outputSubDir = path.join(outputDir, `${dateStr}-${subject}`);

  log('INFO', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  log('INFO', 'ASPAR Franchise — Slides to PDF Generator');
  log('INFO', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  log('INFO', `Input  : ${inputDir}`);
  log('INFO', `Output : ${outputSubDir}`);
  log('INFO', `Formats: ${targetFormats.join(', ')}`);
  log('INFO', `Sujet  : ${subject}`);

  const results = [];

  for (const formatName of targetFormats) {
    const formatConfig = FORMATS[formatName];
    log('INFO', `\n📐 Format : ${formatConfig.label} (${formatConfig.width}×${formatConfig.height})`);

    const formatOutputDir = path.join(outputSubDir, formatName);
    ensureDir(formatOutputDir);

    const images = findSlideImages(inputDir, formatName);

    if (images.length === 0) {
      log('WARN', `Aucune image trouvée pour le format ${formatName} — ignoré`);
      continue;
    }

    log('INFO', `  ${images.length} slides trouvés`);

    const pdfFilename = `aspar-${dateStr}-${subject}-${formatName}.pdf`;
    const pdfPath = path.join(formatOutputDir, pdfFilename);

    try {
      await generatePDF(images, pdfPath, formatConfig);
      const stats = fs.statSync(pdfPath);
      const sizeKB = Math.round(stats.size / 1024);
      log('SUCCESS', `  PDF généré : ${pdfFilename} (${sizeKB} KB)`);
      results.push({ format: formatName, pdf: pdfPath, size: stats.size, slides: images.length });
    } catch (err) {
      log('ERROR', `  Échec génération PDF ${formatName} : ${err.message}`);
    }
  }

  // Résumé
  console.log('\n');
  log('INFO', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  log('SUCCESS', `Pipeline PDF terminé — ${results.length}/${targetFormats.length} formats générés`);
  for (const r of results) {
    log('SUCCESS', `  ${FORMATS[r.format].label}: ${r.slides} slides → PDF (${Math.round(r.size / 1024)} KB)`);
  }
  log('INFO', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // Exit avec code d'erreur si aucun PDF généré
  if (results.length === 0) {
    process.exit(1);
  }
}

main().catch(err => {
  log('ERROR', `Erreur fatale : ${err.message}`);
  process.exit(1);
});
