import 'package:flutter/material.dart';
import 'package:hockey_union_app/services/auth_service.dart';
import 'package:hockey_union_app/ui/home_screen.dart';
import 'package:hockey_union_app/utils/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _roleReasonController = TextEditingController();

  String _selectedRole = 'Fan';
  bool _isLogin = true;
  bool _isLoading = false;
  String? errorMessage;

  File? _pickedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImageFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

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
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        errorMessage = null;
      });

      String? currentErrorMessage;
      User? user;

      try {
        if (_isLogin) {
          // Login flow
          user = await _auth.signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
          if (user == null) {
            currentErrorMessage = "Authentication failed. Please check your credentials.";
          }
        } else {
          // Registration flow
          user = await _auth.signUpWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
            _selectedRole,
            _roleReasonController.text.trim(),
            _pickedImage,
          );
          if (user == null) {
            currentErrorMessage = "Registration failed. Please check your details or try again.";
          }
        }

        if (user != null) {
          if (_isLogin) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomeScreen(userId: user!.uid)),
              );
            }
          } else {
            // After successful registration, switch to login mode and prefill email
            currentErrorMessage = "Registration successful! Please log in.";
            if (mounted) {
              setState(() {
                _isLogin = true;
                _emailController.text = user?.email ?? '';
                _passwordController.clear();
                _firstNameController.clear();
                _lastNameController.clear();
                _roleReasonController.clear();
                _pickedImage = null;
                _selectedRole = 'Fan';
              });
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        currentErrorMessage = e.message;
      } catch (e) {
        currentErrorMessage = "An unexpected error occurred: ${e.toString()}";
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            errorMessage = currentErrorMessage;
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

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty || !_emailController.text.trim().contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email to reset password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    String? result = await _auth.sendPasswordResetEmail(_emailController.text.trim());

    setState(() {
      _isLoading = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset email sent to ${_emailController.text.trim()}. Check your inbox.',
          ),
        ),
      );
    } else {
      String displayErrorMessage = 'Failed to send password reset email.';
      if (result == 'user-not-found') {
        displayErrorMessage = 'No user found for that email.';
      } else if (result == 'invalid-email') {
        displayErrorMessage = 'The email address is not valid.';
      } else if (result == 'network-request-failed') {
        displayErrorMessage = 'Network error. Please check your connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayErrorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        title: Text(_isLogin ? 'Sign In' : 'Register'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: Icon(_isLogin ? Icons.person_add : Icons.login, color: AppColors.white),
            label: Text(_isLogin ? 'Register' : 'Sign In', style: TextStyle(color: AppColors.white)),
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
                _formKey.currentState?.reset();
                _emailController.clear();
                _passwordController.clear();
                _firstNameController.clear();
                _lastNameController.clear();
                _roleReasonController.clear();
                _pickedImage = null;
                _selectedRole = 'Fan';
                errorMessage = null;
              });
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/IMG_7434.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isLogin ? 'Welcome Back!' : 'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Image picker for signup only
                    if (!_isLogin)
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.secondaryGreen,
                          backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                          child: _pickedImage == null
                              ? Icon(Icons.add_a_photo, size: 50, color: AppColors.white.withOpacity(0.8))
                              : null,
                        ),
                      ),
                    if (!_isLogin) const SizedBox(height: 20),

                    // First Name signup
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
                    if (!_isLogin) const SizedBox(height: 16),

                    // Last Name signup
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
                    if (!_isLogin) const SizedBox(height: 16),

                    // Email field
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
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: AppColors.primaryGreen),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Role dropdown for signup only
                    if (!_isLogin)
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Select Role',
                          prefixIcon: Icon(Icons.person_pin, color: AppColors.primaryGreen),
                        ),
                        items: ['Player', 'Coach', 'Fan', 'Admin']
                            .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                            });
                          }
                        },
                      ),
                    if (!_isLogin) const SizedBox(height: 16),

                    // Reason field for certain roles only (example: Player or Coach)
                    if (!_isLogin && (_selectedRole == 'Player' || _selectedRole == 'Coach'))
                      TextFormField(
                        controller: _roleReasonController,
                        decoration: InputDecoration(
                          labelText: 'Reason for Role',
                          prefixIcon: Icon(Icons.info_outline, color: AppColors.primaryGreen),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if ((_selectedRole == 'Player' || _selectedRole == 'Coach') &&
                              (value == null || value.isEmpty)) {
                            return 'Please explain why you want this role.';
                          }
                          return null;
                        },
                      ),
                    if (!_isLogin && (_selectedRole == 'Player' || _selectedRole == 'Coach'))
                      const SizedBox(height: 16),

                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _submitAuthForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(_isLogin ? 'Sign In' : 'Register'),
                      ),

                    if (_isLogin)
                      TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot Password?'),
                      ),

                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
