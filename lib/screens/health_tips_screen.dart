import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bmi_calc/services/openrouter_service.dart';
import 'package:bmi_calc/services/supabase_service.dart';
import 'package:bmi_calc/utils/bmi_history_manager.dart';
import 'package:bmi_calc/services/health_tips_cache_service.dart';
import 'package:bmi_calc/utils/event_bus.dart';
import 'package:bmi_calc/services/bmi_storage_service.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  String _healthTips = '';
  bool _isLoading = false;
  String _error = '';
  final HealthTipsCacheService _cacheService = HealthTipsCacheService();

  StreamSubscription<String>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _isLoading = true; // Show loading state initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadTips();
    });
    
    // Listen for BMI calculation events to refresh health tips
    _eventSubscription = EventBus.instance.stream.listen((event) {
      if (event == Events.bmiCalculated) {
        _checkAndLoadTips();
      }
    });
  }

  Future<void> _checkAndLoadTips() async {
    try {
      print('DEBUG: _checkAndLoadTips started');
      // Check if user is authenticated to decide where to get the data from
      final user = SupabaseService.instance.getCurrentUser();
      print('DEBUG: User authenticated: ${user != null}');
      List<Map<String, dynamic>> records = [];

      if (user != null) {
        // If authenticated, get data from Supabase
        print('DEBUG: Fetching from Supabase for user: ${user.id}');
        records = await SupabaseService.instance.getBMIHistory();
      } else {
        // If not authenticated, get data from local storage
        print('DEBUG: Fetching from local storage');
        records = await BMIHistoryManager.getBMIHistory();
      }

      print('DEBUG: Records found: ${records.length}');
      if (records.isEmpty) {
        print('DEBUG: No records found, showing message');
        setState(() {
          _healthTips = "No BMI history found. Calculate your BMI to get personalized health tips!";
          _isLoading = false;
        });
        // Clear the cache if there's no BMI data
        _cacheService.clearCache();
        return;
      }

      // Use the most recent BMI record
      final recentRecord = records[0];
      print('DEBUG: Recent record: $recentRecord');

      // Use the correct field names depending on the source
      final bmi = user != null ? recentRecord['bmi_value'] : recentRecord['bmi'];
      final category = recentRecord['category'];
      print('DEBUG: BMI: $bmi, Category: $category');

      // Check if we have valid cached tips for this BMI and category
      final isValidCache = await _cacheService.isValidCache();
      print('DEBUG: Valid cache: $isValidCache, Has cached data: ${_cacheService.hasCachedData}');

      if (isValidCache && _cacheService.hasCachedData) {
        // Use cached tips
        print('DEBUG: Using cached tips');
        setState(() {
          _healthTips = _cacheService.cachedHealthTips ?? '';
          _error = _cacheService.cachedError ?? '';
          _isLoading = false;
        });
      } else {
        // Fetch new tips
        print('DEBUG: Fetching new tips');
        _fetchPersonalizedTips();
      }
    } catch (e) {
      print('DEBUG: Error in _checkAndLoadTips: $e');
      setState(() {
        _error = 'Failed to load health tips: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPersonalizedTips() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Check if user is authenticated to decide where to get the data from
      final user = SupabaseService.instance.getCurrentUser();
      List<Map<String, dynamic>> records = [];

      if (user != null) {
        // If authenticated, get data from Supabase
        print('DEBUG: Getting BMI history from Supabase for user: ${user.id}');
        records = await SupabaseService.instance.getBMIHistory();
        print('DEBUG: Found ${records.length} records from Supabase');
      } else {
        // If not authenticated, get data from local storage
        print('DEBUG: Getting BMI history from local storage');
        records = await BMIHistoryManager.getBMIHistory();
        print('DEBUG: Found ${records.length} records from local storage');
      }

      if (records.isEmpty) {
        setState(() {
          _healthTips = "No BMI history found. Calculate your BMI to get personalized health tips!";
          _isLoading = false;
        });
        // Clear the cache if there's no BMI data
        _cacheService.clearCache();
        return;
      }

      // Use the most recent BMI record
      final recentRecord = records[0];
      print('DEBUG: Recent record: $recentRecord');

      // Use the correct field names depending on the source
      final bmi = user != null ? recentRecord['bmi_value'] : recentRecord['bmi'];
      final category = recentRecord['category'];
      final height = user != null ? recentRecord['height'] : recentRecord['height'];
      final weight = user != null ? recentRecord['weight'] : recentRecord['weight'];

      print('DEBUG: BMI data - BMI: $bmi, Category: $category, Height: $height, Weight: $weight');

      // Validate the extracted data
      if (bmi == null || category == null || height == null || weight == null) {
        setState(() {
          _error = 'Invalid BMI data found. Please calculate your BMI again.';
          _isLoading = false;
        });
        return;
      }

      // Load user profile data for age and gender
      final userProfile = await BMIStorageService.loadUserProfile();
      final age = userProfile?['age']?.toInt();
      final gender = userProfile?['gender'];
      print('DEBUG: User profile - Age: $age, Gender: $gender');

      // Get user's name if authenticated
      final currentUser = SupabaseService.instance.getCurrentUser();
      final userName = currentUser != null ? SupabaseService.instance.getCurrentUserName() : null;
      print('DEBUG: User name: $userName');

      // Get personalized health tips from AI with age, gender, and name
      print('DEBUG: Calling OpenRouter with validated data types:');
      print('DEBUG: BMI (${bmi.runtimeType}): ${bmi.toDouble()}');
      print('DEBUG: Category (${category.runtimeType}): $category');
      print('DEBUG: Height (${height.runtimeType}): ${height.toDouble()}');
      print('DEBUG: Weight (${weight.runtimeType}): ${weight.toDouble()}');
      print('DEBUG: Age (${age?.runtimeType}): $age');
      print('DEBUG: Gender (${gender?.runtimeType}): $gender');
      print('DEBUG: UserName (${userName?.runtimeType}): $userName');

      String tips;
      try {
        tips = await OpenRouterService.getHealthTips(
          bmi: bmi.toDouble(),
          category: category,
          height: height.toDouble(),
          weight: weight.toDouble(),
          age: age,
          gender: gender,
          userName: userName,
        );
        print('DEBUG: Successfully got tips with age and gender');
      } catch (e) {
        print('DEBUG: Failed to get tips with age and gender: $e');
        print('DEBUG: Trying again without age and gender...');

        // Try again without age and gender as fallback
        try {
          tips = await OpenRouterService.getHealthTips(
            bmi: bmi.toDouble(),
            category: category,
            height: height.toDouble(),
            weight: weight.toDouble(),
            age: null,
            gender: null,
            userName: userName,
          );
          print('DEBUG: Successfully got tips without age and gender');
        } catch (e2) {
          print('DEBUG: Failed to get tips even without age and gender: $e2');
          // Try one more time with minimal data
          try {
            tips = await OpenRouterService.getHealthTips(
              bmi: bmi.toDouble(),
              category: category,
              height: height.toDouble(),
              weight: weight.toDouble(),
              age: null,
              gender: null,
              userName: null,
            );
            print('DEBUG: Successfully got tips with minimal data');
          } catch (e3) {
            print('DEBUG: All attempts failed: $e3');
            throw e3; // Re-throw the last error
          }
        }
      }

      // Update the cache with new results, using formatted BMI for consistency
      _cacheService.updateCache(tips, bmi.toDouble(), category, null);

      setState(() {
        _healthTips = tips;
        _error = '';
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Final error in _fetchPersonalizedTips: $e');
      // Update cache with error as well
      _cacheService.updateCache(null, null, null, 'Failed to load health tips: $e');

      setState(() {
        _error = 'Failed to load health tips: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'AI Health Tips',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPersonalizedTips,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Generating personalized health tips...'),
                  ],
                ),
              )
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchPersonalizedTips,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchPersonalizedTips,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add a header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personalized Health Tips',
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Based on your latest BMI calculation',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // User Profile Information Card
                          _buildUserProfileCard(),
                          const SizedBox(height: 16),
                          // Display the AI-generated health tips
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _healthTips,
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Add general tips section if needed
                          if (!_healthTips.contains('diet') && 
                              !_healthTips.contains('exercise') && 
                              !_healthTips.contains('tips'))
                            _buildGeneralTipsSection(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildGeneralTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General Health Tips',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          context,
          'Stay Hydrated',
          'Drink at least 8 glasses of water daily to maintain good health and support weight management.',
          Icons.local_drink,
          Colors.blue,
        ),
        _buildTipCard(
          context,
          'Exercise Regularly',
          'Aim for at least 150 minutes of moderate aerobic activity or 75 minutes of vigorous activity each week.',
          Icons.fitness_center,
          Colors.green,
        ),
        _buildTipCard(
          context,
          'Eat Balanced Meals',
          'Include fruits, vegetables, lean proteins, and whole grains in your daily diet for optimal nutrition.',
          Icons.restaurant,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildUserProfileCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserProfileData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Text(
              'User profile information not available',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          );
        }

        final profileData = snapshot.data!;
        final userName = profileData['userName'] as String?;
        final bmi = profileData['bmi'] as double?;
        final category = profileData['category'] as String?;
        final age = profileData['age'] as int?;
        final gender = profileData['gender'] as String?;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Profile',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (userName != null)
                    _buildProfileChip('👤 $userName', Colors.blue),
                  if (bmi != null && category != null)
                    _buildProfileChip('📊 BMI: ${bmi.toStringAsFixed(1)} ($category)', _getBMICategoryColor(category)),
                  if (age != null)
                    _buildProfileChip('🎂 $age years', Colors.purple),
                  if (gender != null)
                    _buildProfileChip('⚧ $gender', Colors.teal),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Color _getBMICategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'underweight':
        return Colors.blue;
      case 'normal':
      case 'normal weight':
      case 'healthy weight':
        return Colors.green;
      case 'overweight':
        return Colors.orange;
      case 'obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>?> _getUserProfileData() async {
    try {
      // Get BMI data
      final user = SupabaseService.instance.getCurrentUser();
      List<Map<String, dynamic>> records = [];

      if (user != null) {
        records = await SupabaseService.instance.getBMIHistory();
      } else {
        records = await BMIHistoryManager.getBMIHistory();
      }

      if (records.isEmpty) return null;

      final recentRecord = records[0];
      final bmi = user != null ? recentRecord['bmi_value'] : recentRecord['bmi'];
      final category = recentRecord['category'];

      // Get user profile data
      final userProfile = await BMIStorageService.loadUserProfile();
      final age = userProfile?['age']?.toInt();
      final gender = userProfile?['gender'];

      // Get user name
      final userName = user != null ? SupabaseService.instance.getCurrentUserName() : null;

      return {
        'userName': userName,
        'bmi': bmi,
        'category': category,
        'age': age,
        'gender': gender,
      };
    } catch (e) {
      return null;
    }
  }

  Widget _buildTipCard(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}