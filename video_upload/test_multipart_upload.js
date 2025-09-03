const fs = require('fs');
const https = require('https');
const { URL } = require('url');

// Read the response from Lambda
const response = JSON.parse(fs.readFileSync('response-final-test.json', 'utf8'));
const body = JSON.parse(response.body);

console.log('🚀 Testing Multipart Upload for Video File');
console.log('==========================================');
console.log(`File: ${body.fileKey}`);
console.log(`Upload ID: ${body.uploadId}`);
console.log(`Parts: ${body.parts.length}`);
console.log('');

// Function to upload a part
async function uploadPart(part, partNumber) {
  return new Promise((resolve, reject) => {
    const url = new URL(part.uploadUrl);
    const filePath = 'Cloud Computing (S2-24_CCZG527)-20250216_154047-Meeting Recording.mp4';
    
    // Calculate part boundaries (100MB each)
    const partSize = 100 * 1024 * 1024; // 100MB
    const start = (partNumber - 1) * partSize;
    const end = Math.min(start + partSize, fs.statSync(filePath).size);
    
    console.log(`📤 Uploading Part ${partNumber}: bytes ${start}-${end-1}`);
    
    const fileStream = fs.createReadStream(filePath, { start, end: end - 1 });
    
    const options = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: 'PUT',
      headers: {
        'Content-Length': end - start,
        'Content-Type': 'video/mp4'
      }
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log(`✅ Part ${partNumber} uploaded successfully`);
          resolve({
            PartNumber: partNumber,
            ETag: res.headers.etag
          });
        } else {
          console.log(`❌ Part ${partNumber} failed: ${res.statusCode} - ${data}`);
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    
    req.on('error', (err) => {
      console.log(`❌ Part ${partNumber} error: ${err.message}`);
      reject(err);
    });
    
    fileStream.pipe(req);
  });
}

// Main upload function
async function uploadVideo() {
  try {
    console.log('Starting multipart upload...\n');
    
    const uploadedParts = [];
    
    // Upload each part
    for (const part of body.parts) {
      const result = await uploadPart(part, part.partNumber);
      uploadedParts.push(result);
    }
    
    console.log('\n🎉 All parts uploaded successfully!');
    console.log('====================================');
    console.log('Uploaded parts:');
    uploadedParts.forEach(part => {
      console.log(`  Part ${part.PartNumber}: ETag ${part.ETag}`);
    });
    
    console.log('\nNext steps:');
    console.log('1. Complete the multipart upload using the multipart_complete Lambda');
    console.log('2. Verify the file in S3');
    console.log('3. Test video playback');
    
    // Save the uploaded parts for completion
    fs.writeFileSync('uploaded_parts.json', JSON.stringify(uploadedParts, null, 2));
    console.log('\n📝 Uploaded parts saved to uploaded_parts.json');
    
  } catch (error) {
    console.error('❌ Upload failed:', error.message);
    process.exit(1);
  }
}

// Check if video file exists
const videoFile = 'Cloud Computing (S2-24_CCZG527)-20250216_154047-Meeting Recording.mp4';
if (!fs.existsSync(videoFile)) {
  console.error(`❌ Video file not found: ${videoFile}`);
  console.log('Please ensure the video file is in the current directory');
  process.exit(1);
}

// Start upload
uploadVideo();
