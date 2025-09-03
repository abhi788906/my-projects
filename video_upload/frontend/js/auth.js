// Authentication Management
class AuthManager {
    constructor() {
        this.userPool = null;
        this.currentUser = null;
        this.currentSession = null;
        this.isAuthenticated = false;
        
        this.initializeCognito();
        this.bindEvents();
        this.checkAuthStatus();
    }
    
    // Initialize Cognito User Pool
    initializeCognito() {
        try {
            if (!CONFIG.aws.userPoolId || !CONFIG.aws.userPoolClientId) {
                console.warn('Cognito configuration not available');
                return;
            }
            
            const poolData = {
                UserPoolId: CONFIG.aws.userPoolId,
                ClientId: CONFIG.aws.userPoolClientId
            };
            
            this.userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);
            console.log('Cognito User Pool initialized');
        } catch (error) {
            console.error('Failed to initialize Cognito:', error);
        }
    }
    
    // Bind authentication events
    bindEvents() {
        console.log('🔐 Binding authentication events...');
        
        // Login form
        const loginForm = document.getElementById('login-form-element');
        if (loginForm) {
            loginForm.addEventListener('submit', (e) => this.handleLogin(e));
            console.log('✅ Login form event bound');
        } else {
            console.warn('⚠️ Login form not found');
        }
        
        // Signup form
        const signupForm = document.getElementById('signup-form-element');
        if (signupForm) {
            signupForm.addEventListener('submit', (e) => this.handleSignup(e));
            console.log('✅ Signup form event bound');
        } else {
            console.warn('⚠️ Signup form not found');
        }
        
        // Verification form
        const verificationForm = document.getElementById('verification-form-element');
        if (verificationForm) {
            verificationForm.addEventListener('submit', (e) => this.handleVerification(e));
            console.log('✅ Verification form event bound');
        } else {
            console.warn('⚠️ Verification form not found');
        }
        
        // Logout button
        const logoutBtn = document.getElementById('logout-btn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', () => this.logout());
            console.log('✅ Logout button event bound');
        } else {
            console.warn('⚠️ Logout button not found');
        }
        
        // Form navigation
        const showSignupBtn = document.getElementById('show-signup');
        const showLoginBtn = document.getElementById('show-login');
        
        if (showSignupBtn) {
            showSignupBtn.addEventListener('click', () => {
                console.log('🔄 Show signup button clicked');
                this.showForm('signup');
            });
            console.log('✅ Show signup button event bound');
        } else {
            console.warn('⚠️ Show signup button not found');
        }
        
        if (showLoginBtn) {
            showLoginBtn.addEventListener('click', () => {
                console.log('🔄 Show login button clicked');
                this.showForm('login');
            });
            console.log('✅ Show login button event bound');
        } else {
            console.warn('⚠️ Show login button not found');
        }
        
        console.log('🔐 Authentication events binding completed');
    }
    
    // Check authentication status
    async checkAuthStatus() {
        try {
            if (!this.userPool) return;
            
            const currentUser = this.userPool.getCurrentUser();
            if (currentUser) {
                const session = await this.getCurrentSession(currentUser);
                if (session && session.isValid()) {
                    this.currentUser = currentUser;
                    this.currentSession = session;
                    this.isAuthenticated = true;
                    this.onAuthSuccess();
                } else {
                    this.logout();
                }
            }
        } catch (error) {
            console.error('Error checking auth status:', error);
            this.logout();
        }
    }
    
    // Get current session
    getCurrentSession(user) {
        return new Promise((resolve, reject) => {
            user.getSession((err, session) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(session);
                }
            });
        });
    }
    
    // Handle login
    async handleLogin(event) {
        event.preventDefault();
        
        const email = document.getElementById('login-email').value;
        const password = document.getElementById('login-password').value;
        
        if (!email || !password) {
            this.showError('Please fill in all fields');
            return;
        }
        
        this.showLoading('Signing in...');
        
        try {
            const userData = {
                Username: email,
                Pool: this.userPool
            };
            
            const cognitoUser = new AmazonCognitoIdentity.CognitoUser(userData);
            
            const authDetails = new AmazonCognitoIdentity.AuthenticationDetails({
                Username: email,
                Password: password
            });
            
            cognitoUser.authenticateUser(authDetails, {
                onSuccess: (result) => {
                    this.hideLoading();
                    this.currentUser = cognitoUser;
                    this.currentSession = result;
                    this.isAuthenticated = true;
                    this.onAuthSuccess();
                    this.showSuccess('Successfully signed in!');
                },
                onFailure: (err) => {
                    this.hideLoading();
                    this.showError(err.message || 'Login failed');
                },
                newPasswordRequired: (userAttributes, requiredAttributes) => {
                    this.hideLoading();
                    this.showError('New password required. Please contact administrator.');
                }
            });
        } catch (error) {
            this.hideLoading();
            this.showError('Login failed: ' + error.message);
        }
    }
    
    // Handle signup
    async handleSignup(event) {
        event.preventDefault();
        
        const email = document.getElementById('signup-email').value;
        const password = document.getElementById('signup-password').value;
        const confirmPassword = document.getElementById('signup-confirm-password').value;
        
        if (!email || !password || !confirmPassword) {
            this.showError('Please fill in all fields');
            return;
        }
        
        if (password !== confirmPassword) {
            this.showError('Passwords do not match');
            return;
        }
        
        if (password.length < 8) {
            this.showError('Password must be at least 8 characters long');
            return;
        }
        
        this.showLoading('Creating account...');
        
        try {
            const attributeList = [
                new AmazonCognitoIdentity.CognitoUserAttribute({
                    Name: 'email',
                    Value: email
                })
            ];
            
            this.userPool.signUp(email, password, attributeList, null, (err, result) => {
                if (err) {
                    this.hideLoading();
                    this.showError(err.message || 'Signup failed');
                } else {
                    this.hideLoading();
                    this.showForm('verification');
                    this.showSuccess('Account created! Please check your email for verification code.');
                }
            });
        } catch (error) {
            this.hideLoading();
            this.showError('Signup failed: ' + error.message);
        }
    }
    
    // Handle verification
    async handleVerification(event) {
        event.preventDefault();
        
        const code = document.getElementById('verification-code').value;
        
        if (!code) {
            this.showError('Please enter verification code');
            return;
        }
        
        this.showLoading('Verifying email...');
        
        try {
            const email = document.getElementById('signup-email').value;
            const userData = {
                Username: email,
                Pool: this.userPool
            };
            
            const cognitoUser = new AmazonCognitoIdentity.CognitoUser(userData);
            
            cognitoUser.confirmRegistration(code, true, (err, result) => {
                if (err) {
                    this.hideLoading();
                    this.showError(err.message || 'Verification failed');
                } else {
                    this.hideLoading();
                    this.showForm('login');
                    this.showSuccess('Email verified! You can now sign in.');
                }
            });
        } catch (error) {
            this.hideLoading();
            this.showError('Verification failed: ' + error.message);
        }
    }
    
    // Logout
    logout() {
        if (this.currentUser) {
            this.currentUser.signOut();
        }
        
        this.currentUser = null;
        this.currentSession = null;
        this.isAuthenticated = false;
        
        // Clear stored data
        localStorage.removeItem(CONFIG.storage.userToken);
        localStorage.removeItem(CONFIG.storage.userInfo);
        
        this.onAuthLogout();
        this.showForm('login');
    }
    
    // Get authentication token
    async getAuthToken() {
        if (!this.isAuthenticated || !this.currentSession) {
            throw new Error('User not authenticated');
        }
        
        return this.currentSession.getIdToken().getJwtToken();
    }
    
    // Get user info
    async getUserInfo() {
        if (!this.isAuthenticated || !this.currentUser) {
            throw new Error('User not authenticated');
        }
        
        return new Promise((resolve, reject) => {
            this.currentUser.getUserAttributes((err, attributes) => {
                if (err) {
                    reject(err);
                } else {
                    const userInfo = {};
                    attributes.forEach(attr => {
                        userInfo[attr.Name] = attr.Value;
                    });
                    resolve(userInfo);
                }
            });
        });
    }
    
    // Show form
    showForm(formName) {
        console.log(`🔄 Showing form: ${formName}`);
        
        const forms = ['login', 'signup', 'verification'];
        const authForms = document.getElementById('auth-forms');
        const uploadInterface = document.getElementById('upload-interface');
        
        console.log('🔍 Found elements:', {
            authForms: !!authForms,
            uploadInterface: !!uploadInterface
        });
        
        forms.forEach(form => {
            const formElement = document.getElementById(`${form}-form`);
            if (formElement) {
                const wasHidden = formElement.classList.contains('hidden');
                formElement.classList.toggle('hidden', form !== formName);
                const isHidden = formElement.classList.contains('hidden');
                console.log(`📝 Form ${form}: ${wasHidden ? 'hidden' : 'visible'} -> ${isHidden ? 'hidden' : 'visible'}`);
            } else {
                console.warn(`⚠️ Form ${form} not found`);
            }
        });
        
        if (formName === 'login' || formName === 'signup') {
            if (authForms) authForms.classList.remove('hidden');
            if (uploadInterface) uploadInterface.classList.add('hidden');
            console.log('👁️ Showing auth forms, hiding upload interface');
        } else {
            if (authForms) authForms.classList.add('hidden');
            console.log('👁️ Hiding auth forms');
        }
        
        console.log(`✅ Form ${formName} display updated`);
    }
    
    // On authentication success
    onAuthSuccess() {
        const authForms = document.getElementById('auth-forms');
        const uploadInterface = document.getElementById('upload-interface');
        const userInfo = document.getElementById('user-info');
        const authButtons = document.getElementById('auth-buttons');
        
        authForms.classList.add('hidden');
        uploadInterface.classList.remove('hidden');
        userInfo.classList.remove('hidden');
        authButtons.classList.add('hidden');
        
        // Update user email display
        this.updateUserDisplay();
        
        // Store authentication data
        this.storeAuthData();
    }
    
    // On authentication logout
    onAuthLogout() {
        const authForms = document.getElementById('auth-forms');
        const uploadInterface = document.getElementById('upload-interface');
        const userInfo = document.getElementById('user-info');
        const authButtons = document.getElementById('auth-buttons');
        
        authForms.classList.remove('hidden');
        uploadInterface.classList.add('hidden');
        userInfo.classList.add('hidden');
        authButtons.classList.remove('hidden');
        
        this.showForm('login');
    }
    
    // Update user display
    async updateUserDisplay() {
        try {
            const userInfo = await this.getUserInfo();
            const userEmail = document.getElementById('user-email');
            if (userEmail && userInfo.email) {
                userEmail.textContent = userInfo.email;
            }
        } catch (error) {
            console.error('Failed to update user display:', error);
        }
    }
    
    // Store authentication data
    storeAuthData() {
        try {
            if (this.currentSession) {
                const token = this.currentSession.getIdToken().getJwtToken();
                localStorage.setItem(CONFIG.storage.userToken, token);
                
                this.getUserInfo().then(userInfo => {
                    localStorage.setItem(CONFIG.storage.userInfo, JSON.stringify(userInfo));
                });
            }
        } catch (error) {
            console.error('Failed to store auth data:', error);
        }
    }
    
    // Show loading
    showLoading(message = 'Loading...') {
        const loading = document.getElementById('loading');
        const loadingMessage = document.getElementById('loading-message');
        
        if (loading && loadingMessage) {
            loadingMessage.textContent = message;
            loading.classList.remove('hidden');
        }
    }
    
    // Hide loading
    hideLoading() {
        const loading = document.getElementById('loading');
        if (loading) {
            loading.classList.add('hidden');
        }
    }
    
    // Show success message
    showSuccess(message) {
        this.showMessage(message, 'success');
    }
    
    // Show error message
    showError(message) {
        this.showMessage(message, 'error');
    }
    
    // Show message
    showMessage(message, type = 'info') {
        const messageDiv = document.createElement('div');
        const bgColor = type === 'success' ? 'bg-green-500' : 
                       type === 'error' ? 'bg-red-500' : 'bg-blue-500';
        
        messageDiv.className = `fixed top-4 right-4 ${bgColor} text-white px-6 py-3 rounded-lg shadow-lg z-50 fade-in`;
        messageDiv.innerHTML = `
            <div class="flex items-center">
                <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-triangle' : 'info-circle'} mr-2"></i>
                <span>${message}</span>
            </div>
        `;
        
        document.body.appendChild(messageDiv);
        
        setTimeout(() => {
            messageDiv.remove();
        }, CONFIG.ui.autoHideMessages);
    }
}

// Initialize authentication manager
let authManager;

document.addEventListener('DOMContentLoaded', () => {
    authManager = new AuthManager();
});

// Export for global access
window.authManager = authManager;
