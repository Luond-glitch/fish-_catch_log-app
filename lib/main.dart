import 'package:flutter/material.dart';
import 'screens/statistics_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_screen.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/settings_screen.dart';
import '../notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  
  // Corrected: Changed 'firebase' to 'Firebase'
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
 
  runApp(const FishApp());
}

class FishApp extends StatelessWidget {
  const FishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SamakiLog App',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Check if user is already logged in
    final currentUser = _authService.currentUser;

    if (currentUser != null) {
      await _loadUserData(currentUser.uid);
    } else {
      setState(() {
        _isLoading = false;
      });
    }

    // Listen for auth state changes
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        setState(() {
          _user = null;
          _userData = null;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
  try {
    final userData = await _authService.getUserDataByUid(uid);
    setState(() {
      _user = _authService.currentUser;
      _userData = userData;
      _isLoading = false;
    });
  } catch (e) {
    print("⚠️ Error loading user data: $e");
    setState(() {
      _isLoading = false;
    });
    
    // Even if Firestore fails, allow login if auth succeeded
    if (_authService.currentUser != null) {
      setState(() {
        _user = _authService.currentUser;
        _userData = {}; // Empty data, but user can still use app
        _isLoading = false;
      });
    }
  }
}

  Future<void> _login(String username, String boatNumber) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithUsername(username, boatNumber);
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please try again.')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createAccount(
    String username,
    String phoneNumber,
    String boatNumber,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.createAccount(
        username,
        phoneNumber,
        boatNumber,
      );
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account creation failed. Please try again.'),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account creation error: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    if (_user == null || _userData == null) {
      return AuthPage(onLogin: _login, onCreateAccount: _createAccount);
    } else {
      return MainApp(
        username: _userData!['username'],
        boatNumber: _userData!['boatNumber'],
        phoneNumber: _userData!['phoneNumber'] ?? '',
        userId: _user!.uid,
        firestoreService: _firestoreService,
        onLogout: _logout,
      );
    }
  }
}

class AuthPage extends StatefulWidget {
  final Function(String, String) onLogin;
  final Function(String, String, String) onCreateAccount;

  const AuthPage({
    super.key,
    required this.onLogin,
    required this.onCreateAccount,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _boatNumberController = TextEditingController();
  bool _isLoading = false;
  bool _obscureBoatNumber = true;
  bool _isLogin = true;

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await widget.onLogin(
          _usernameController.text,
          _boatNumberController.text,
        );
      } else {
        await widget.onCreateAccount(
          _usernameController.text,
          _phoneNumberController.text,
          _boatNumberController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      // Clear form when switching modes
      if (_isLogin) {
        _phoneNumberController.clear();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _boatNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.orange],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.anchor, size: 60, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        _isLogin ? 'Welcome to Samaki Log' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Username field (used for both login and signup)
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone number field for account creation only
                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _phoneNumberController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number (Optional)',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            // Phone number is optional, so no validation needed
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Boat Number field (used as password)
                      TextFormField(
                        controller: _boatNumberController,
                        obscureText: _obscureBoatNumber,
                        decoration: InputDecoration(
                          labelText: 'Boat Number',
                          hintText: "e.g RAM678",
                          prefixIcon: const Icon(Icons.directions_boat),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureBoatNumber
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureBoatNumber = !_obscureBoatNumber;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your boat number';
                          }
                          if (value.length < 4) {
                            return 'Boat number must be at least 4 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Processing...'),
                          ],
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Colors.deepOrange,
                                ),
                                onPressed: _submit,
                                child: Text(
                                  _isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading ? null : _toggleMode,
                              child: Text(
                                _isLogin
                                    ? 'Need an account? Create one'
                                    : 'Already have an account? Login',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
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

class MainApp extends StatefulWidget {
  final String username;
  final String boatNumber;
  final String userId;
  final String phoneNumber; 
  final FirestoreService firestoreService;
  final VoidCallback onLogout;

  const MainApp({
    super.key,
    required this.username,
    required this.boatNumber,
    required this.userId,
    required this.firestoreService,
    required this.phoneNumber,
    required this.onLogout,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomePage(username: widget.username, boatNumber: widget.boatNumber),
      FishDataPage(
        userId: widget.userId,
        boatNumber: widget.boatNumber,
        firestoreService: widget.firestoreService,
      ),
      FishCatchList(
        userId: widget.userId,
        firestoreService: widget.firestoreService,
      ),
      StatisticsScreen(userId: widget.userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome ${widget.username}👋'),
            Text(
              'Boat: ${widget.boatNumber}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 233, 89, 6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Boat No: ${widget.boatNumber}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Catch'),
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('My Catches'),
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistics'),
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen(
                    username: widget.username,
          boatNumber: widget.boatNumber,
          phoneNumber: widget.phoneNumber,
                  )),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                widget.onLogout();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.deepPurpleAccent,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Catch'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Catches'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String username;
  final String boatNumber;

  const HomePage({super.key, required this.username, required this.boatNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/background.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.anchor, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'SamakiLog Data App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome back $username',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              Text(
                'Boat No. $boatNumber',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FishDataPage(
                        userId: '',
                        boatNumber: boatNumber,
                        firestoreService: FirestoreService(),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Record New Catch',
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

class FishDataPage extends StatefulWidget {
  final String userId;
  final String boatNumber;
  final FirestoreService firestoreService;

  const FishDataPage({
    super.key,
    required this.userId,
    required this.boatNumber,
    required this.firestoreService,
  });

  @override
  State<FishDataPage> createState() => _FishDataPageState();
}

class _FishDataPageState extends State<FishDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _weightController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _catchDate = DateTime.now();
  TimeOfDay _catchTime = TimeOfDay.now();
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _catchDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _catchDate) {
      setState(() {
        _catchDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _catchTime,
    );
    if (picked != null && picked != _catchTime) {
      setState(() {
        _catchTime = picked;
      });
    }
  }

  Future<void> _submitCatch() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await widget.firestoreService.addFishCatch(
          userId: widget.userId,
          species: _speciesController.text,
          weight: double.parse(_weightController.text),
          location: _locationController.text,
          date: DateTime(
            _catchDate.year,
            _catchDate.month,
            _catchDate.day,
            _catchTime.hour,
            _catchTime.minute,
          ),
          boatNumber: widget.boatNumber,
          notes: _notesController.text,
        );

        _handleSuccess();
      } catch (e) {
        _handleError(e);
      }
    }
  }

  void _handleSuccess() {
    // Check if widget is still mounted before updating state
    if (!mounted) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catch recorded successfully!')),
    );

    // Clear the form
    _formKey.currentState!.reset();
    setState(() {
      _catchDate = DateTime.now();
      _catchTime = TimeOfDay.now();
      _isSubmitting = false;
    });
  }

  void _handleError(Object e) {
    // Check if widget is still mounted before showing error
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error recording catch: $e')));
    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _weightController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record Fish Catch',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _speciesController,
              decoration: InputDecoration(
                labelText: 'Fish Species',
                prefixIcon: const Icon(Icons.pets, color: Colors.deepOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepOrange),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.orange.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the fish species';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: const Icon(Icons.scale, color: Colors.deepOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepOrange),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.orange.shade50,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the weight';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Fishing Location',
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Colors.deepOrange,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepOrange),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.orange.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Colors.deepOrange,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepOrange),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        filled: true,
                        fillColor: Colors.orange.shade50,
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(_catchDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Time',
                        prefixIcon: const Icon(
                          Icons.access_time,
                          color: Colors.deepOrange,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepOrange),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        filled: true,
                        fillColor: Colors.orange.shade50,
                      ),
                      child: Text(_catchTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: const Icon(Icons.note, color: Colors.deepOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrange),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                filled: true,
                fillColor: Colors.orange.shade50,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Center(
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _submitCatch,
                      child: const Text(
                        'Submit Catch',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class FishCatchList extends StatelessWidget {
  final String userId;
  final FirestoreService firestoreService;

  const FishCatchList({
    super.key,
    required this.userId,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getUserCatches(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No catches recorded yet',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final fishCatch = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8.0),
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.pets,
                  size: 40,
                  color: Colors.deepOrange,
                ),
                title: Text(
                  fishCatch['species'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Weight: ${fishCatch['weight']} kg'),
                    Text('Location: ${fishCatch['location']}'),
                    Text(
                      'Date: ${DateFormat('yyyy-MM-dd').format(fishCatch['date'].toDate())}',
                    ),
                    if (fishCatch['notes'] != null &&
                        fishCatch['notes'].isNotEmpty)
                      Text('Notes: ${fishCatch['notes']}'),
                    Text('Boat No.: ${fishCatch['boatNumber']}'),
                  ],
                ),
                trailing: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
