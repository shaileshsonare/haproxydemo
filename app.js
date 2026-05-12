const express = require('express');
const session = require('express-session');

const app = express();

const PORT = process.env.PORT || 8081;
const SERVER_NAME = process.env.SERVER_NAME || 'node1';

let activeConnections = 0;

app.use(session({
    secret: 'demo-secret',
    resave: false,
    saveUninitialized: true
}));

app.use((req, res, next) => {

    activeConnections++;

    res.on('finish', () => {
        activeConnections--;
    });

    next();
});

app.get('/', async (req, res) => {

    await new Promise(r => setTimeout(r, 10000));

    if (!req.session.views) {
        req.session.views = 0;
    }

    req.session.views++;

    res.send(`
        <h1>${SERVER_NAME}</h1>
        <p>Session Views: ${req.session.views}</p>
        <p>Active Connections: ${activeConnections}</p>
    `);
});

app.get('/health', (req, res) => {

    res.json({
        server: SERVER_NAME,
        activeConnections: activeConnections,
        status: 'UP'
    });
});

app.listen(PORT, () => {
    console.log(`${SERVER_NAME} listening on ${PORT}`);
});