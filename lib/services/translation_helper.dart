class TranslationHelper {
  // Dictionary mapping Vietnamese medical phrases/words to English academic terms.
  // Sorted from longest phrase to shortest word to prevent partial matches taking priority.
  static const Map<String, String> _dictionary = {
    // Multi-word medical terms
    'sốt xuất huyết': 'dengue fever',
    'ung thư phổi': 'lung cancer',
    'ung thư vú': 'breast cancer',
    'ung thư gan': 'liver cancer',
    'ung thư dạ dày': 'gastric cancer',
    'ung thư máu': 'leukemia',
    'hệ miễn dịch': 'immune system',
    'xương khớp': 'orthopedics',
    'viêm khớp': 'arthritis',
    'huyết áp cao': 'hypertension',
    'huyết áp thấp': 'hypotension',
    'nhồi máu cơ tim': 'myocardial infarction',
    'tai biến mạch máu não': 'stroke',
    'suy giảm trí nhớ': 'dementia',
    'rối loạn lo âu': 'anxiety disorder',
    'tế bào gốc': 'stem cells',
    'kháng kháng sinh': 'antibiotic resistance',
    'đái tháo đường': 'diabetes mellitus',
    'tiểu đường': 'diabetes',
    'suy thận': 'renal failure',
    'viêm phổi': 'pneumonia',
    'lao phổi': 'tuberculosis',
    'hen suyễn': 'asthma',
    'bệnh truyền nhiễm': 'infectious disease',
    'phẫu thuật': 'surgery',
    'chẩn đoán': 'diagnosis',
    'điều trị': 'therapy',
    'tác dụng phụ': 'side effects',
    'lâm sàng': 'clinical trial',
    'dịch tễ học': 'epidemiology',
    
    // Single-word terms
    'ung thư': 'cancer',
    'tim mạch': 'cardiology',
    'tim': 'cardiology',
    'thần kinh': 'neurology',
    'não': 'brain',
    'gan': 'liver',
    'phổi': 'lung',
    'thận': 'kidney',
    'máu': 'blood',
    'dạ dày': 'stomach',
    'ruột': 'intestinal',
    'khớp': 'joint',
    'da liễu': 'dermatology',
    'nhi khoa': 'pediatrics',
    'vắc xin': 'vaccine',
    'vacxin': 'vaccine',
    'dược': 'pharmacology',
    'thuốc': 'drug',
    'gen': 'genetics',
    'di truyền': 'genetics',
    'béo phì': 'obesity',
    'dị ứng': 'allergy',
    'đại dịch': 'pandemic',
    'dịch bệnh': 'epidemic',
    'đột quỵ': 'stroke',
    'trầm cảm': 'depression',
    'lo âu': 'anxiety',
    'lão hóa': 'aging',
    'miễn dịch': 'immunology',
    'dinh dưỡng': 'nutrition',
    'độc chất': 'toxicology',
    'vi khuẩn': 'bacteria',
    'vi rút': 'virus',
    'nấm': 'fungal',
  };

  /// Enhances a search query entered by the user.
  /// If it detects Vietnamese medical terms, it appends the English translation.
  /// Example: "ung thư phổi" -> "ung thư phổi OR \"lung cancer\""
  static Map<String, String> getTranslationInfo(String query) {
    if (query.trim().isEmpty) {
      return {'original': '', 'translated': '', 'enhanced': ''};
    }

    String lowerQuery = query.toLowerCase().trim();
    List<String> matchedTranslations = [];

    // Check against dictionary
    _dictionary.forEach((vnTerm, enTerm) {
      if (lowerQuery.contains(vnTerm)) {
        matchedTranslations.add(enTerm);
        // Remove the matched Vietnamese term to avoid matching subparts
        lowerQuery = lowerQuery.replaceAll(vnTerm, '');
      }
    });

    if (matchedTranslations.isEmpty) {
      return {
        'original': query,
        'translated': '',
        'enhanced': query,
      };
    }

    // Combine translations
    String translatedText = matchedTranslations.join(' ');
    
    // Build enhanced query
    // If the query is mostly Vietnamese, we construct: "Original Query OR (English Translations)"
    // This allows fetching both English publications and any Vietnamese publications in the index.
    String enhancedQuery = '($query) OR ($translatedText)';

    return {
      'original': query,
      'translated': translatedText,
      'enhanced': enhancedQuery,
    };
  }
}
