import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'bacground.dart'; 

void main() {
  runApp(const FishApp());
}

class FishApp extends StatelessWidget {
  const FishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catchlog App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:const AuthWrapper(), 
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
  bool _isLoggedIn = false;
  String _username = '';
  String _boatNumber = '';

  void _login(String username, String boatNumber) {
    setState(() {
      _isLoggedIn = true;
      _username = username;
      _boatNumber = boatNumber;
    });
   BlurredBackgroundApp();
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _username = '';
      _boatNumber = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn
        ? MainApp(
            username: _username,
            boatNumber: _boatNumber,
            onLogout: _logout,
          )
        : AuthPage(onLogin: _login);
  }
}

class AuthPage extends StatefulWidget {
  final Function(String, String) onLogin;

  const AuthPage({super.key, required this.onLogin});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _boatNumberController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (_isLogin) {
      // Login logic
      widget.onLogin(
          _usernameController.text, _boatNumberController.text);
    } else {
      // Signup logic
      widget.onLogin(_usernameController.text, _boatNumberController.text);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _boatNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center( child: Text(_isLogin ? 'Welcome Back again' : 'Sing Up ',
        style: TextStyle(
          color: const Color.fromARGB(255, 10, 135, 236),
          fontSize: 34,
          fontWeight: FontWeight.w200,
        ), 
        ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isLogin)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _boatNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Boat Number',
                    prefixIcon: Icon(Icons.directions_boat),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your boat number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Login' : 'Register'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(_isLogin
                      ? 'Create new fisherman account'
                      : 'I already have an account'),
                ),
              ],
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
  final VoidCallback onLogout;

  const MainApp({
    super.key,
    required this.username,
    required this.boatNumber,
    required this.onLogout,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  final List<FishCatch> _catches = [];

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomePage(
        username: widget.username,
        boatNumber: widget.boatNumber,
      ),
      FishDataPage(
        catches: _catches,
        boatNumber: widget.boatNumber,
        onAddCatch: (newCatch) {
          setState(() {
            _catches.add(newCatch);
          });
        },
      ),
      FishCatchList(catches: _catches),
    ]);
    BlurredBackgroundApp();
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
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 233, 89, 6),
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
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  Text(
                    'Boat No.: ${widget.boatNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Catch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My Catches',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String username;
  final String boatNumber;

  const HomePage({
    super.key,
    required this.username,
    required this.boatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.anchor, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Fisherman Data App',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Welcome back $username',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          Text(
            'Boat No.: $boatNumber',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
        onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FishDataPage(
                    catches: const [],
                    boatNumber: boatNumber,
                    onAddCatch: (_) {},
                  ),
                ),
              );
            },
            child: const Text('Record New Catch'),

          ),
        ],
      ),
    );
  }
}

class FishDataPage extends StatefulWidget {
  final List<FishCatch> catches;
  final String boatNumber;
  final Function(FishCatch) onAddCatch;

  const FishDataPage({
    super.key,
    required this.catches,
    required this.boatNumber,
    required this.onAddCatch,
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

  void _submitCatch() {
    if (_formKey.currentState!.validate()) {
      final newCatch = FishCatch(
        species: _speciesController.text,
        weight: double.parse(_weightController.text),
        location: _locationController.text,
        date: _catchDate,
        time: _catchTime,
        notes: _notesController.text,
        boatNumber: widget.boatNumber,
      );

      widget.onAddCatch(newCatch);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catch recorded successfully!')),
      );

      // Clear the form
      _formKey.currentState!.reset();
      setState(() {
        _catchDate = DateTime.now();
        _catchTime = TimeOfDay.now();
      });
    }
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
              decoration: const InputDecoration(
                labelText: 'Fish Species',
                prefixIcon: Icon(Icons.pets),
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
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.scale),
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
              decoration: const InputDecoration(
                labelText: 'Fishing Location',
                prefixIcon: Icon(Icons.location_on),
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
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(_catchDate),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _catchTime.format(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submitCatch,
                child: const Text('Submit Catch'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FishCatchList extends StatelessWidget {
  final List<FishCatch> catches;

  const FishCatchList({super.key, required this.catches});

  @override
  Widget build(BuildContext context) {
    return catches.isEmpty
        ? const Center(
            child: Text(
              'No catches recorded yet',
              style: TextStyle(fontSize: 18),
            ),
          )
        : ListView.builder(
            itemCount: catches.length,
            itemBuilder: (context, index) {
              final fishCatch = catches[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const Icon(Icons.pets, size: 40),
                  title: Text(
                    fishCatch.species,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weight: ${fishCatch.weight} kg'),
                      Text('Location: ${fishCatch.location}'),
                      Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(fishCatch.date)} at ${fishCatch.time.format(context)}',
                      ),
                      if (fishCatch.notes.isNotEmpty)
                        Text('Notes: ${fishCatch.notes}'),
                      Text('Boat No.: ${fishCatch.boatNumber}'),
                    ],
                  ),
                  trailing: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
  }
}

class FishCatch {
  final String species;
  final double weight;
  final String location;
  final DateTime date;
  final TimeOfDay time;
  final String notes;
  final String boatNumber;

  FishCatch({
    required this.species,
    required this.weight,
    required this.location,
    required this.date,
    required this.time,
    required this.notes,
    required this.boatNumber,
  });
}