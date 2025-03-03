class RegexExtractionService {
  // Extract entities using enhanced regex patterns
  Map<String, String?> extractEntities(String text) {
    // Normalize text first
    final normalizedText = _normalizeArabicText(text);

    // Initialize empty results
    final Map<String, String?> entities = {
      'quantity': null,
      'address': null,
      'collection_date': null,
      'gift_selection': null,
    };

    // QUANTITY - Enhanced patterns
    // Try multiple patterns to extract quantity information
    final quantityRegexPatterns = [
      // X كيلو/kg of oil
      r'(\d+)\s*(كيلو|كجم|كغم|كلغ|kg|kilo|لتر|لتر من الزيت)',
      // Words like "I have X كيلو"
      r'(عندي|لدي|أملك|املك)\s+(\d+)\s*(كيلو|كجم|كغم|كلغ|kg|kilo|لتر)',
      // X كيلو من الزيت
      r'(\d+)\s*(كيلو|كجم|كغم|كلغ|kg|kilo|لتر)\s*(من\s+)?(الزيت|زيت)',
      // Just numbers with units
      r'(\d+)\s*(كيلو|كجم|كغم|كلغ|kg|kilo)',
    ];

    for (final pattern in quantityRegexPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(normalizedText);
      if (match != null) {
        if (match.groupCount >= 1) {
          // Extract just the number
          final quantity = match.group(1);
          if (quantity != null) {
            entities['quantity'] = _convertArabicWordsToNumbers(quantity);
            break;
          }
        }
      }
    }

    // Try to find numbers near "زيت" (oil) if no quantity found
    if (entities['quantity'] == null) {
      final oilRegex = RegExp(r'زيت', caseSensitive: false);
      final oilMatch = oilRegex.firstMatch(normalizedText);
      if (oilMatch != null) {
        final oilIndex = oilMatch.start;

        // Look for numbers within 20 characters before or after "زيت"
        final searchStart = (oilIndex - 20).clamp(0, normalizedText.length);
        final searchEnd = (oilIndex + 20).clamp(0, normalizedText.length);
        final searchArea = normalizedText.substring(searchStart, searchEnd);

        final numberRegex = RegExp(r'(\d+)');
        final numberMatch = numberRegex.firstMatch(searchArea);
        if (numberMatch != null) {
          entities['quantity'] = numberMatch.group(1);
        }
      }
    }

    // ADDRESS - Enhanced patterns
    // Common address indicators in Arabic contexts
    final addressIndicators = [
      'عنوان',
      'شارع',
      'حي',
      'منطقة',
      'مدينة',
      'بلوك',
      'قطعة',
      'منزل',
      'فيلا',
      'شقة',
      'عمارة',
      'بناية',
      'مبنى',
      'مجمع',
      'طريق',
      'جادة',
      'مفرق',
      'تقاطع',
      'دوار',
      'قرية'
    ];

    // Try to extract address using address indicators
    for (final indicator in addressIndicators) {
      final indicatorRegex =
          RegExp('\\b$indicator\\b[\\s،,:]+([^،.؟!]+)', caseSensitive: false);
      final match = indicatorRegex.firstMatch(normalizedText);
      if (match != null) {
        entities['address'] = '$indicator ${match.group(1)?.trim()}';
        break;
      }
    }

    // Try to extract address from "في" (in) + location
    if (entities['address'] == null) {
      final inLocationRegex =
          RegExp(r'في\s+([^،.؟!]{3,30})', caseSensitive: false);
      final match = inLocationRegex.firstMatch(normalizedText);
      if (match != null) {
        entities['address'] = match.group(1)?.trim();
      }
    }

    // COLLECTION DATE - Enhanced patterns
    // Try multiple date formats and patterns
    final dateRegexPatterns = [
      // dd/mm/yyyy or dd-mm-yyyy
      r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})',
      // Simple day mention
      r'(يوم|اليوم|غد|غدا|بعد غد|بكرة|بكره|بكرا)\s+([^،.؟!]{3,20})',
      // Next/this week/month
      r'(هذا|هذه|القادم|القادمة|المقبل|المقبلة)\s+(الاسبوع|الأسبوع|الشهر)',
      // Morning/evening of specific day
      r'(صباح|مساء|ظهر)\s+([^،.؟!]{3,20})',
      // Named day (Saturday, Sunday, etc.)
      r'(السبت|الأحد|الاثنين|الثلاثاء|الاربعاء|الخميس|الجمعة)',
      // Named month dates
      r'(\d{1,2})\s+(يناير|فبراير|مارس|ابريل|مايو|يونيو|يوليو|اغسطس|سبتمبر|اكتوبر|نوفمبر|ديسمبر)',
    ];

    for (final pattern in dateRegexPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(normalizedText);
      if (match != null) {
        // Get the full matched date expression
        entities['collection_date'] = match.group(0)?.trim();
        break;
      }
    }

    // Additional date context patterns
    if (entities['collection_date'] == null) {
      final dateContextRegex = RegExp(
          r'(?:استلام|جمع|تاريخ|موعد|زيارة)[^،.؟!]+(يوم|غدا|بعد غد|اليوم|الاسبوع|الشهر|صباح|مساء|ظهر)[^،.؟!]+',
          caseSensitive: false);
      final match = dateContextRegex.firstMatch(normalizedText);
      if (match != null) {
        entities['collection_date'] = match.group(0)?.trim();
      }
    }

    // GIFT SELECTION - Enhanced patterns
    // Match gift-related keywords and surrounding context
    final giftIndicators = [
      'هدية',
      'هدايا',
      'مكافأة',
      'جائزة',
      'قسيمة',
      'كوبون',
      'خصم',
      'عرض',
      'قسيمة شراء',
      'بطاقة هدية',
      'نقاط',
      'استبدال'
    ];

    for (final indicator in giftIndicators) {
      // Look for indicator directly
      final directRegex =
          RegExp('$indicator\\s+([^،.؟!]+)', caseSensitive: false);
      final directMatch = directRegex.firstMatch(normalizedText);
      if (directMatch != null) {
        entities['gift_selection'] =
            '$indicator ${directMatch.group(1)?.trim()}';
        break;
      }

      // Look for "I want/prefer" + indicator
      final preferenceRegex = RegExp(
          '(?:اريد|أريد|افضل|أفضل|اختار|أختار)\\s+([^،.؟!]*$indicator[^،.؟!]*)',
          caseSensitive: false);
      final preferenceMatch = preferenceRegex.firstMatch(normalizedText);
      if (preferenceMatch != null) {
        entities['gift_selection'] = preferenceMatch.group(1)?.trim();
        break;
      }
    }

    // If no specific gift was found, check if any of the standard gifts are mentioned
    if (entities['gift_selection'] == null) {
      final standardGifts = [
        'قسيمة تسوق',
        'بطاقة هدية',
        'خصم على الزيت',
        'منتجات مجانية',
        'صابون',
        'منظفات',
        'منتجات تنظيف'
      ];

      for (final gift in standardGifts) {
        if (normalizedText.contains(gift)) {
          entities['gift_selection'] = gift;
          break;
        }
      }
    }

    return entities;
  }

  // Normalize Arabic text
  String _normalizeArabicText(String text) {
    // Replace various Arabic character forms with standard forms
    Map<String, String> replacements = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ى': 'ي',
      'ة': 'ه',
    };

    String normalized = text;
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });

    // Remove diacritics (tashkeel)
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u065F]'), '');

    // Normalize whitespace
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  // Helper to convert Arabic number words to digits
  String _convertArabicWordsToNumbers(String input) {
    // If already a number, return it
    if (RegExp(r'^\d+$').hasMatch(input)) {
      return input;
    }

    // Map of Arabic number words to digits
    final Map<String, String> numberWords = {
      'واحد': '1',
      'اثنين': '2',
      'ثلاثة': '3',
      'اربعة': '4',
      'أربعة': '4',
      'خمسة': '5',
      'ستة': '6',
      'سبعة': '7',
      'ثمانية': '8',
      'تسعة': '9',
      'عشرة': '10',
      'عشرين': '20',
      'ثلاثين': '30',
      'اربعين': '40',
      'أربعين': '40',
      'خمسين': '50',
      'ستين': '60',
      'سبعين': '70',
      'ثمانين': '80',
      'تسعين': '90',
      'مئة': '100',
      'مائة': '100',
      'مية': '100',
      'ألف': '1000',
      'الف': '1000'
    };

    // Check if the input matches any known number word
    for (final entry in numberWords.entries) {
      if (input.contains(entry.key)) {
        return entry.value;
      }
    }

    // If no match found, return the original input
    return input;
  }
}
