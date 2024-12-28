import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:watt_way/login_page.dart';
import 'package:watt_way/welcome_page.dart';

class UserProfileWidget extends StatefulWidget {
  final int? userId;

  const UserProfileWidget({super.key, required this.userId});

  @override
  _UserProfileWidgetState createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends State<UserProfileWidget> {
  late Future<Map<String, dynamic>> _userData;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isEditingUsername = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  Future<Map<String, dynamic>> fetchUserData() async {
    final apiUrl = dotenv.env['API_URL'];
    final response = await http.get(
      Uri.parse('$apiUrl/api/user/${widget.userId}'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user data');
    }
  }

  int calculateDaysWithUs(String createdAt) {
    final createdDate = DateTime.parse(createdAt);
    final currentDate = DateTime.now();
    return currentDate.difference(createdDate).inDays;
  }

  Future<bool> _saveChanges(String field, String newValue) async {
    if (field == 'password' && newValue.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 8 characters long')),
      );
      return false;
    } else if (field == 'email' && !newValue.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email address')),
      );
      return false;
    } else if (field == 'username' && newValue.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Username must be less than 50 characters long')),
      );
      return false;
    }

    final apiUrl = dotenv.env['API_URL'];
    final response = await http.put(
      Uri.parse('$apiUrl/api/user/${widget.userId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({field: newValue}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );

      setState(() {
        if (field == 'username') {
          _usernameController.text = newValue;
        } else if (field == 'email') {
          _emailController.text = newValue;
        }
      });

      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save changes')),
      );
      return false;
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });
    final apiUrl = dotenv.env['API_URL'];
    final response = await http.delete(
      Uri.parse('$apiUrl/api/user/${widget.userId}'),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    setState(() {
      if (token != null && token.isNotEmpty) {
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
      }
    });

    if (_isLoggedIn) {
      _userData = fetchUserData();
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange,
              Colors.green,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _isLoggedIn
              ? FutureBuilder<Map<String, dynamic>>(
                  future: _userData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      final user = snapshot.data!;

                      if (_usernameController.text.isEmpty) {
                        _usernameController.text = user['username'];
                      }
                      if (_emailController.text.isEmpty) {
                        _emailController.text = user['email'];
                      }

                      final daysWithUs =
                          calculateDaysWithUs(user['created_at']);

                      return SingleChildScrollView(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'User Profile',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hi ${_usernameController.text}, you are with us for $daysWithUs days!',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _usernameController,
                                        enabled: _isEditingUsername,
                                        decoration: InputDecoration(
                                          labelText: 'Username',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        _isEditingUsername
                                            ? Icons.save_outlined
                                            : Icons.edit_outlined,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        if (_isEditingUsername) {
                                          bool success = await _saveChanges(
                                              'username',
                                              _usernameController.text.trim());
                                          if (!success) {
                                            return;
                                          }
                                        }
                                        setState(() {
                                          _isEditingUsername =
                                              !_isEditingUsername;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _emailController,
                                        enabled: _isEditingEmail,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        _isEditingEmail
                                            ? Icons.save_outlined
                                            : Icons.edit_outlined,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        if (_isEditingEmail) {
                                          bool success = await _saveChanges(
                                              'email',
                                              _emailController.text.trim());
                                          if (!success) {
                                            return;
                                          }
                                        }
                                        setState(() {
                                          _isEditingEmail = !_isEditingEmail;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _passwordController,
                                        enabled: _isEditingPassword,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        _isEditingPassword
                                            ? Icons.save_outlined
                                            : Icons.edit_outlined,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        if (_isEditingPassword) {
                                          bool success = await _saveChanges(
                                              'password',
                                              _passwordController.text.trim());
                                          if (!success) {
                                            return;
                                          }
                                        }
                                        setState(() {
                                          _isEditingPassword =
                                              !_isEditingPassword;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.8,
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            bool? confirmDelete =
                                                await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Delete Account'),
                                                  content: const Text(
                                                      'Are you sure you want to delete your account? This action cannot be undone.'),
                                                  actions: <Widget>[
                                                    OutlinedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(false);
                                                      },
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 32,
                                                          vertical: 12,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        side: const BorderSide(
                                                          color: Colors.orange,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.orange),
                                                      ),
                                                    ),
                                                    OutlinedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(true);
                                                      },
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 32,
                                                          vertical: 12,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        side: const BorderSide(
                                                          color: Colors.green,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Yes',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.green),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (confirmDelete == true) {
                                              _deleteAccount();
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            side: const BorderSide(
                                              color: Colors.red,
                                              width: 2,
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const CircularProgressIndicator(
                                                  color: Colors.green,
                                                )
                                              : const Text(
                                                  'Delete Account',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.8,
                                        child: OutlinedButton(
                                          onPressed: _logout,
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            side: const BorderSide(
                                              color: Colors.green,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Text(
                                            'Logout',
                                            style:
                                                TextStyle(color: Colors.green),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const Center(child: Text('No data available'));
                    }
                  },
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'You should log in first to see your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
