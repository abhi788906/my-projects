// Main Application Controller
class VideoUploadApp {
    constructor() {
        this.isInitialized = false;
        this.errorModal = null;
        
        this.initialize();
    }
    
    // Initialize application
    async initialize() {
        try {
            console.log('🚀 Initializing Video Upload Platform...');
            
            // Wait for DOM to be ready
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => this.setupApp());
            } else {
                this.setupApp();
            }
            
        } catch (error) {
            console.error('Failed to initialize application:', error);
            this.showError('Application initialization failed');
        }
    }
    
    // Setup application
    setupApp() {
        try {
            // Initialize error modal
            this.setupErrorModal();
            
            // Initialize authentication manager
            this.setupAuthentication();
            
            // Setup drag and drop
            this.setupDragAndDrop();
            
            // Setup keyboard shortcuts
            this.setupKeyboardShortcuts();
            
            // Setup performance monitoring
            this.setupPerformanceMonitoring();
            
            // Setup service worker (if supported)
            this.setupServiceWorker();
            
            // Mark as initialized
            this.isInitialized = true;
            
            console.log('✅ Video Upload Platform initialized successfully');
            
            // Show welcome message
            this.showWelcomeMessage();
            
        } catch (error) {
            console.error('Failed to setup application:', error);
            this.showError('Application setup failed');
        }
    }
    
    // Setup error modal
    setupErrorModal() {
        const errorModal = document.getElementById('error-modal');
        const errorClose = document.getElementById('error-close');
        
        if (errorModal && errorClose) {
            this.errorModal = errorModal;
            
            errorClose.addEventListener('click', () => {
                this.hideErrorModal();
            });
            
            // Close on outside click
            errorModal.addEventListener('click', (e) => {
                if (e.target === errorModal) {
                    this.hideErrorModal();
                }
            });
            
            // Close on escape key
            document.addEventListener('keydown', (e) => {
                if (e.key === 'Escape' && !errorModal.classList.contains('hidden')) {
                    this.hideErrorModal();
                }
            });
        }
    }
    
    // Setup authentication
    setupAuthentication() {
        try {
            // Initialize AuthManager and make it globally available
            window.authManager = new AuthManager();
            console.log('✅ Authentication manager initialized');
        } catch (error) {
            console.error('Failed to setup authentication:', error);
            this.showError('Authentication setup failed');
        }
    }
    
    // Setup drag and drop
    setupDragAndDrop() {
        const uploadArea = document.getElementById('upload-area');
        
        if (uploadArea) {
            // Prevent default drag behaviors
            ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
                uploadArea.addEventListener(eventName, (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                });
            });
            
            // Visual feedback for drag operations
            uploadArea.addEventListener('dragenter', () => {
                uploadArea.classList.add('dragover');
            });
            
            uploadArea.addEventListener('dragleave', () => {
                uploadArea.classList.remove('dragover');
            });
            
            uploadArea.addEventListener('drop', (e) => {
                uploadArea.classList.remove('dragover');
                this.handleFileDrop(e);
            });
        }
    }
    
    // Setup keyboard shortcuts
    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Ctrl/Cmd + U to focus upload area
            if ((e.ctrlKey || e.metaKey) && e.key === 'u') {
                e.preventDefault();
                const uploadArea = document.getElementById('upload-area');
                if (uploadArea) {
                    uploadArea.focus();
                    uploadArea.click();
                }
            }
            
            // Ctrl/Cmd + L to focus login
            if ((e.ctrlKey || e.metaKey) && e.key === 'l') {
                e.preventDefault();
                const loginEmail = document.getElementById('login-email');
                if (loginEmail) {
                    loginEmail.focus();
                }
            }
            
            // Ctrl/Cmd + S to show signup
            if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                e.preventDefault();
                if (authManager) {
                    authManager.showForm('signup');
                }
            }
        });
    }
    
    // Setup performance monitoring
    setupPerformanceMonitoring() {
        // Monitor page load performance
        if ('performance' in window) {
            window.addEventListener('load', () => {
                setTimeout(() => {
                    const perfData = performance.getEntriesByType('navigation')[0];
                    if (perfData) {
                        console.log('📊 Page Load Performance:', {
                            'DOM Content Loaded': `${Math.round(perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart)}ms`,
                            'Page Load Complete': `${Math.round(perfData.loadEventEnd - perfData.loadEventStart)}ms`,
                            'Total Load Time': `${Math.round(perfData.loadEventEnd - perfData.navigationStart)}ms`
                        });
                    }
                }, 0);
            });
        }
        
        // Monitor upload performance
        if (uploadManager) {
            const originalAddToHistory = uploadManager.addToHistory.bind(uploadManager);
            uploadManager.addToHistory = function(uploadInfo) {
                // Add performance metrics
                if (uploadManager.currentUpload) {
                    uploadInfo.uploadDuration = Date.now() - uploadManager.currentUpload.startTime;
                    uploadInfo.uploadSpeed = uploadInfo.size / (uploadInfo.uploadDuration / 1000); // bytes per second
                }
                
                originalAddToHistory(uploadInfo);
            };
        }
    }
    
    // Setup service worker
    setupServiceWorker() {
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', async () => {
                try {
                    const registration = await navigator.serviceWorker.register('/sw.js');
                    console.log('✅ Service Worker registered:', registration);
                } catch (error) {
                    console.warn('Service Worker registration failed:', error);
                }
            });
        }
    }
    
    // Handle file drop
    handleFileDrop(event) {
        const files = event.dataTransfer.files;
        if (files.length > 0) {
            const file = files[0];
            
            // Validate file type
            if (!file.type.startsWith('video/')) {
                this.showError('Please drop a valid video file');
                return;
            }
            
            // Process file
            if (uploadManager) {
                uploadManager.processFile(file);
            }
        }
    }
    
    // Show welcome message
    showWelcomeMessage() {
        // Check if this is the first visit
        const isFirstVisit = !localStorage.getItem('video_upload_first_visit');
        
        if (isFirstVisit) {
            localStorage.setItem('video_upload_first_visit', 'true');
            
            // Show welcome toast
            setTimeout(() => {
                this.showWelcomeToast();
            }, 1000);
        }
    }
    
    // Show welcome toast
    showWelcomeToast() {
        const toast = document.createElement('div');
        toast.className = 'fixed bottom-4 right-4 bg-gradient-to-r from-blue-500 to-purple-600 text-white px-6 py-4 rounded-xl shadow-2xl z-50 slide-up';
        toast.innerHTML = `
            <div class="flex items-center space-x-3">
                <div class="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center">
                    <i class="fas fa-rocket text-white"></i>
                </div>
                <div>
                    <h4 class="font-semibold">Welcome to Video Upload Platform!</h4>
                    <p class="text-sm opacity-90">Drag & drop your videos or click to browse</p>
                </div>
                <button class="ml-4 text-white/80 hover:text-white transition-colors" onclick="this.parentElement.parentElement.remove()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `;
        
        document.body.appendChild(toast);
        
        // Auto-hide after 8 seconds
        setTimeout(() => {
            if (toast.parentElement) {
                toast.remove();
            }
        }, 8000);
    }
    
    // Show error modal
    showErrorModal(message) {
        if (this.errorModal) {
            const errorMessage = document.getElementById('error-message');
            if (errorMessage) {
                errorMessage.textContent = message;
            }
            this.errorModal.classList.remove('hidden');
        }
    }
    
    // Hide error modal
    hideErrorModal() {
        if (this.errorModal) {
            this.errorModal.classList.add('hidden');
        }
    }
    
    // Show error
    showError(message) {
        console.error('Error:', message);
        this.showErrorModal(message);
    }
    
    // Get application status
    getStatus() {
        return {
            initialized: this.isInitialized,
            auth: authManager ? authManager.isAuthenticated : false,
            upload: uploadManager ? uploadManager.currentUpload : null,
            config: CONFIG ? 'loaded' : 'not loaded'
        };
    }
    
    // Export application data
    exportData() {
        try {
            const data = {
                timestamp: new Date().toISOString(),
                uploadHistory: uploadManager ? uploadManager.uploadHistory : [],
                stats: uploadManager ? uploadManager.stats : {},
                config: CONFIG
            };
            
            const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = `video-upload-data-${new Date().toISOString().split('T')[0]}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            
            return true;
        } catch (error) {
            console.error('Failed to export data:', error);
            return false;
        }
    }
    
    // Import application data
    importData(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            
            reader.onload = (e) => {
                try {
                    const data = JSON.parse(e.target.result);
                    
                    // Validate data structure
                    if (data.uploadHistory && Array.isArray(data.uploadHistory)) {
                        if (uploadManager) {
                            uploadManager.uploadHistory = data.uploadHistory;
                            uploadManager.saveUploadHistory();
                            uploadManager.updateHistoryDisplay();
                            uploadManager.updateStats();
                        }
                        resolve(true);
                    } else {
                        reject(new Error('Invalid data format'));
                    }
                } catch (error) {
                    reject(error);
                }
            };
            
            reader.onerror = () => reject(new Error('Failed to read file'));
            reader.readAsText(file);
        });
    }
    
    // Reset application
    resetApplication() {
        if (confirm('Are you sure you want to reset the application? This will clear all upload history and settings.')) {
            try {
                // Clear localStorage
                localStorage.clear();
                
                // Reset upload manager
                if (uploadManager) {
                    uploadManager.uploadHistory = [];
                    uploadManager.stats = {
                        totalUploads: 0,
                        inProgress: 0,
                        completed: 0,
                        storageUsed: 0
                    };
                    uploadManager.updateHistoryDisplay();
                    uploadManager.updateStats();
                }
                
                // Reset auth manager
                if (authManager) {
                    authManager.logout();
                }
                
                // Reload page
                window.location.reload();
                
            } catch (error) {
                console.error('Failed to reset application:', error);
                this.showError('Failed to reset application');
            }
        }
    }
}

// Initialize application
let app;

document.addEventListener('DOMContentLoaded', () => {
    app = new VideoUploadApp();
});

// Export for global access
window.app = app;

// Global utility functions
window.utils = {
    // Format file size
    formatFileSize: (bytes) => {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },
    
    // Format timestamp
    formatTimestamp: (timestamp) => {
        const date = new Date(timestamp);
        const now = new Date();
        const diff = now - date;
        
        if (diff < 60000) return 'Just now';
        if (diff < 3600000) return Math.floor(diff / 60000) + 'm ago';
        if (diff < 86400000) return Math.floor(diff / 3600000) + 'h ago';
        if (diff < 2592000000) return Math.floor(diff / 86400000) + 'd ago';
        
        return date.toLocaleDateString();
    },
    
    // Generate random ID
    generateId: () => {
        return Math.random().toString(36).substr(2, 9);
    },
    
    // Debounce function
    debounce: (func, wait) => {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },
    
    // Throttle function
    throttle: (func, limit) => {
        let inThrottle;
        return function() {
            const args = arguments;
            const context = this;
            if (!inThrottle) {
                func.apply(context, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }
};

// Global error handler
window.addEventListener('error', (event) => {
    console.error('Global error:', event.error);
    if (app) {
        app.showError('An unexpected error occurred');
    }
});

// Global unhandled rejection handler
window.addEventListener('unhandledrejection', (event) => {
    console.error('Unhandled promise rejection:', event.reason);
    if (app) {
        app.showError('An operation failed unexpectedly');
    }
});

console.log('🎬 Video Upload Platform Application Loaded');
