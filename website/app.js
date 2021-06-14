const nunjucks = require('nunjucks')
const express = require('express')

const app = express()

nunjucks.configure('views', {
    express: app,
    autoescape: false,
    noCache: true
})

app.set('view engine', 'njk')
app.use(express.static('public'))

app.locals.title = process.env.WEBSITE_TITLE || 'Parrot'
app.locals.image = process.env.WEBSITE_IMAGE || 'parrot-1.jpg'
app.locals.version = process.env.WEBSITE_VERSION || require('./package.json').version


app.get('/', async (req, res) => {
    res.render('index')
})

app.get('/healthcheck', (req, res) => {
    res.json({ uptime: process.uptime() })
})

module.exports = app
