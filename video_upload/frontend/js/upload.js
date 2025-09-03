// Video Upload Management
class UploadManager {
    constructor() {
        this.currentUpload = null;
        this.uploadHistory = [];
        this.stats = {
            totalUploads: 0,
            inProgress: 0,
            completed: 0,
            storageUsed: 0
        };
        
        this.loadUploadHistory();
        this.bindEvents();
        this.updateStats();
    }
    
    // Bind upload events
    bindEvents() {
        // File input
        const fileInput = document.getElementById('file-input');
        const browseBtn = document.getElementById('browse-btn');
        const uploadArea = document.getElementById('upload-area');
        
        if (browseBtn) {
            browseBtn.addEventListener('click', () => fileInput.click());
        }
        
        if (fileInput) {
            fileInput.addEventListener('change', (e) => this.handleFileSelect(e));
        }
        
        if (uploadArea) {
            uploadArea.addEventListener('dragover', (e) => this.handleDragOver(e));
            uploadArea.addEventListener('dragleave', (e) => this.handleDragLeave(e));
            uploadArea.addEventListener('drop', (e) => this.handleDrop(e));
            uploadArea.addEventListener('click', () => fileInput.click());
        }
    }
    
    // Handle file selection
    handleFileSelect(event) {
        const file = event.target.files[0];
        if (file) {
            this.processFile(file);
        }
    }
    
    // Handle drag over
    handleDragOver(event) {
        event.preventDefault();
        event.currentTarget.classList.add('dragover');
    }
    
    // Handle drag leave
    handleDragLeave(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('dragover');
    }
    
    // Handle drop
    handleDrop(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('dragover');
        
        const files = event.dataTransfer.files;
        if (files.length > 0) {
            this.processFile(files[0]);
        }
    }
    
    // Process selected file
    processFile(file) {
        // Validate file
        if (!this.validateFile(file)) {
            return;
        }
        
        // Start upload
        this.startUpload(file);
    }
    
    // Validate file
    validateFile(file) {
        // Check file size
        if (file.size > CONFIG.upload.maxFileSize) {
            this.showError(`File size ${this.formatFileSize(file.size)} exceeds maximum allowed size ${this.formatFileSize(CONFIG.upload.maxFileSize)}`);
            return false;
        }
        
        // Check file format
        const extension = file.name.split('.').pop().toLowerCase();
        if (!CONFIG.upload.allowedFormats.includes(extension)) {
            this.showError(`File format ${extension} is not allowed. Allowed formats: ${CONFIG.upload.allowedFormats.join(', ')}`);
            return false;
        }
        
        return true;
    }
    
    // Start upload
    async startUpload(file) {
        try {
            // Check authentication
            if (!authManager || !authManager.isAuthenticated) {
                this.showError('Please sign in to upload files');
                return;
            }
            
            // Initialize upload
            this.currentUpload = {
                file: file,
                startTime: Date.now(),
                status: 'preparing',
                progress: 0,
                parts: [],
                uploadId: null,
                fileKey: null
            };
            
            // Show upload progress
            this.showUploadProgress();
            this.updateUploadInfo();
            
            // Determine upload method
            if (file.size > CONFIG.upload.chunkSize) {
                await this.startMultipartUpload(file);
            } else {
                await this.startDirectUpload(file);
            }
            
        } catch (error) {
            console.error('Upload failed:', error);
            this.showError('Upload failed: ' + error.message);
            this.hideUploadProgress();
        }
    }
    
    // Start multipart upload
    async startMultipartUpload(file) {
        try {
            this.currentUpload.status = 'initializing';
            this.updateUploadStatus();
            
            // Get auth token
            const token = await authManager.getAuthToken();
            
            // Initialize multipart upload
            const response = await this.callAPI(CONFIG.endpoints.multipartInit, {
                filename: file.name,
                fileSize: file.size,
                contentType: file.type
            }, token);
            
            if (response.uploadType === 'multipart') {
                this.currentUpload.uploadId = response.uploadId;
                this.currentUpload.fileKey = response.fileKey;
                this.currentUpload.parts = response.parts;
                
                // Upload parts
                await this.uploadParts(file);
                
                // Complete upload
                await this.completeMultipartUpload();
            } else {
                throw new Error('Failed to initialize multipart upload');
            }
            
        } catch (error) {
            throw new Error('Multipart upload failed: ' + error.message);
        }
    }
    
    // Upload parts
    async uploadParts(file) {
        const totalParts = this.currentUpload.parts.length;
        let completedParts = 0;
        
        this.currentUpload.status = 'uploading';
        this.updateUploadStatus();
        
        // Create upload tasks for each part
        const uploadTasks = this.currentUpload.parts.map((part, index) => {
            return this.uploadPart(file, part, index + 1, totalParts);
        });
        
        // Upload parts with concurrency limit
        for (let i = 0; i < uploadTasks.length; i += CONFIG.upload.maxConcurrentChunks) {
            const batch = uploadTasks.slice(i, i + CONFIG.upload.maxConcurrentChunks);
            await Promise.all(batch);
        }
    }
    
    // Upload single part
    async uploadPart(file, part, partNumber, totalParts) {
        try {
            const start = (partNumber - 1) * CONFIG.upload.chunkSize;
            const end = Math.min(start + CONFIG.upload.chunkSize, file.size);
            const chunk = file.slice(start, end);
            
            // Update part progress
            this.updatePartProgress(partNumber, 'uploading', 0);
            
            // Upload chunk to S3
            const response = await fetch(part.uploadUrl, {
                method: 'PUT',
                body: chunk,
                headers: {
                    'Content-Type': file.type
                }
            });
            
            if (response.ok) {
                const etag = response.headers.get('etag');
                this.currentUpload.parts[partNumber - 1].etag = etag;
                this.currentUpload.parts[partNumber - 1].status = 'completed';
                
                this.updatePartProgress(partNumber, 'completed', 100);
                this.updateOverallProgress();
                
                return { partNumber, etag };
            } else {
                throw new Error(`Part ${partNumber} upload failed: ${response.statusText}`);
            }
            
        } catch (error) {
            this.updatePartProgress(partNumber, 'failed', 0);
            throw new Error(`Part ${partNumber} failed: ${error.message}`);
        }
    }
    
    // Complete multipart upload
    async completeMultipartUpload() {
        try {
            this.currentUpload.status = 'completing';
            this.updateUploadStatus();
            
            const token = await authManager.getAuthToken();
            
            const response = await this.callAPI(CONFIG.endpoints.multipartComplete, {
                uploadId: this.currentUpload.uploadId,
                fileKey: this.currentUpload.fileKey,
                parts: this.currentUpload.parts.map((part, index) => ({
                    PartNumber: index + 1,
                    ETag: part.etag
                }))
            }, token);
            
            if (response.message === 'Multipart upload completed successfully') {
                this.currentUpload.status = 'completed';
                this.currentUpload.progress = 100;
                this.updateUploadStatus();
                this.updateOverallProgress();
                
                // Add to history
                this.addToHistory({
                    filename: this.currentUpload.file.name,
                    size: this.currentUpload.file.size,
                    status: 'completed',
                    timestamp: Date.now(),
                    fileKey: this.currentUpload.fileKey,
                    uploadType: 'multipart'
                });
                
                this.showSuccess('Video uploaded successfully!');
                setTimeout(() => this.hideUploadProgress(), 3000);
                
            } else {
                throw new Error('Failed to complete multipart upload');
            }
            
        } catch (error) {
            throw new Error('Failed to complete upload: ' + error.message);
        }
    }
    
    // Start direct upload
    async startDirectUpload(file) {
        try {
            this.currentUpload.status = 'uploading';
            this.updateUploadStatus();
            
            const token = await authManager.getAuthToken();
            
            const response = await this.callAPI(CONFIG.endpoints.videoUpload, {
                filename: file.name,
                fileSize: file.size,
                contentType: file.type
            }, token);
            
            if (response.uploadType === 'direct') {
                // Direct upload to S3
                const uploadResponse = await fetch(response.uploadUrl, {
                    method: 'PUT',
                    body: file,
                    headers: {
                        'Content-Type': file.type
                    }
                });
                
                if (uploadResponse.ok) {
                    this.currentUpload.status = 'completed';
                    this.currentUpload.progress = 100;
                    this.updateUploadStatus();
                    this.updateOverallProgress();
                    
                    // Add to history
                    this.addToHistory({
                        filename: file.name,
                        size: file.size,
                        status: 'completed',
                        timestamp: Date.now(),
                        fileKey: response.fileKey,
                        uploadType: 'direct'
                    });
                    
                    this.showSuccess('Video uploaded successfully!');
                    setTimeout(() => this.hideUploadProgress(), 3000);
                    
                } else {
                    throw new Error('Direct upload failed');
                }
            } else {
                throw new Error('Unexpected response from upload API');
            }
            
        } catch (error) {
            throw new Error('Direct upload failed: ' + error.message);
        }
    }
    
    // Call API
    async callAPI(endpoint, data, token) {
        const url = CONFIG.aws.apiGatewayUrl + endpoint;
        
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(data)
        });
        
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || `API call failed: ${response.statusText}`);
        }
        
        return await response.json();
    }
    
    // Show upload progress
    showUploadProgress() {
        const uploadProgress = document.getElementById('upload-progress');
        if (uploadProgress) {
            uploadProgress.classList.remove('hidden');
            uploadProgress.classList.add('slide-up');
        }
    }
    
    // Hide upload progress
    hideUploadProgress() {
        const uploadProgress = document.getElementById('upload-progress');
        if (uploadProgress) {
            uploadProgress.classList.add('hidden');
        }
        
        this.currentUpload = null;
    }
    
    // Update upload info
    updateUploadInfo() {
        if (!this.currentUpload) return;
        
        const filename = document.getElementById('upload-filename');
        const filesize = document.getElementById('upload-filesize');
        
        if (filename) filename.textContent = this.currentUpload.file.name;
        if (filesize) filesize.textContent = this.formatFileSize(this.currentUpload.file.size);
    }
    
    // Update upload status
    updateUploadStatus() {
        if (!this.currentUpload) return;
        
        const status = document.getElementById('upload-status');
        if (status) {
            status.textContent = this.currentUpload.status.charAt(0).toUpperCase() + this.currentUpload.status.slice(1);
        }
    }
    
    // Update part progress
    updatePartProgress(partNumber, status, progress) {
        const partsProgress = document.getElementById('parts-progress');
        if (!partsProgress) return;
        
        let partElement = document.getElementById(`part-${partNumber}`);
        if (!partElement) {
            partElement = this.createPartProgressElement(partNumber);
            partsProgress.appendChild(partElement);
        }
        
        // Update part status and progress
        const progressBar = partElement.querySelector('.part-progress-bar');
        const statusText = partElement.querySelector('.part-status');
        
        if (progressBar) progressBar.style.width = `${progress}%`;
        if (statusText) statusText.textContent = status;
        
        // Update colors based on status
        if (status === 'completed') {
            partElement.classList.add('bg-green-50');
            partElement.classList.remove('bg-yellow-50', 'bg-red-50');
        } else if (status === 'uploading') {
            partElement.classList.add('bg-yellow-50');
            partElement.classList.remove('bg-green-50', 'bg-red-50');
        } else if (status === 'failed') {
            partElement.classList.add('bg-red-50');
            partElement.classList.remove('bg-green-50', 'bg-yellow-50');
        }
    }
    
    // Create part progress element
    createPartProgressElement(partNumber) {
        const element = document.createElement('div');
        element.id = `part-${partNumber}`;
        element.className = 'bg-gray-50 rounded-lg p-4 transition-all duration-300';
        
        element.innerHTML = `
            <div class="flex justify-between items-center mb-2">
                <span class="text-sm font-medium text-gray-700">Part ${partNumber}</span>
                <span class="part-status text-sm text-gray-500">Preparing...</span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2">
                <div class="part-progress-bar bg-blue-600 h-2 rounded-full transition-all duration-300" style="width: 0%"></div>
            </div>
        `;
        
        return element;
    }
    
    // Update overall progress
    updateOverallProgress() {
        if (!this.currentUpload) return;
        
        const totalParts = this.currentUpload.parts.length;
        if (totalParts === 0) return;
        
        const completedParts = this.currentUpload.parts.filter(part => part.status === 'completed').length;
        const progress = Math.round((completedParts / totalParts) * 100);
        
        this.currentUpload.progress = progress;
        
        const progressBar = document.getElementById('overall-progress-bar');
        const progressText = document.getElementById('overall-progress-text');
        
        if (progressBar) progressBar.style.width = `${progress}%`;
        if (progressText) progressText.textContent = `${progress}%`;
    }
    
    // Add to upload history
    addToHistory(uploadInfo) {
        this.uploadHistory.unshift(uploadInfo);
        
        // Limit history size
        if (this.uploadHistory.length > CONFIG.ui.maxHistoryItems) {
            this.uploadHistory = this.uploadHistory.slice(0, CONFIG.ui.maxHistoryItems);
        }
        
        this.saveUploadHistory();
        this.updateHistoryDisplay();
        this.updateStats();
    }
    
    // Load upload history
    loadUploadHistory() {
        try {
            const saved = localStorage.getItem(CONFIG.storage.uploadHistory);
            if (saved) {
                this.uploadHistory = JSON.parse(saved);
            }
        } catch (error) {
            console.warn('Failed to load upload history:', error);
        }
    }
    
    // Save upload history
    saveUploadHistory() {
        try {
            localStorage.setItem(CONFIG.storage.uploadHistory, JSON.stringify(this.uploadHistory));
        } catch (error) {
            console.warn('Failed to save upload history:', error);
        }
    }
    
    // Update history display
    updateHistoryDisplay() {
        const historyList = document.getElementById('history-list');
        if (!historyList) return;
        
        if (this.uploadHistory.length === 0) {
            historyList.innerHTML = `
                <div class="text-center py-12">
                    <i class="fas fa-inbox text-4xl text-gray-300 mb-4"></i>
                    <p class="text-gray-500 text-lg">No uploads yet</p>
                    <p class="text-gray-400 text-sm">Your uploaded videos will appear here</p>
                </div>
            `;
            return;
        }
        
        historyList.innerHTML = this.uploadHistory.map(upload => `
            <div class="bg-white rounded-lg p-4 shadow-sm border border-gray-200 hover:shadow-md transition-shadow duration-300">
                <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-3">
                        <div class="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                            <i class="fas fa-video text-blue-600"></i>
                        </div>
                        <div>
                            <h4 class="font-medium text-gray-900 truncate">${upload.filename}</h4>
                            <p class="text-sm text-gray-500">${this.formatFileSize(upload.size)} • ${this.formatTimestamp(upload.timestamp)}</p>
                        </div>
                    </div>
                    <div class="flex items-center space-x-2">
                        <span class="px-2 py-1 text-xs font-medium rounded-full ${
                            upload.status === 'completed' ? 'bg-green-100 text-green-800' :
                            upload.status === 'failed' ? 'bg-red-100 text-red-800' :
                            'bg-yellow-100 text-yellow-800'
                        }">
                            ${upload.status.charAt(0).toUpperCase() + upload.status.slice(1)}
                        </span>
                        <span class="px-2 py-1 text-xs font-medium bg-gray-100 text-gray-800 rounded-full">
                            ${upload.uploadType}
                        </span>
                    </div>
                </div>
            </div>
        `).join('');
    }
    
    // Update stats
    updateStats() {
        this.stats.totalUploads = this.uploadHistory.length;
        this.stats.completed = this.uploadHistory.filter(u => u.status === 'completed').length;
        this.stats.inProgress = this.currentUpload ? 1 : 0;
        this.stats.storageUsed = this.uploadHistory
            .filter(u => u.status === 'completed')
            .reduce((total, u) => total + u.size, 0);
        
        // Update stats display
        const statsElements = document.querySelectorAll('.stats-card h3');
        if (statsElements.length >= 4) {
            statsElements[0].textContent = this.stats.totalUploads;
            statsElements[1].textContent = this.stats.inProgress;
            statsElements[2].textContent = this.stats.completed;
            statsElements[3].textContent = this.formatFileSize(this.stats.storageUsed);
        }
    }
    
    // Format file size
    formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }
    
    // Format timestamp
    formatTimestamp(timestamp) {
        const date = new Date(timestamp);
        const now = new Date();
        const diff = now - date;
        
        if (diff < 60000) return 'Just now';
        if (diff < 3600000) return Math.floor(diff / 60000) + 'm ago';
        if (diff < 86400000) return Math.floor(diff / 3600000) + 'h ago';
        if (diff < 2592000000) return Math.floor(diff / 86400000) + 'd ago';
        
        return date.toLocaleDateString();
    }
    
    // Show success message
    showSuccess(message) {
        if (authManager && authManager.showSuccess) {
            authManager.showSuccess(message);
        }
    }
    
    // Show error message
    showError(message) {
        if (authManager && authManager.showError) {
            authManager.showError(message);
        }
    }
}

// Initialize upload manager
let uploadManager;

document.addEventListener('DOMContentLoaded', () => {
    uploadManager = new UploadManager();
});

// Export for global access
window.uploadManager = uploadManager;

