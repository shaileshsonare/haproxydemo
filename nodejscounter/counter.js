const express = require('express');

const app = express();

let counter = 0;

app.get('/count', (req, res) => {
    counter++;
    res.send(counter.toString());
});

app.get('/route', (req, res) => {

    counter++;

    console.log('Counter:', counter);

    // ODD
    if (counter % 2 !== 0) {
        res.set('X-Route', 'node1');
    }

    // EVEN
    else {
        res.set('X-Route', 'node2');
    }

    res.send('ok');
});

app.listen(8081, () => {
    console.log('Counter API on 8081');
});