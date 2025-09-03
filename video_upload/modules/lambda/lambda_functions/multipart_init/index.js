const AWS = require('aws-sdk');

// Configure AWS SDK
const s3 = new AWS.S3({
  apiVersion: '2006-03-01',
  signatureVersion: 'v4',
});

exports.handler = async (event) => {
  try {
    console.log('Event received:', JSON.stringify(event, null, 2));
    
    // Parse request body
    const body = JSON.parse(event.body);
    const { filename, userId, fileSize, contentType } = body;
    
    // Input validation
    if (!filename || !userId || !fileSize || !contentType) {
      throw new Error('Missing required parameters: filename, userId, fileSize, contentType');
    }
    
    // Generate unique file key
    const timestamp = new Date().toISOString();
    const fileKey = `uploads/${timestamp}/${userId}/${filename}`;
    
    // Initiate multipart upload with KMS encryption
    const multipartUpload = await s3.createMultipartUpload({
      Bucket: process.env.BUCKET_NAME,
      Key: fileKey,
      ContentType: contentType,
      ServerSideEncryption: 'aws:kms',
      SSEKMSKeyId: process.env.KMS_KEY_ID,
      Metadata: {
        userId: userId,
        originalName: filename,
        uploadType: 'multipart'
      }
    }).promise();
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
      },
      body: JSON.stringify({
        uploadId: multipartUpload.UploadId,
        fileKey: fileKey,
        message: 'Multipart upload initiated successfully'
      })
    };
    
  } catch (error) {
    console.error('Error initiating multipart upload:', error);
    
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
      },
      body: JSON.stringify({
        error: 'Multipart upload initiation failed',
        message: error.message,
        timestamp: new Date().toISOString()
      })
    };
  }
};
