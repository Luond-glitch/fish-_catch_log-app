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
  String _weightUnit = 'kg';
  String _temperatureUnit = 'Celsius';
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
        _weightUnit = prefs.getString('weightUnit') ?? 'kg';
        _temperatureUnit = prefs.getString('temperatureUnit') ?? 'Celsius';
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
        time:const Time(hour: 8, minute: 0),
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
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Profile'),
          ListTile(
            leading: const Icon(Icons.person),
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
          ListTile(
            leading: const Icon(Icons.notification_add),
            title: const Text('Notification Settings'),
            subtitle: Text(
              'Reminders: ${_catchRemindersEnabled ? 'On' : 'Off'}, '
              'Reports: ${_weeklyReportsEnabled ? 'On' : 'Off'}',
            ),
            onTap: _showNotificationSettings,
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
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Data & Backup Settings'),
            onTap: _showBackupSettings,
          ),
          _buildSectionHeader('Units & Measurements'),
          ListTile(
            leading: const Icon(Icons.scale),
            title: const Text('Measurement Units'),
            subtitle: Text('Weight: $_weightUnit, Temp: $_temperatureUnit'),
            onTap: _showUnitsSettings,
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
            },
          ),
          _buildSectionHeader('Help & Support'),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: _showHelpSupport,
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            onTap: _showAboutApp,
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate App'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redirecting to app store...')),
              );
            },
          ),
          _buildSectionHeader('App Information'),
          const ListTile(title: Text('Version'), subtitle: Text('1.0.0')),
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Terms of Service'),
            onTap: () {},
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
              TextField(
                controller: _boatNumberController,
                decoration: const InputDecoration(labelText: 'Boat Number'),
              ),
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
                  const SnackBar(content: Text('Profile updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Notification Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSwitchTile(
                    icon: Icons.remember_me,
                    title: 'Catch Reminders',
                    value: _catchRemindersEnabled,
                    onChanged: _toggleCatchReminders,
                  ),
                  _buildSwitchTile(
                    icon: Icons.analytics,
                    title: 'Weekly Reports',
                    value: _weeklyReportsEnabled,
                    onChanged: _toggleWeeklyReports,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBackupSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Backup Settings'),
          content: const Text('Configure your backup preferences here.'),
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

  void _showUnitsSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Units Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Weight Unit'),
                trailing: DropdownButton<String>(
                  value: _weightUnit,
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                  ],
                  onChanged: (value) {
                    setState(() => _weightUnit = value!);
                    _saveSetting('weightUnit', value);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              ListTile(
                title: const Text('Temperature Unit'),
                trailing: DropdownButton<String>(
                  value: _temperatureUnit,
                  items: const [
                    DropdownMenuItem(value: 'Celsius', child: Text('Celsius')),
                    DropdownMenuItem(value: 'Fahrenheit', child: Text('Fahrenheit')),
                  ],
                  onChanged: (value) {
                    setState(() => _temperatureUnit = value!);
                    _saveSetting('temperatureUnit', value);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
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

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text('Contact support at support@fishingapp.com'),
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
          title: const Text('About App'),
          content: const Text('Fishing Log App v1.0.0\n\nTrack your fishing catches and statistics.'),
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