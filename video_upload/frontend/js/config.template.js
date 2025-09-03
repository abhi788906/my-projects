// Frontend Configuration Template
// Copy this file to config.js and fill in your actual values
const CONFIG = {
    // AWS Configuration
    aws: {
        region: 'YOUR_AWS_REGION', // e.g., 'ap-south-1'
        userPoolId: 'YOUR_USER_POOL_ID', // e.g., 'ap-south-1_xxxxxxxxx'
        userPoolClientId: 'YOUR_USER_POOL_CLIENT_ID', // e.g., 'xxxxxxxxxxxxxxxxxxxxxxxxxx'
        identityPoolId: 'YOUR_IDENTITY_POOL_ID', // e.g., 'ap-south-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
        apiGatewayUrl: 'YOUR_API_GATEWAY_URL', // e.g., 'https://xxxxxxxxxx.execute-api.ap-south-1.amazonaws.com/production'
    },
    
    // Upload Configuration
    upload: {
        maxFileSize: 1024 * 1024 * 1024, // 1GB in bytes
        allowedFormats: ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm', 'm4v'],
        chunkSize: 100 * 1024 * 1024, // 100MB chunks
        maxConcurrentChunks: 3,
        retryAttempts: 3,
        retryDelay: 1000, // 1 second
    },
    
    // UI Configuration
    ui: {
        animationDuration: 300,
        progressUpdateInterval: 100, // ms
        autoHideMessages: 5000, // 5 seconds
        maxHistoryItems: 50,
    },
    
    // API Endpoints
    endpoints: {
        videoUpload: '/uploads',
        multipartInit: '/multipart/init',
        multipartComplete: '/multipart/complete',
    },
    
    // Local Storage Keys
    storage: {
        userToken: 'video_upload_user_token',
        userInfo: 'video_upload_user_info',
        uploadHistory: 'video_upload_history',
        settings: 'video_upload_settings',
    }
};

// Initialize configuration from environment or Terraform outputs
function initializeConfig() {
    // Try to load configuration from environment variables or Terraform outputs
    if (window.ENV_CONFIG) {
        Object.assign(CONFIG.aws, window.ENV_CONFIG);
    }
    
    // Load from localStorage if available
    const savedConfig = localStorage.getItem('video_upload_config');
    if (savedConfig) {
        try {
            const parsed = JSON.parse(savedConfig);
            Object.assign(CONFIG, parsed);
        } catch (e) {
            console.warn('Failed to parse saved configuration:', e);
        }
    }
    
    // Validate required configuration
    validateConfig();
}

// Validate configuration
function validateConfig() {
    const required = ['userPoolId', 'userPoolClientId', 'identityPoolId', 'apiGatewayUrl'];
    const missing = required.filter(key => !CONFIG.aws[key]);
    
    if (missing.length > 0) {
        console.warn('Missing required configuration:', missing);
        showConfigWarning();
    }
}

// Show configuration warning
function showConfigWarning() {
    const warning = document.createElement('div');
    warning.className = 'fixed top-4 right-4 bg-yellow-500 text-white px-6 py-3 rounded-lg shadow-lg z-50';
    warning.innerHTML = `
        <div class="flex items-center">
            <i class="fas fa-exclamation-triangle mr-2"></i>
            <span>Configuration incomplete. Please check console for details.</span>
        </span>
    `;
    document.body.appendChild(warning);
    
    setTimeout(() => {
        warning.remove();
    }, 10000);
}

// Save configuration to localStorage
function saveConfig() {
    try {
        localStorage.setItem('video_upload_config', JSON.stringify(CONFIG));
    } catch (e) {
        console.warn('Failed to save configuration:', e);
    }
}

// Update configuration
function updateConfig(key, value) {
    const keys = key.split('.');
    let current = CONFIG;
    
    for (let i = 0; i < keys.length - 1; i++) {
        current = current[keys[i]];
    }
    
    current[keys[keys.length - 1]] = value;
    saveConfig();
}

// Get configuration value
function getConfig(key) {
    const keys = key.split('.');
    let current = CONFIG;
    
    for (const k of keys) {
        if (current && typeof current === 'object' && k in current) {
            current = current[k];
        } else {
            return undefined;
        }
    }
    
    return current;
}

// Export configuration
window.CONFIG = CONFIG;
window.initializeConfig = initializeConfig;
window.updateConfig = updateConfig;
window.getConfig = getConfig;

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initializeConfig);
