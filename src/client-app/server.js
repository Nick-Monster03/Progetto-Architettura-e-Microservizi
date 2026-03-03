const express = require('express');
const cors = require('cors');
const app = express();
const port = 3000;

// Serve i file statici dalla cartella 'public'
app.use(express.static('public'));

// Abilita CORS (utile se estenderai il server node in futuro)
app.use(cors());

app.listen(port, () => {
    console.log(`📱 ACME Client App running at http://localhost:${port}`);
});