const express = require('express');
const bodyParser = require('body-parser');
const app = express();

// Ihre Cloud Function importieren
const { createPdf } = require('./index'); // Pfad zur Datei Ihrer Cloud Function

app.use(bodyParser.json());
app.post('/', (req, res) => {
    createPdf(req, res); // Ihre Cloud Function aufrufen
});

const port = 8080;
app.listen(port, () => {
    console.log(`Server läuft auf http://localhost:${port}`);
});
