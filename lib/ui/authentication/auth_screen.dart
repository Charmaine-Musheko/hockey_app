import 'package:flutter/material.dart';
import 'package:hockey_union_app/services/auth_service.dart'; // Adjust path if needed
import 'package:hockey_union_app/utils/app_colors.dart'; // Import your new AppColors

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Text field controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // For user's name
  final TextEditingController _surnameController = TextEditingController(); // For user's surname
  final TextEditingController _roleReasonController = TextEditingController(); // For reason for role

  String error = '';
  bool showSignIn = true; // Toggle between Sign In and Register
  bool _isLoading = false; // To show loading for auth operations

  String? _desiredRole; // To store the user's desired role during registration
  final List<String> _availableRoles = ['Fan', 'Player', 'Coach']; // Roles users can request

  void toggleView() {
    setState(() {
      showSignIn = !showSignIn;
      _formKey.currentState?.reset();
      error = ''; // Clear error message on toggle
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _surnameController.clear();
      _roleReasonController.clear();
      _desiredRole = null; // Clear desired role
    });
  }

  // Function to handle password reset
  Future<void> _forgotPassword() async {
    // Basic validation: Check if email is entered and looks like an email
    if (_emailController.text.isEmpty || !_emailController.text.contains('@') || !_emailController.text.contains('.')) {
      setState(() {
        error = 'Please enter a valid email to reset password.';
      });
      return; // Stop if email is invalid
    }

    setState(() {
      _isLoading = true; // Start loading
      error = ''; // Clear previous errors
    });

    // Call the sendPasswordResetEmail method from AuthService
    String? result = await _auth.sendPasswordResetEmail(_emailController.text);

    setState(() {
      _isLoading = false; // Stop loading
    });

    if (result == null) {
      // Success: Password reset email sent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to ${_emailController.text}. Check your inbox.')),
      );
    } else {
      // Handle errors based on the error code returned from AuthService
      String errorMessage = 'Failed to send password reset email.';
      if (result == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (result == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (result == 'network-request-failed') {
        errorMessage = 'Network error. Please check your connection.';
      }

      setState(() {
        error = errorMessage; // Display the specific error message
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _roleReasonController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen, // Dark green background
      appBar: AppBar(
        title: Text(showSignIn ? 'Sign In' : 'Register'),
        backgroundColor: AppColors.primaryGreen, // Dark green AppBar
        foregroundColor: AppColors.white, // White text/icons
        elevation: 0, // No shadow
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(showSignIn ? Icons.person_add : Icons.login, color: AppColors.white),
            label: Text(showSignIn ? 'Register' : 'Sign In', style: TextStyle(color: AppColors.white)),
            onPressed: () => toggleView(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accentOrange)) // Show loading indicator
          : SingleChildScrollView( // Use SingleChildScrollView for scrollability
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // App Logo/Icon
                Center(
                  child: Icon(
                    Icons.sports_hockey, // Placeholder icon
                    size: 100,
                    color: AppColors.accentOrange,
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    showSignIn ? 'Welcome Back!' : 'Create Your Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white, // White text
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    showSignIn ? 'Sign in to continue' : 'Join the Hockey Union community',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: AppColors.primaryGreen),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: AppColors.primaryGreen),
                  ),
                  obscureText: true,
                  validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                SizedBox(height: 20.0),

                // New fields for Registration
                if (!showSignIn) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person, color: AppColors.primaryGreen),
                    ),
                    validator: (val) => val!.isEmpty ? 'Enter your first name' : null,
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryGreen),
                    ),
                    validator: (val) => val!.isEmpty ? 'Enter your last name' : null,
                  ),
                  SizedBox(height: 20.0),
                  DropdownButtonFormField<String>(
                    value: _desiredRole,
                    decoration: InputDecoration(
                      labelText: 'Desired Role',
                      prefixIcon: Icon(Icons.badge, color: AppColors.primaryGreen),
                    ),
                    items: _availableRoles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _desiredRole = val;
                      });
                    },
                    validator: (val) => val == null ? 'Please select a desired role' : null,
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _roleReasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason for Role (Optional)',
                      prefixIcon: Icon(Icons.info_outline, color: AppColors.primaryGreen),
                    ),
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                  ),
                  SizedBox(height: 30.0),
                ],

                ElevatedButton(
                  child: Text(showSignIn ? 'Sign In' : 'Register'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isLoading = true;
                        error = '';
                      });

                      dynamic result;
                      if (showSignIn) {
                        result = await _auth.signInWithEmailAndPassword(
                            _emailController.text, _passwordController.text);
                        if (result == null) {
                          setState(() {
                            error = 'Could not sign in with those credentials.';
                          });
                        }
                      } else {
                        try {
                          // Pass name, surname, desired role, and reason to signUp
                          result = await _auth.signUpWithEmailAndPassword(
                            _emailController.text,
                            _passwordController.text,
                            _nameController.text,
                            _surnameController.text,
                            _desiredRole!, // _desiredRole is guaranteed non-null by validator
                            _roleReasonController.text,
                          );
                          if (result == null) {
                            setState(() {
                              if (_passwordController.text.length < 6) {
                                error = 'Password must be at least 6 characters.';
                              } else if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
                                error = 'Please enter a valid email address.';
                              } else {
                                error = 'Registration failed. Email may already be in use or other issue.';
                              }
                            });
                          }
                        } catch (e) {
                          setState(() {
                            error = 'An unexpected error occurred: ${e.toString()}';
                          });
                        }
                      }

                      setState(() => _isLoading = false);

                      if (result == null && error == '') {
                        setState(() {
                          error = showSignIn ? 'Could not sign in with those credentials.' : 'Could not register with those credentials.';
                        });
                      }
                    }
                  },
                ),
                SizedBox(height: 12.0),
                TextButton(
                  child: Text('Forgot Password?', style: TextStyle(color: AppColors.accentOrange)),
                  onPressed: showSignIn ? _forgotPassword : null,
                ),
                SizedBox(height: 12.0),
                Text(
                  error,
                  style: TextStyle(color: Colors.red, fontSize: 14.0),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}