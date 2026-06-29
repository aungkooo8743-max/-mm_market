class ProductFormValidator {
  const ProductFormValidator._();
  static String? title(String value) => value.trim().length < 3 ? 'Product name အနည်းဆုံး ၃ လုံး ရေးပါ' : null;
  static String? description(String value) => value.trim().length < 10 ? 'Description အနည်းဆုံး ၁၀ လုံး ရေးပါ' : null;
  static String? price(String value) { final price = int.tryParse(value.trim()); if (price == null || price <= 0) return 'စျေးနှုန်းမှန်ကန်စွာ ထည့်ပါ'; return null; }
  static String? requiredText(String value, String label) => value.trim().isEmpty ? '$label ထည့်ပါ' : null;
}
