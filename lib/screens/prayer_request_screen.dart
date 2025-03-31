import 'package:flutter/material.dart';
import '../services/prayer_request_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrayerRequestScreen extends StatefulWidget {
  const PrayerRequestScreen({super.key});

  @override
  State<PrayerRequestScreen> createState() => _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends State<PrayerRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _requestController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;
  final _prayerService = PrayerRequestService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('first_name, last_name')
            .eq('id', user.id)
            .single();
        
        print('Debug - User profile data: $response');
        
        if (response != null) {
          final firstName = response['first_name'] as String? ?? '';
          final lastName = response['last_name'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          
          print('Debug - Setting name to: $fullName');
          
          if (mounted) {
            setState(() {
              _nameController.text = fullName;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _submitPrayerRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('Debug - About to submit prayer request:');
      print('Debug - Name value: ${_nameController.text}');
      print('Debug - Is anonymous: $_isAnonymous');
      print('Debug - Request text: ${_requestController.text}');

      await _prayerService.submitPrayerRequest(
        request: _requestController.text,
        name: _nameController.text,
        isAnonymous: _isAnonymous,
      );

      _requestController.clear();
      _nameController.clear();
      setState(() {
        _isAnonymous = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prayer request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting prayer request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: const Text('Prayer Requests'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Submit a Prayer Request',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.red[900],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your prayer requests with our church community.\nYour request will be kept confidential.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red[100]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your Name',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isAnonymous,
                        decoration: InputDecoration(
                          hintText: 'Enter your name...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[500]!, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[200]!),
                          ),
                          filled: _isAnonymous,
                          fillColor: _isAnonymous ? Colors.grey[100] : null,
                        ),
                        validator: (value) {
                          if (!_isAnonymous && (value == null || value.isEmpty)) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Your Prayer Request',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _requestController,
                        decoration: InputDecoration(
                          hintText: 'Enter your prayer request here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[500]!, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[200]!),
                          ),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your prayer request';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      CheckboxListTile(
                        title: const Text('Submit Anonymously'),
                        subtitle: const Text('Your name will not be shown with the request'),
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() {
                            _isAnonymous = value ?? false;
                            if (_isAnonymous) {
                              _nameController.clear();
                            } else {
                              _loadUserProfile(); // Reload the user's name when unchecking anonymous
                            }
                          });
                        },
                        activeColor: Colors.red,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitPrayerRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Prayer Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red[100]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Scripture for Today',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"Therefore I tell you, whatever you ask for in prayer, believe that you have received it, and it will be yours."',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '- Mark 11:24',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _requestController.dispose();
    _nameController.dispose();
    super.dispose();
  }
} 