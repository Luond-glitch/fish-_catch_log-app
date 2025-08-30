import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_service.dart';
import '/models/time.dart';

class SettingsScreen extends StatefulWidget {
  final String username;
  final String boatNumber;
  final String phoneNumber;

  const SettingsScreen({
    super.key,
    required this.username,
    required this.boatNumber,
    required this.phoneNumber,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _boatNumberController;
  late TextEditingController _phoneNumberController;

  bool _notificationsEnabled = true;
  bool _autoBackupEnabled = false;
  bool _locationServicesEnabled = true;
  bool _catchRemindersEnabled = false;
  bool _weeklyReportsEnabled = false;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _boatNumberController = TextEditingController(text: widget.boatNumber);
    _phoneNumberController = TextEditingController(text: widget.phoneNumber);
    _loadSettings();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications') ?? true;
        _autoBackupEnabled = prefs.getBool('autoBackup') ?? false;
        _locationServicesEnabled = prefs.getBool('locationServices') ?? true;
        _catchRemindersEnabled = prefs.getBool('catchReminders') ?? false;
        _weeklyReportsEnabled = prefs.getBool('weeklyReports') ?? false;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
        return;
      }
    } else {
      await _notificationService.cancelAllNotifications();
    }

    if (mounted) {
      setState(() => _notificationsEnabled = value);
    }
    _saveSetting('notifications', value);

    if (!value && mounted) {
      setState(() {
        _catchRemindersEnabled = false;
        _weeklyReportsEnabled = false;
      });
      _saveSetting('catchReminders', false);
      _saveSetting('weeklyReports', false);
    }

    // Show visual feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _toggleCatchReminders(bool value) async {
    if (value && !_notificationsEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enable notifications first')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _catchRemindersEnabled = value);
    }
    _saveSetting('catchReminders', value);

    if (value) {
      await _notificationService.scheduleDailyReminder(
        id: 1,
        title: 'Catch Reminder 🎣',
        body: 'Don\'t forget to log your catches today!',
        time: const Time(hour: 8, minute: 0),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily catch reminders enabled')),
        );
      }
    } else {
      await _notificationService.cancelNotification(1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily catch reminders disabled')),
        );
      }
    }
  }

  Future<void> _toggleWeeklyReports(bool value) async {
    if (value && !_notificationsEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enable notifications first')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _weeklyReportsEnabled = value);
    }
    _saveSetting('weeklyReports', value);

    if (value) {
      await _notificationService.showNotification(
        id: 2,
        title: 'Weekly Report Ready',
        body: 'Your weekly fishing report is available!',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly reports enabled')),
        );
      }
    } else {
      await _notificationService.cancelNotification(2);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly reports disabled')),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepOrange,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: value, 
        onChanged: onChanged,
        activeColor: Colors.deepOrange,
      ),
      onTap: () => onChanged(!value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Profile'),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.deepOrange),
            title: const Text('Edit Profile'),
            subtitle: Text('Username: ${widget.username}'),
            onTap: _showEditProfileDialog,
          ),
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Enable Notifications',
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          _buildSwitchTile(
            icon: Icons.remember_me,
            title: 'Catch Reminders',
            subtitle: 'Daily reminders to log your catches',
            value: _catchRemindersEnabled,
            onChanged: _toggleCatchReminders,
          ),
          _buildSwitchTile(
            icon: Icons.analytics,
            title: 'Weekly Reports',
            subtitle: 'Weekly fishing performance reports',
            value: _weeklyReportsEnabled,
            onChanged: _toggleWeeklyReports,
          ),
          _buildSectionHeader('Data & Storage'),
          _buildSwitchTile(
            icon: Icons.backup,
            title: 'Auto Backup',
            subtitle: 'Backup data automatically',
            value: _autoBackupEnabled,
            onChanged: (value) {
              setState(() => _autoBackupEnabled = value);
              _saveSetting('autoBackup', value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? 'Auto backup enabled' : 'Auto backup disabled'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          _buildSectionHeader('Location'),
          _buildSwitchTile(
            icon: Icons.location_on,
            title: 'Location Services',
            subtitle: 'Enable location tracking for catches',
            value: _locationServicesEnabled,
            onChanged: (value) {
              setState(() => _locationServicesEnabled = value);
              _saveSetting('locationServices', value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? 'Location services enabled' : 'Location services disabled'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          _buildSectionHeader('Help & Support'),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.deepOrange),
            title: const Text('Help & Support'),
            onTap: () {
              _showHelpSupport();
              // Visual feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening help section'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.deepOrange),
            title: const Text('About App'),
            onTap: () {
              _showAboutApp();
              // Visual feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Showing app information'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          _buildSectionHeader('App Information'),
          const ListTile(
            leading: Icon(Icons.apps, color: Colors.grey),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.deepOrange),
            title: const Text('Privacy Policy'),
            onTap: () {
              // Visual feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening privacy policy'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.deepOrange),
            title: const Text('Terms of Service'),
            onTap: () {
              // Visual feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening terms of service'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _boatNumberController,
                decoration: const InputDecoration(labelText: 'Boat Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Save profile changes logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text('Contact support at support@samakilog.com\n\nWe\'re here to help you with any questions or issues.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About SamakiLog'),
          content: const Text('SamakiLog App v1.0.0\n\nTrack your fishing catches and statistics. Built for fishermen by fishermen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  } 
}