const fs = require('fs');
const axios = require('axios');
const mime = require('mime-types');

const file = 'C:/Users/Mansimrat Bedi/Downloads/sample_1280x720_surfing_with_audio.mp4';
const apiUrl = 'https://5bg47nekj1.execute-api.ap-south-1.amazonaws.com/Prod/upload';
const userId =  1 ;

// Read the file content and detect the file type
const fileContent = fs.readFileSync(file);
const detectedType = mime.lookup(file);
const contentType = detectedType ? detectedType : 'application/octet-stream';

// Send a POST request to the API Gateway endpoint to get the pre-signed URL and file key
axios.post(apiUrl, { "filename" : file , "userId" : userId}, {
  headers: {
    'Content-Type': 'application/json'
  }
})
  .then(response => {
    // Get the pre-signed URL and file key from the response
    const { uploadUrl, fileKey } = response.data;

    // Send a PUT request to the pre-signed URL with the form data
    axios.put(uploadUrl, fileContent, {
      headers: {
        'Content-Type': contentType
      }
    })
      .then(() => {
        console.log(`File uploaded successfully to S3: ${fileKey}`);
      })
      .catch(error => {
        console.error('Error uploading file to S3:', error);
      });
  })
  .catch(error => {
    console.error('Error getting pre-signed URL:', error);
  });
