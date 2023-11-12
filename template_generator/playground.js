const puppeteer = require('puppeteer');
const pdfjsLib = require('pdfjs-dist');
const pdfParse = require('pdf-parse');
const fs = require('fs');



async function htmlToPdf(htmlPath, pdfPath) {
    const browser = await puppeteer.launch({ headless: "new" }); // Update here
    const page = await browser.newPage();
    await page.goto(`file://${htmlPath}`, { waitUntil: 'networkidle2' });
    await page.pdf({ path: pdfPath, format: 'A4', printBackground: true});

    await browser.close();
}

doIt('vollmacht_v1');
doIt('protokoll_v1');

async function doIt(fileName) {
    const htmlPath = '/Users/mali/flutter_projects/macsignaturepad_project/template_generator/' + fileName + '.html';

    const jsonPath = './' + fileName + '_metadata.json';
    const pdfPath = './' + fileName + '.pdf';

    await htmlToPdf(htmlPath, pdfPath)
        .then(() => console.log('PDF erfolgreich erstellt'))
        .catch(err => console.error('Fehler beim Erstellen des PDFs:', err));

    await createMetadata(fileName)
    await cleanPdf(fileName);
}

async function cleanPdf(fileName) {
    const htmlPath = '/Users/mali/flutter_projects/macsignaturepad_project/template_generator/' + fileName + '.html';
    const cleanedHtmlPath = '/Users/mali/flutter_projects/macsignaturepad_project/template_generator/' + fileName + '_cleaned.html';

    const pdfPath = './' + fileName + '.pdf';

    const html = fs.readFileSync(htmlPath, 'utf8');

    // Platzhalter entfernen
    const cleanedHtml = html.replace(/##[^#]+##/g, '|');

    // HTML-Datei überschreiben
    await fs.writeFileSync(cleanedHtmlPath, cleanedHtml);
    htmlToPdf(cleanedHtmlPath, pdfPath)
        .then(() => console.log('PDF erfolgreich erstellt'))
        .catch(err => console.error('Fehler beim Erstellen des PDFs:', err));
}

async function createMetadata(fileName) {

    const jsonPath = './' + fileName + '_metadata.json';
    const pdfPath = './' + fileName + '.pdf';

    const pdf = await pdfjsLib.getDocument(pdfPath).promise;
    const metadata = {};

    for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const viewport = await page.getViewport({ scale: 1 });

        const textContent = await page.getTextContent();
        textContent.items.forEach(item => {
            let text = item.str;
            // remove line breaks
            text = text.replace(/(\r\n|\n|\r)/gm, '');
            const match = text.match(/##[^#]+##/g);

            if (match) {
                match.forEach(m => {
                    const placeholder = m && m.substring(2, m.length - 2);
                    if (metadata[placeholder] === undefined) {
                        metadata[placeholder] = [];
                    }
                    const tx = item.transform[4];
                    const ty = viewport.height - item.transform[5];
                    metadata[placeholder].push({
                        x: tx,
                        y: ty,
                        width: item.width,
                        height: item.height,
                        fontName: item.fontName,
                        page: i -1,
                    });
                });
            }
        });
    }

    fs.writeFileSync(jsonPath, JSON.stringify(metadata, null, 2));
}


