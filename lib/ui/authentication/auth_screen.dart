import 'package:flutter/material.dart';
import 'package:hockey_union_app/services/auth_service.dart'; // Adjust path if needed

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // text field state
  String email = '';
  String password = '';
  String error = '';
  bool showSignIn = true; // Toggle between Sign In and Register
  bool _isLoading = false; // To show loading for auth operations

  void toggleView() {
    setState(() => showSignIn = !showSignIn);
    _formKey.currentState?.reset();
    error = ''; // Clear error message on toggle
    email = ''; // Clear email on toggle
    password = ''; // Clear password on toggle
  }

  // Function to handle password reset
  Future<void> _forgotPassword() async {
    // Basic validation: Check if email is entered and looks like an email
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
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
    String? result = await _auth.sendPasswordResetEmail(email);

    setState(() {
      _isLoading = false; // Stop loading
    });

    if (result == null) {
      // Success: Password reset email sent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email. Check your inbox.')),
      );
      // Optionally clear the email field after success
      // setState(() => email = '');
      // _emailController.clear(); // If you were using a controller for email
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
      // You can add more specific error codes here from Firebase Auth documentation

      setState(() {
        error = errorMessage; // Display the specific error message
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showSignIn ? 'Sign In' : 'Register'),
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(showSignIn ? Icons.person_add : Icons.login, color: Colors.blue),
            label: Text(showSignIn ? 'Register' : 'Sign In', style: TextStyle(color: Colors.black)),
            onPressed: () => toggleView(),
          ),
        ],
      ),
      // Show loading indicator or the form based on _isLoading
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator when _isLoading is true
          : Container(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center the form vertically
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              SizedBox(height: 20.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                // Keep the basic validator here, but Firebase Auth provides the ultimate check
                validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                child: Text(showSignIn ? 'Sign In' : 'Register'),
                onPressed: () async {
                  // Validate the form fields
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true; // Start loading
                      error = ''; // Clear previous errors
                    });

                    dynamic result;
                    if (showSignIn) {
                      // Attempt Sign In
                      result = await _auth.signInWithEmailAndPassword(email, password);
                      if (result == null) {
                        // If signInWithEmailAndPassword returned null, it means an error occurred
                        // The specific error message is printed in AuthService,
                        // but we'll show a generic sign-in error here.
                        setState(() {
                          error = 'Could not sign in with those credentials.';
                        });
                      }
                    } else { // Attempt Register
                      try {
                        result = await _auth.signUpWithEmailAndPassword(email, password);
                        if (result == null) {
                          // If signUpWithEmailAndPassword returned null, an error occurred.
                          // AuthService prints the specific Firebase Auth error code.
                          // We can show a generic registration error or refine based on common codes.
                          setState(() {
                            // Basic checks for common registration issues if result is null
                            if (password.length < 6) {
                              error = 'Password must be at least 6 characters.';
                            } else if (!email.contains('@') || !email.contains('.')) {
                              error = 'Please enter a valid email address.';
                            } else {
                              // Fallback for other errors like email already in use
                              error = 'Registration failed. Email may already be in use or other issue.';
                            }
                          });
                        }
                      } catch (e) {
                        // Catch any unexpected errors during the async call
                        setState(() {
                          error = 'An unexpected error occurred: ${e.toString()}';
                        });
                      }
                    }

                    setState(() => _isLoading = false); // Stop loading

                    // If result is NOT null, it means success, Wrapper handles navigation
                    // If result IS null, the error message is already set above
                  }
                },
              ),
              SizedBox(height: 12.0),
              // Add the Forgot Password button/text
              TextButton(
                child: Text('Forgot Password?'),
                onPressed: showSignIn ? _forgotPassword : null, // Only enable if in Sign In view
              ),
              SizedBox(height: 12.0),
              Text(
                error,
                style: TextStyle(color: Colors.red, fontSize: 14.0),
                textAlign: TextAlign.center, // Center the error text
              ),
            ],
          ),
        ),
      ),
    );
  }
}
