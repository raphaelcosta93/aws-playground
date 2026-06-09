const express = require('express');
const multer  = require('multer');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });
const s3     = new S3Client({ region: process.env.AWS_REGION });

const BUCKET = process.env.S3_BUCKET;

router.post('/', upload.single('image'), async (req, res) => {
  try {
    const file = req.file;
    const key  = 'images/' + crypto.randomUUID() + '/' + file.originalname;

    await s3.send(new PutObjectCommand({
      Bucket:      BUCKET,
      Key:         key,
      Body:        file.buffer,
      ContentType: file.mimetype
    }));

    res.json({ message: 'Uploaded successfully', s3_key: key });
  } catch (err) {
    console.error('ERROR upload:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
