// node2.js

const express = require('express');

const app = express();

app.use((req, res) => {
    res.send('NODE2');
});

app.listen(8083, () => {
    console.log('NODE2 running on 8083');
});