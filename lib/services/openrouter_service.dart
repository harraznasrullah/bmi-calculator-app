import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String _apiKey = "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";
  static const String _apiUrl = "https://openrouter.ai/api/v1/chat/completions";
  static const String _model = "deepseek/deepseek-chat-v3.1:free";

  static Future<String> getHealthTips({
    required double bmi,
    required String category,
    double? height,
    double? weight,
    int? age,
    String? gender,
  }) async {
    try {
      // Create a prompt based on the user's BMI and profile
      String prompt = _generatePrompt(bmi, category, height, weight, age, gender);
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('choices') && data['choices'].length > 0) {
          final content = data['choices'][0]['message']['content'];
          if (content != null) {
            return content.toString().trim();
          }
        }
        // If API response format is unexpected, return a fallback
        return _getFallbackTips(bmi, category);
      } else {
        // Try to get more specific error information
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']['message'];
          // Consider using a proper logging solution in production
          // log('OpenRouter API Error: $errorMessage');
        } catch (error) {
          // Consider using a proper logging solution in production
          // log('OpenRouter API Error with status ${response.statusCode}');
        }
        return _getFallbackTips(bmi, category);
      }
    } catch (e) {
      // Consider using a proper logging solution in production
      // log('Error getting health tips: $e');
      return _getFallbackTips(bmi, category);
    }
  }

  // Fallback tips when AI service is unavailable
  static String _getFallbackTips(double bmi, String category) {
    String tips = "Here are some personalized health tips based on your BMI ($bmi - $category):\n\n";

    switch (category.toLowerCase()) {
      case 'underweight':
        tips += "• You're underweight. Consider consulting a nutritionist for healthy weight gain strategies.\n";
        tips += "• Focus on nutrient-dense foods like nuts, avocados, and whole grains.\n";
        tips += "• Include strength training exercises to build muscle mass.\n";
        tips += "• Eat 5-6 small, frequent meals throughout the day.";
        break;
      case 'normal':
        tips += "• Great job maintaining a healthy BMI! Keep up the good work.\n";
        tips += "• Continue regular exercise (150 mins moderate activity per week).\n";
        tips += "• Maintain balanced meals with fruits, vegetables, lean proteins.\n";
        tips += "• Stay hydrated and get 7-9 hours of quality sleep nightly.";
        break;
      case 'overweight':
        tips += "• You're slightly overweight. Try 30 mins of brisk walking daily.\n";
        tips += "• Reduce portion sizes and limit processed foods.\n";
        tips += "• Include both cardio and strength training exercises.\n";
        tips += "• Aim to lose 0.5-1kg per week for sustainable results.";
        break;
      case 'obese':
        tips += "• Focus on gradual weight loss through diet and exercise.\n";
        tips += "• Start with low-impact activities like walking or swimming.\n";
        tips += "• Reduce calorie intake by 500-750 calories per day.\n";
        tips += "• Consider consulting a healthcare professional for support.";
        break;
      default:
        tips += "• Maintain a balanced diet with plenty of fruits and vegetables.\n";
        tips += "• Aim for 150 minutes of moderate exercise per week.\n";
        tips += "• Stay hydrated and get adequate sleep for overall health.";
    }

    tips += "\n\nRemember to consult with a healthcare professional before making significant changes to your diet or exercise routine.";

    return tips;
  }

  static String _generatePrompt(
    double bmi,
    String category,
    double? height,
    double? weight,
    int? age,
    String? gender,
  ) {
    String userProfile = "Your BMI is ${bmi.toStringAsFixed(1)} which is categorized as $category.";
    
    if (height != null) userProfile += " Your height is ${height}cm.";
    if (weight != null) userProfile += " Your weight is ${weight}kg.";
    if (age != null) userProfile += " You are $age years old.";
    if (gender != null) userProfile += " Your gender is $gender.";
    
    return '''
$userProfile

Based on this information, provide personalized health tips. Include specific recommendations for:
- Diet suggestions
- Exercise routines 
- Lifestyle changes
- Health monitoring advice

Keep the response concise, friendly, and actionable. Format as follows:
- Main health recommendation
- Specific diet advice
- Recommended exercises
- Additional tips

Make the advice age and BMI appropriate.
''';
  }
}