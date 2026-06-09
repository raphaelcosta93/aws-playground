const express = require('express');
const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const router = express.Router();
const s3     = new S3Client({ region: process.env.AWS_REGION });
const dynamo = DynamoDBDocumentClient.from(new DynamoDBClient({ region: process.env.AWS_REGION }));

const BUCKET = process.env.S3_BUCKET;
const TABLE  = process.env.DYNAMO_TABLE;

router.get('/', async (req, res) => {
  try {
    const { Items = [] } = await dynamo.send(new ScanCommand({ TableName: TABLE }));

    const images = await Promise.all(Items.map(async (item) => {
      const url = await getSignedUrl(
        s3,
        new GetObjectCommand({ Bucket: BUCKET, Key: item.s3_key }),
        { expiresIn: 3600 }
      );
      return Object.assign({}, item, { url });
    }));

    res.json(images);
  } catch (err) {
    console.error('ERROR images:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
