import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hockey_union_app/services/auth_service.dart';
import 'package:hockey_union_app/ui/home_screen.dart';
import 'package:hockey_union_app/utils/app_colors.dart';
import 'package:image_picker/image_picker.dart'; // Import for image picking
import 'dart:io'; // Required for File class

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  // Text editing controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _roleReasonController = TextEditingController(); // For the role reason
  String _selectedRole = 'Fan'; // Default role for registration

  bool _isLogin = true; // State to switch between login and registration
  bool _isLoading = false; // State for loading indicator

  File? _pickedImage; // To store the picked image file

  // Function to pick an image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImageFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedImageFile != null) {
      setState(() {
        _pickedImage = File(pickedImageFile.path);
      });
    }
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _roleReasonController.dispose();
    super.dispose();
  }

  void _submitAuthForm() async {
    // Ensure the widget is still mounted before proceeding with setState
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      String? errorMessage;
      User? user; // Using the Firebase User type for clarity

      try {
        if (_isLogin) {
          // Login logic
          user = await _auth.signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          // Registration logic
          user = await _auth.signUpWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
            _selectedRole, // Pass the selected role
            _roleReasonController.text.trim(), // Pass the role reason
            _pickedImage, // Pass the picked image
          );
        }

        if (user != null) {
          print('User ${user.uid} logged in with role: $_selectedRole'); // Log the user and role

          // NavigatAe to HomeScreen on successful login/registration
          // Ensure we don't try to navigate if the context is no longer valid
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomeScreen(userId: user!.uid)),
            );
          }
        } else {
          // Handle case where user is null (e.g., authentication failed without an explicit exception)
          errorMessage = "Authentication failed. Please check your credentials.";
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase specific errors
        errorMessage = e.message;
        print("FirebaseAuthException: ${e.code} - ${e.message}");
      } catch (e) {
        // Handle other general errors
        errorMessage = "An unexpected error occurred: ${e.toString()}";
        print("General Error: ${e.toString()}");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // Hide loading indicator
          });
          if (errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage!)),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- ADDED LOGO HERE ---
                      Image.asset(
                        'assets/images/IMG_7434.png', // Path to your logo
                        height: 120, // Adjust height as needed
                        fit: BoxFit.contain, // Ensures the entire image is visible within its bounds
                      ),
                      const SizedBox(height: 20), // Spacing below the logo

                      Text(
                        _isLogin ? 'Welcome Back!' : 'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 20),
                      if (!_isLogin)
                        GestureDetector(
                          onTap: _pickImage, // Call image picker on tap
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.secondaryGreen,
                            backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                            child: _pickedImage == null
                                ? Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: AppColors.white.withOpacity(0.8),
                            )
                                : null,
                          ),
                        ),
                      if (!_isLogin) SizedBox(height: 20),
                      if (!_isLogin)
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icon(Icons.person, color: AppColors.primaryGreen),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name.';
                            }
                            return null;
                          },
                        ),
                      if (!_isLogin) SizedBox(height: 16),
                      if (!_isLogin)
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryGreen),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name.';
                            }
                            return null;
                          },
                        ),
                      if (!_isLogin) SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: AppColors.primaryGreen),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock, color: AppColors.primaryGreen),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                      ),
                      if (!_isLogin) SizedBox(height: 16),
                      if (!_isLogin)
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Request Role',
                            prefixIcon: Icon(Icons.person_add, color: AppColors.primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: <String>['Fan', 'Player', 'Coach']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedRole = newValue!;
                            });
                          },
                        ),
                      if (!_isLogin && _selectedRole != 'Fan') SizedBox(height: 16),
                      if (!_isLogin && _selectedRole != 'Fan')
                        TextFormField(
                          controller: _roleReasonController,
                          decoration: InputDecoration(
                            labelText: 'Reason for Role Request (e.g., "I am a professional player")',
                            prefixIcon: Icon(Icons.info_outline, color: AppColors.primaryGreen),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please provide a reason for your role request.';
                            }
                            return null;
                          },
                        ),
                      SizedBox(height: 20),
                      _isLoading
                          ? CircularProgressIndicator(color: AppColors.accentOrange)
                          : ElevatedButton(
                        onPressed: _submitAuthForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentOrange,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: Text(
                          _isLogin ? 'Login' : 'Sign Up',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin; // Toggle between login and registration
                            _formKey.currentState?.reset(); // Clear form fields
                            _emailController.clear();
                            _passwordController.clear();
                            _firstNameController.clear();
                            _lastNameController.clear();
                            _roleReasonController.clear();
                            _pickedImage = null; // Clear picked image on toggle
                            // Add this line to reset the selected role
                            _selectedRole = 'Fan';
                          });
                        },
                        child: Text(
                          _isLogin
                              ? 'Don\'t have an account? Sign Up'
                              : 'Already have an account? Login',
                          style: TextStyle(color: AppColors.primaryGreen),
                        ),
                      ),
                      if (_isLogin) // Only show forgot password on login screen
                        TextButton(
                          onPressed: () async {
                            // Implement forgot password logic here
                            final String email = _emailController.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please enter a valid email to reset password.')),
                              );
                              return;
                            }
                            setState(() {
                              _isLoading = true;
                            });
                            String? error = await _auth.sendPasswordResetEmail(email);
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                              if (error == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Password reset email sent to $email')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to send reset email: $error')),
                                );
                              }
                            }
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: AppColors.accentOrange),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}