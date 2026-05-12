// node1.js

const express = require('express');

const app = express();

app.use((req, res) => {
    res.send('NODE1');
});

app.listen(8082, () => {
    console.log('NODE1 running on 8082');
});