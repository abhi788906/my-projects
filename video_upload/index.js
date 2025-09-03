const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  apiVersion: '2006-03-01',
  signatureVersion: 'v4',
});

exports.handler = async (event) => {
  const bucketName = process.env.BUCKET_NAME;
  const body = JSON.parse(event.body);
  console.log(body)
  
  const timestamp = new Date().toISOString();
  const userId = body.userId; 

  const filenamePath = body.filename; 
  const parts = filenamePath.split('/'); 
  const filename = parts.pop();
  const key = `${timestamp}/${userId}/${filename}`; 


  const signedUrl = s3.getSignedUrl('putObject', {
    Bucket: bucketName,
    Key: key,
    Expires: 300, 
  });

  const responseBody = {
    uploadUrl: signedUrl,
    fileKey: key,
  };

  return {
    statusCode: 200,
    body: JSON.stringify(responseBody),
  };
};
