import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String _apiKey ="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";
  static const String _apiUrl = "https://openrouter.ai/api/v1/chat/completions";
  static const String _model = "deepseek/deepseek-chat-v3.1:free";
  static const String _siteUrl = "https://bmi-app.com"; // Your site URL
  static const String _siteName = "BMI App"; // Your site name

  static Future<String> getHealthTips({
    required double bmi,
    required String category,
    double? height,
    double? weight,
    int? age,
    String? gender,
    String? userName,
  }) async {
    try {
      print('DEBUG: OpenRouter.getHealthTips called with:');
      print('DEBUG: BMI: $bmi, Category: $category, Height: $height, Weight: $weight');
      print('DEBUG: Age: $age, Gender: $gender, UserName: $userName');

      // Create a prompt based on the user's BMI and profile
      String prompt = _generatePrompt(
        bmi,
        category,
        height,
        weight,
        age,
        gender,
        userName,
      );

      print('DEBUG: Generated prompt length: ${prompt.length}');

      // Create HTTP client with timeout
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse(_apiUrl),
              headers: {
                "Authorization": "Bearer $_apiKey",
                "Content-Type": "application/json",
                "HTTP-Referer": _siteUrl, // Site URL for rankings on openrouter.ai
                "X-Title": _siteName, // Site title for rankings on openrouter.ai
              },
              body: jsonEncode({
                "model": _model,
                "messages": [
                  {
                    "role": "user", 
                    "content": prompt
                  }
                ],
              }),
            )
            .timeout(const Duration(seconds: 30)); // Increased timeout

        if (response.statusCode == 200) {
          // Parse and cast the JSON response
          final Map<String, dynamic> data = jsonDecode(response.body);
          
          if (data.containsKey('choices') &&
              data['choices'] is List &&
              (data['choices'] as List).isNotEmpty) {
            final List choices = data['choices'];
            final choice = choices[0];

            if (choice is Map<String, dynamic> &&
                choice.containsKey('message')) {
              final message = choice['message'];

              if (message is Map<String, dynamic> &&
                  message.containsKey('content')) {
                final content = message['content'];

                if (content is String) {
                  return content.trim();
                } else {
                  // Content might be of different type, try to handle
                  return content?.toString()?.trim() ?? 
                      "AI health tips are currently unavailable. Here are some general tips based on your BMI:\n\n${_getFallbackTips(bmi, category)}";
                }
              }
            }
          }

          // If API response format is unexpected, notify user and return a fallback
          return "AI health tips are currently unavailable. Here are some general tips based on your BMI:\n\n${_getFallbackTips(bmi, category)}";
        } else {
          // Try to get more specific error information
          String errorMessage = "Unknown error";
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            if (errorData.containsKey('error')) {
              final errorInfo = errorData['error'];
              if (errorInfo is Map<String, dynamic> &&
                  errorInfo.containsKey('message')) {
                errorMessage = errorInfo['message'];
              }
            }
          } catch (error) {
            // Consider using a proper logging solution in production
            // log('OpenRouter API Error with status ${response.statusCode}. Error: $error');
          }
          // Return both API error and fallback tips to help with debugging
          return "AI health tips are currently unavailable due to API error: $errorMessage. Here are some general tips based on your BMI:\n\n${_getFallbackTips(bmi, category)}";
        }
      } finally {
        client.close(); // Always close the client
      }
    } on TimeoutException {
      // Handle timeout specifically
      return "AI health tips are currently unavailable. Here are some general tips based on your BMI:\n\n${_getFallbackTips(bmi, category)}";
    } on SocketException {
      // Handle network errors specifically
      return "No internet connection. Here are some general tips based on your BMI:\n\n${_getFallbackTips(bmi, category)}";
    } catch (e) {
      // Consider using a proper logging solution in production
      // log('Error getting health tips: $e');
      return "AI health tips are currently unavailable. Here are some general tips based on your BMI:\n\n${_getFallbackTips(bmi, category)}";
    }
  }

  // Fallback tips when AI service is unavailable
  static String _generatePersonalizedTips(
    double bmi,
    String category,
    double? height,
    double? weight,
    int? age,
    String? gender,
  ) {
    String tips = "🌟 **MAIN RECOMMENDATION**\n";
    
    switch (category.toLowerCase()) {
      case 'underweight':
        tips += "You're underweight, so focus on healthy weight gain through nutritious foods and strength training. 🌱\n\n";
        break;
      case 'normal':
        tips += "Great job maintaining a healthy BMI! Keep up the excellent work and maintain these healthy habits. 🎉\n\n";
        break;
      case 'overweight':
        tips += "You're slightly overweight. Focus on gradual changes to diet and exercise for sustainable results. 💪\n\n";
        break;
      case 'obese':
        tips += "Focus on gradual improvements in diet and activity levels. Small changes can lead to significant improvements. 🌟\n\n";
        break;
      default:
        tips += "Maintain healthy habits and continue monitoring your health. 🌿\n\n";
    }

    tips += "🥗 **DIET & NUTRITION TIPS**\n";
    
    switch (category.toLowerCase()) {
      case 'underweight':
        tips += "• Increase calorie intake with nutrient-dense foods like nuts, seeds, avocados, and whole grains\n";
        tips += "• Have 5-6 smaller meals throughout the day rather than 3 large ones\n";
        tips += "• Include protein-rich foods with each meal to support muscle gain\n";
        break;
      case 'normal':
        tips += "• Continue eating a balanced diet with plenty of fruits and vegetables\n";
        tips += "• Maintain portion control and mindful eating practices\n";
        tips += "• Stay hydrated with 8+ glasses of water daily\n";
        break;
      case 'overweight':
        tips += "• Reduce portion sizes gradually to avoid feeling deprived\n";
        tips += "• Focus on whole foods while limiting processed and sugary foods\n";
        tips += "• Include more vegetables and lean proteins in your meals\n";
        break;
      case 'obese':
        tips += "• Consider working with a nutritionist to create a sustainable eating plan\n";
        tips += "• Focus on reducing calorie-dense foods and increasing nutrient-rich options\n";
        tips += "• Track your food intake to understand eating patterns\n";
        break;
      default:
        tips += "• Maintain a balanced diet rich in fruits, vegetables, and whole grains\n";
        tips += "• Limit processed foods and added sugars\n";
        tips += "• Practice portion control and mindful eating\n";
    }
    
    tips += "\n🏃‍♀️ **EXERCISE RECOMMENDATIONS**\n";
    
    tips += "• Start with 150 minutes of moderate aerobic activity or 75 minutes of vigorous activity each week\n";
    
    switch (category.toLowerCase()) {
      case 'underweight':
        tips += "• Include strength training exercises 2-3 times per week to build muscle mass\n";
        break;
      case 'normal':
        tips += "• Maintain regular exercise routine with a mix of cardio and strength training\n";
        break;
      case 'overweight':
      case 'obese':
        tips += "• Start with low-impact activities like walking or swimming\n";
        tips += "• Gradually increase intensity and duration as fitness improves\n";
        break;
      default:
        tips += "• Include both cardiovascular exercise and muscle-strengthening activities\n";
    }
    
    tips += "\n💡 **LIFESTYLE ADVICE**\n";
    tips += "• Get 7-9 hours of quality sleep each night\n";
    tips += "• Manage stress through meditation, yoga, or other relaxation techniques\n";
    tips += "• Stay consistent with healthy habits rather than seeking quick fixes\n";
    
    if (age != null && age > 50) {
      tips += "• Pay special attention to bone health with calcium-rich foods and weight-bearing exercises\n";
    }
    
    if (gender != null && gender.toLowerCase() == 'female') {
      tips += "• Ensure adequate iron intake if of menstruating age\n";
    }
    
    tips += "\n📊 **HEALTH MONITORING**\n";
    tips += "• Track your BMI and other health metrics regularly\n";
    tips += "• Monitor how you feel, energy levels, and overall well-being\n";
    tips += "• Consider consulting with a healthcare professional for personalized advice\n\n";
    
    tips += "🎉 **MOTIVATIONAL CLOSING**\n";
    tips += "Remember, health is a journey, not a destination. Small, consistent changes lead to lasting improvements. You're taking positive steps by focusing on your health! 🌟";
    
    return tips;
  }

  static String _generatePrompt(
    double bmi,
    String category,
    double? height,
    double? weight,
    int? age,
    String? gender,
    String? userName,
  ) {
    String userProfile = "=== PATIENT PROFILE ===\n";

    if (userName != null && userName.isNotEmpty) {
      userProfile += "👤 Name: $userName\n";
    }
    userProfile += "📊 BMI: ${bmi.toStringAsFixed(1)} ($category)\n";

    if (age != null) {
      userProfile += "👤 Age: $age years old\n";
      String ageGroup = _getAgeGroup(age);
      userProfile += "🔸 Life Stage: $ageGroup\n";
    }

    if (gender != null) {
      userProfile += "⚧ Gender: $gender\n";
    }

    if (height != null) userProfile += "📏 Height: ${height}cm\n";
    if (weight != null) userProfile += "⚖️ Weight: ${weight}kg\n";

    return '''$userProfile

Based on this information, provide personalized health tips in an engaging and encouraging manner. Include specific recommendations for:
- Diet suggestions 🍎
- Exercise routines 💪
- Lifestyle changes 🌱
- Health monitoring advice 🔍

Make the response fun, motivational, and easy to follow with emojis and clear formatting.

Structure your response like this:

🌟 MAIN RECOMMENDATION
[Start with an encouraging message and the most important tip for their BMI category]

🥗 DIET & NUTRITION TIPS
• [Specific dietary advice with food suggestions]
• [Portion control or meal timing tips]
• [Hydration recommendations]

🏃‍♀️ EXERCISE RECOMMENDATIONS
• [Best exercises for their BMI category]
• [Duration and frequency suggestions]
• [Progression tips]

💡 LIFESTYLE ADVICE
• [Sleep, stress management, or daily habit tips]
• [Motivational suggestions]
• [Easy wins they can implement immediately]

📊 HEALTH MONITORING
• [How often to track progress]
• [What metrics to watch]
• [When to consult a healthcare professional]

🎉 MOTIVATIONAL CLOSING
[End with an encouraging message to keep them motivated]

Make the advice age and BMI appropriate. Keep it positive, supportive, and actionable. Use lots of relevant emojis to make it engaging!

Avoid medical disclaimers as they will be added separately.
''';
  }

  static String _getAgeGroup(int age) {
    if (age < 18) return 'Adolescent';
    if (age < 25) return 'Young Adult';
    if (age < 35) return 'Adult';
    if (age < 45) return 'Middle-aged Adult';
    if (age < 55) return 'Adult';
    if (age < 65) return 'Senior Adult';
    return 'Elder';
  }

  static String _getFallbackTips(double bmi, String category) {
    String tips =
        "Here are some personalized health tips based on your BMI (${bmi.toStringAsFixed(1)} - $category):\n\n";

    switch (category.toLowerCase()) {
      case 'underweight':
        tips +=
            "• You're underweight. Consider consulting a nutritionist for healthy weight gain strategies.\n";
        tips +=
            "• Focus on nutrient-dense foods like nuts, avocados, and whole grains.\n";
        tips += "• Include strength training exercises to build muscle mass.\n";
        tips += "• Eat 5-6 small, frequent meals throughout the day.";
        break;
      case 'normal':
        tips +=
            "• Great job maintaining a healthy BMI! Keep up the good work.\n";
        tips +=
            "• Continue regular exercise (150 mins moderate activity per week).\n";
        tips +=
            "• Maintain balanced meals with fruits, vegetables, lean proteins.\n";
        tips += "• Stay hydrated and get 7-9 hours of quality sleep nightly.";
        break;
      case 'overweight':
        tips +=
            "• You're slightly overweight. Try 30 mins of brisk walking daily.\n";
        tips += "• Reduce portion sizes and limit processed foods.\n";
        tips += "• Include both cardio and strength training exercises.\n";
        tips += "• Aim to lose 0.5-1kg per week for sustainable results.";
        break;
      case 'obese':
        tips += "• Focus on gradual weight loss through diet and exercise.\n";
        tips +=
            "• Start with low-impact activities like walking or swimming.\n";
        tips += "• Reduce calorie intake by 500-750 calories per day.\n";
        tips += "• Consider consulting a healthcare professional for support.";
        break;
      default:
        tips +=
            "• Maintain a balanced diet with plenty of fruits and vegetables.\n";
        tips += "• Aim for 150 minutes of moderate exercise per week.\n";
        tips += "• Stay hydrated and get adequate sleep for overall health.";
    }

    tips +=
        "\n\nRemember to consult with a healthcare professional before making significant changes to your diet or exercise routine.";

    return tips;
  }
}
