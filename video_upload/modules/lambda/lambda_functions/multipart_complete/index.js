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
    const { uploadId, fileKey, parts } = body;
    
    // Input validation
    if (!uploadId || !fileKey || !parts || !Array.isArray(parts)) {
      throw new Error('Missing required parameters: uploadId, fileKey, parts');
    }
    
    // Complete multipart upload
    const completedUpload = await s3.completeMultipartUpload({
      Bucket: process.env.BUCKET_NAME,
      Key: fileKey,
      UploadId: uploadId,
      MultipartUpload: {
        Parts: parts
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
        location: completedUpload.Location,
        bucket: completedUpload.Bucket,
        key: completedUpload.Key,
        etag: completedUpload.ETag,
        message: 'Multipart upload completed successfully'
      })
    };
    
  } catch (error) {
    console.error('Error completing multipart upload:', error);
    
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
      },
      body: JSON.stringify({
        error: 'Multipart upload completion failed',
        message: error.message,
        timestamp: new Date().toISOString()
      })
    };
  }
};

