import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'splash_screen.dart';

void main() {
  runApp(const FishApp());
}

//const FishApp());
class FishApp extends StatelessWidget {
  const FishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catchlog App',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
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
  final _usernameController = TextEditingController();
  final _boatNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscureBoatNumber = true;

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 0));

    setState(() {
      _isLoading = false;
    });

    widget.onLogin(_usernameController.text, _boatNumberController.text);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _boatNumberController.dispose();
    _phoneNumberController.dispose();
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
                        _isLogin ? 'Welcome Back' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                          return null;
                        },
                      ),
                      if (!_isLogin) const SizedBox(height: 16),
                      if (!_isLogin)
                        TextFormField(
                          controller: _phoneNumberController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: "e.g 0703...",
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Colors.deepOrange,
                            ),
                            onPressed: _submit,
                            child: Text(
                              _isLogin ? 'LOGIN' : 'REGISTER',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? 'Create new account'
                              : 'Already have an account? Login',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
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
      HomePage(username: widget.username, boatNumber: widget.boatNumber),
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
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Boat No.: ${widget.boatNumber}',
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Catch'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Catches'),
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
            color: Colors.black.withOpacity(0.6),
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
                        catches: const [],
                        boatNumber: boatNumber,
                        onAddCatch: (_) {},
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
              child: ElevatedButton(
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
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(
                    Icons.pets,
                    size: 40,
                    color: Colors.deepOrange,
                  ),
                  title: Text(
                    fishCatch.species,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
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
