class ProductFormValidator {
  const ProductFormValidator._();
  static String? title(String? value) { final text = value?.trim() ?? ''; if (text.isEmpty) return 'Product title ထည့်ပါ'; if (text.length < 3) return 'Title အနည်းဆုံး ၃ လုံး ရေးပါ'; return null; }
  static String? description(String? value) { final text = value?.trim() ?? ''; if (text.isEmpty) return 'Description ထည့်ပါ'; if (text.length < 5) return 'Description အနည်းဆုံး ၅ လုံး ရေးပါ'; return null; }
  static String? price(String? value) { final text = value?.trim() ?? ''; if (text.isEmpty) return 'Price ထည့်ပါ'; final n = int.tryParse(text); if (n == null) return 'Price ကို ဂဏန်းဖြင့်ရေးပါ'; if (n < 0) return 'Price မမှန်ပါ'; return null; }
  static String? city(String? value) => (value?.trim().isEmpty ?? true) ? 'City ထည့်ပါ' : null;
  static String? township(String? value) => (value?.trim().isEmpty ?? true) ? 'Township ထည့်ပါ' : null;
}
