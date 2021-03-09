const express = require('express');
const MongoClient = require('mongodb').MongoClient;

const dbHost = process.env.MONGODB_HOST || "localhost";
const dbPort = process.env.MONGODB_PORT || "27017";
const dbTable = process.env.MONGODB_TABLE || "posts";
const mongoUrl = `mongodb://${dbHost}:${dbPort}/${dbTable}`;

let posts;

async function dbConnect() {
    console.log("Database Configurations:")
    console.log(`\t- MONGODB_HOST: ${dbHost}`);
    console.log(`\t- MONGODB_PORT: ${dbPort}`);
    console.log(`\t- MONGODB_TABLE: ${dbTable}`);

    const conn = await MongoClient.connect(mongoUrl, {
        useUnifiedTopology: true,
        useNewUrlParser: true
    });

    posts = conn.db().collection('posts');
}

async function init() {
    await dbConnect();
}

const router = express.Router();

router.get('/', async (req, res) => {
    const allPosts = await posts.find({}).toArray();
    res.render('index', { items: allPosts });
});

router.post('/new', async (req, res) => {
    let post = {
        name: req.body.name,
        description: req.body.description,
    };

    await posts.insertOne(post);
    res.redirect('/');
});

module.exports = { router, init };