const express = require('express');
const cors = require('cors');
const app = express();
const port = 3000;

app.use(cors());
app.use(express.json()); // ← necessario per leggere req.body

// Serve i file statici dalla cartella 'public'
app.use(express.static('public'));

// Proxy per UserService
app.post('/api/loginUser', async (req, res) => {
    try {
        const response = await fetch('http://user-service:8005/loginUser', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        const data = await response.json();
        res.json(data);
    } catch (err) {
        res.status(500).json({ success: false, message: 'UserService non raggiungibile.' });
    }
});

app.post('/api/registerUser', async (req, res) => {
    try {
        const response = await fetch('http://user-service:8005/registerUser', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        const data = await response.json();
        res.json(data);
    } catch (err) {
        res.status(500).json({ success: false, message: 'UserService non raggiungibile.' });
    }
});

app.listen(port, () => {
    console.log(`📱 ACME Client App running at http://localhost:${port}`);
});