const express = require('express');
const morgan  = require('morgan');
const helmet  = require('helmet');
const path    = require('path');

const uploadRouter = require('./routes/upload');
const imagesRouter = require('./routes/images');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(helmet({
  contentSecurityPolicy: {
    useDefaults: true,
    directives: {
      upgradeInsecureRequests: null,
      imgSrc: ["'self'", 'data:', 'https://*.amazonaws.com'],
    },
  },
  strictTransportSecurity: false,
}));
app.use(morgan('combined'));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/upload', uploadRouter);
app.use('/images', imagesRouter);

app.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});
