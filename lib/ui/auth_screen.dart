import 'package:flutter/material.dart';
import 'package:hockey_union_app/services/auth_service.dart'; // Adjust path if needed

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

// ... (existing imports and class definition)

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // text field state
  String email = '';
  String password = '';
  String error = ''; // This will now hold more specific error messages
  bool showSignIn = true; // Toggle between Sign In and Register

  void toggleView() {
    setState(() => showSignIn = !showSignIn);
    _formKey.currentState?.reset();
    error = ''; // Clear error message on toggle
    email = ''; // Clear email on toggle
    password = ''; // Clear password on toggle
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showSignIn ? 'Sign In' : 'Register'),
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(showSignIn ? Icons.person_add : Icons.login, color: Colors.white),
            label: Text(showSignIn ? 'Register' : 'Sign In', style: TextStyle(color: Colors.white)),
            onPressed: () => toggleView(),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  if (_formKey.currentState!.validate()) {
                    // Clear previous error before attempting auth
                    setState(() => error = '');

                    dynamic result;
                    if (showSignIn) {
                      result = await _auth.signInWithEmailAndPassword(email, password);
                      if (result == null) {
                        // Handle Sign In specific errors here if needed,
                        // based on the error code returned from AuthService (if you chose that option)
                        // For now, it will show the generic "Could not sign in" message below
                      }
                    } else { // Register
                      try {
                        result = await _auth.signUpWithEmailAndPassword(email, password);
                        if (result == null) {
                          // This means an error occurred in AuthService, likely FirebaseAuthException
                          // We can try to infer the error based on common cases or rely on Firebase's printout
                          setState(() {
                            // Provide more specific messages for common registration errors
                            if (password.length < 6) {
                              error = 'Password must be at least 6 characters.';
                            } else if (!email.contains('@') || !email.contains('.')) { // Basic email format check
                              error = 'Please enter a valid email address.';
                            } else {
                              // This is a fallback for other errors, like email already in use
                              // Or you could pass specific error codes from AuthService
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

                    // If result is still null after attempting sign in or register
                    if (result == null && error == '') {
                      // This might catch cases where AuthService returned null but we didn't set a specific error message yet
                      setState(() {
                        error = showSignIn ? 'Could not sign in with those credentials.' : 'Could not register with those credentials.';
                      });
                    }

                    // If result is NOT null, it means success, Wrapper handles navigation
                  }
                },
              ),
              SizedBox(height: 12.0),
              Text(
                error,
                style: TextStyle(color: Colors.red, fontSize: 14.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
