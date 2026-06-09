const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const { DynamoDBClient }                               = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand }           = require('@aws-sdk/lib-dynamodb');
const sharp                                            = require('sharp');

const s3     = new S3Client({});
const dynamo = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const BUCKET = process.env.S3_BUCKET;
const TABLE  = process.env.DYNAMO_TABLE;

const streamToBuffer = async (stream) => {
  const chunks = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
};

exports.handler = async (event) => {
  const record      = event.Records[0];
  const originalKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));

  const { Body } = await s3.send(new GetObjectCommand({ Bucket: BUCKET, Key: originalKey }));
  const originalBuffer = await streamToBuffer(Body);

  const resizedBuffer = await sharp(originalBuffer)
    .resize({ width: 800, withoutEnlargement: true })
    .jpeg({ quality: 85 })
    .toBuffer();

  // images/original/<uuid>/filename -> images/resized/<uuid>/filename
  const resizedKey = originalKey.replace('images/original/', 'images/resized/');

  await s3.send(new PutObjectCommand({
    Bucket:      BUCKET,
    Key:         resizedKey,
    Body:        resizedBuffer,
    ContentType: 'image/jpeg',
  }));

  const parts    = originalKey.split('/');
  const imageId  = parts[2];
  const filename = parts[3];

  await dynamo.send(new PutCommand({
    TableName: TABLE,
    Item: {
      image_id:    imageId,
      s3_key:      resizedKey,
      filename:    filename,
      size:        resizedBuffer.length,
      uploaded_at: new Date().toISOString(),
    },
  }));
};
