const AWS = require('aws-sdk');
const crypto = require('crypto');

// Configure AWS SDK
const s3 = new AWS.S3({
  apiVersion: '2006-03-01',
  signatureVersion: 'v4',
});

const lambda = new AWS.Lambda();
const cloudwatch = new AWS.CloudWatch();

// Environment variables
const BUCKET_NAME = process.env.BUCKET_NAME;
const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE) || 1073741824; // 1GB default
const ALLOWED_FORMATS = ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm', 'm4v'];

exports.handler = async (event) => {
  const startTime = Date.now();
  
  try {
    console.log('Event received:', JSON.stringify(event, null, 2));
    
    // Parse request body
    const body = JSON.parse(event.body);
    const { filename, userId, fileSize, contentType } = body;
    
    // Input validation
    if (!filename || !userId || !fileSize || !contentType) {
      throw new Error('Missing required parameters: filename, userId, fileSize, contentType');
    }
    
    // File size validation
    if (fileSize > MAX_FILE_SIZE) {
      throw new Error(`File size ${fileSize} exceeds maximum allowed size ${MAX_FILE_SIZE}`);
    }
    
    // File format validation
    const fileExtension = filename.split('.').pop().toLowerCase();
    if (!ALLOWED_FORMATS.includes(fileExtension)) {
      throw new Error(`File format ${fileExtension} is not allowed. Allowed formats: ${ALLOWED_FORMATS.join(', ')}`);
    }
    
    // Content type validation
    if (!contentType.startsWith('video/')) {
      throw new Error('Invalid content type. Only video files are allowed.');
    }
    
    // Generate unique file key
    const timestamp = new Date().toISOString();
    const fileKey = `uploads/${timestamp}/${userId}/${filename}`;
    
    // Check if file size requires multipart upload (>100MB)
    const requiresMultipart = fileSize > 100 * 1024 * 1024; // 100MB
    
    if (requiresMultipart) {
      // Initiate multipart upload
      const multipartResponse = await initiateMultipartUpload(fileKey, contentType, fileSize);
      
      // Log metrics
      await logMetrics('multipart_upload_initiated', 1);
      
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Allow-Methods': 'POST, OPTIONS'
        },
        body: JSON.stringify({
          uploadType: 'multipart',
          uploadId: multipartResponse.uploadId,
          fileKey: fileKey,
          parts: multipartResponse.parts,
          message: 'Multipart upload initiated successfully'
        })
      };
    } else {
      // Generate pre-signed URL for direct upload
      const signedUrl = s3.getSignedUrl('putObject', {
        Bucket: BUCKET_NAME,
        Key: fileKey,
        ContentType: contentType,
        Expires: 3600, // 1 hour
        Metadata: {
          userId: userId,
          originalName: filename,
          uploadType: 'direct'
        }
      });
      
      // Log metrics
      await logMetrics('direct_upload_url_generated', 1);
      
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Allow-Methods': 'POST, OPTIONS'
        },
        body: JSON.stringify({
          uploadType: 'direct',
          uploadUrl: signedUrl,
          fileKey: fileKey,
          expiresIn: 3600,
          message: 'Pre-signed URL generated successfully'
        })
      };
    }
    
  } catch (error) {
    console.error('Error processing upload request:', error);
    
    // Log error metrics
    await logMetrics('upload_errors', 1);
    
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
      },
      body: JSON.stringify({
        error: 'Upload request failed',
        message: error.message,
        timestamp: new Date().toISOString()
      })
    };
  } finally {
    // Log execution time
    const executionTime = Date.now() - startTime;
    await logMetrics('execution_time_ms', executionTime);
  }
};

async function initiateMultipartUpload(fileKey, contentType, fileSize) {
  const partSize = 100 * 1024 * 1024; // 100MB parts
  const numParts = Math.ceil(fileSize / partSize);
  
  // Initiate multipart upload
  const multipartUpload = await s3.createMultipartUpload({
    Bucket: BUCKET_NAME,
    Key: fileKey,
    ContentType: contentType,
    Metadata: {
      uploadType: 'multipart',
      totalParts: numParts.toString(),
      partSize: partSize.toString()
    }
  }).promise();
  
  // Generate pre-signed URLs for each part
  const parts = [];
  for (let i = 1; i <= numParts; i++) {
    const partNumber = i;
    const partKey = `${fileKey}.part${i}`;
    
    const signedUrl = s3.getSignedUrl('uploadPart', {
      Bucket: BUCKET_NAME,
      Key: fileKey,
      PartNumber: partNumber,
      UploadId: multipartUpload.UploadId,
      Expires: 3600 // 1 hour
    });
    
    parts.push({
      partNumber: partNumber,
      uploadUrl: signedUrl,
      partKey: partKey
    });
  }
  
  return {
    uploadId: multipartUpload.UploadId,
    parts: parts
  };
}

async function logMetrics(metricName, value) {
  try {
    await cloudwatch.putMetricData({
      Namespace: 'VideoUpload',
      MetricData: [
        {
          MetricName: metricName,
          Value: value,
          Unit: metricName === 'execution_time_ms' ? 'Milliseconds' : 'Count',
          Timestamp: new Date()
        }
      ]
    }).promise();
  } catch (error) {
    console.error('Failed to log metrics:', error);
  }
}
