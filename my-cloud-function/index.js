// my-cloud-function % gcloud functions deploy createPdf_ --runtime nodejs18 --trigger-http --allow-unauthenticated --region europe-west1 --memory=2048MB --timeout=540s --docker-registry=artifact-registry --no-gen2
const puppeteer = require('puppeteer-core');
const chromium = require('chrome-aws-lambda');
const fs = require('fs').promises;
const path = require('path');

exports.createPdf5 = async (req, res) => {
    try {
        const { pdf_name, placeholders } = req.body;
        if (!pdf_name) {
            return res.status(400).send('pdf_name fehlt');
        }
        if (!placeholders) {
            return res.status(400).send('placeholders fehlen');
        }
        if (typeof placeholders !== 'object') {
            return res.status(400).send('placeholders muss ein Objekt sein');
        }

        const browser = await puppeteer.launch({
            args: chromium.args,
            executablePath: await chromium.executablePath,
            headless: chromium.headless,
        });

        const page = await browser.newPage();

        const htmlFilePath = path.join(__dirname, pdf_name + '.html');
        let htmlContent = await fs.readFile(htmlFilePath, 'utf8');

        // Platzhalter ersetzen
        for (const placeholder in placeholders) {
            htmlContent = htmlContent.replace(new RegExp(`##${placeholder}##`, 'g'), placeholders[placeholder]);
        }

        if (placeholders.signature) {
            // Wenn eine Signatur vorhanden ist, fügen Sie die Base64-Daten ein und setzen Sie die Klasse auf 'signature-visible'
            htmlContent = htmlContent.replace('##signature##', placeholders.signature);
            htmlContent = htmlContent.replace('##signature_show##', 'signature-visible');
        } else {
            // Wenn keine Signatur vorhanden ist, leeren Sie den Base64-Wert und setzen Sie die Klasse auf 'signature-hidden'
            htmlContent = htmlContent.replace('##signature##', '');
            htmlContent = htmlContent.replace('##signature_show##', 'signature-hidden');
        }

        // HTML-Inhalt an Puppeteer übergeben
        await page.setContent(htmlContent, { waitUntil: 'networkidle0' });

        const pdfBuffer = await page.pdf({ format: 'A4' });

        await browser.close();

        // Konvertieren des PDF-Buffers in einen Base64-String
        const pdfBase64 = pdfBuffer.toString('base64');

        // Senden des Base64-Strings als Antwort
        res.setHeader('Content-Type', 'text/plain');
        res.send(pdfBase64);
    } catch (error) {
        console.error('Fehler beim Erstellen des PDFss:', error);
        res.status(500).send('Interner Serverfehler');
    }
};