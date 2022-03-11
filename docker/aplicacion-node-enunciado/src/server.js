import express from 'express';
import mustacheExpress from 'mustache-express';
import { __dirname } from './dirname.js';

const port = 5000;

let app = express()

const images = [
    "https://media.giphy.com/media/mlvseq9yvZhba/giphy.gif",
    "https://media.giphy.com/media/MCfhrrNN1goH6/giphy.gif",
    "https://media.giphy.com/media/8vQSQ3cNXuDGo/giphy.gif",
    "https://media.giphy.com/media/rwCX06Y5XpbLG/giphy.gif",
    "https://media.giphy.com/media/vFKqnCdLPNOKc/giphy.gif",
    "https://media.giphy.com/media/CqVNwrLt9KEDK/giphy.gif",
    "https://media.giphy.com/media/MWSRkVoNaC30A/giphy.gif",
    "https://media.giphy.com/media/TEkr9oBZ57KFmMWScZ/giphy.gif"
]

// Register '.html' extension with The Mustache Express
app.set('view engine', 'html');
app.set('views', __dirname + '/views');
app.engine('html', mustacheExpress());

app.get('/', function (req, res) {
    let image = images[Math.floor(Math.random() * images.length)];
    res.render('index', { url: image });
});

process.on('SIGINT', () => {
    process.exit(0);
});

app.listen(port, () => {
    console.log(`* Running on http://localhost:${port}/`);
    console.log("  (Press CTRL+C to quit)");
});