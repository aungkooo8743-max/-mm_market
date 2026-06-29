import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';

extension ProductCategoryLabel on ProductCategory {
  String get displayLabel {
    switch (this) {
      case ProductCategory.electronics:     return 'အီလက်ထရောနစ် / Electronics';
      case ProductCategory.phones:          return 'ဖုန်းများ / Phones';
      case ProductCategory.computers:       return 'ကွန်ပျူတာ / Computers';
      case ProductCategory.fashion:         return 'အခွတ်အထည် / Fashion';
      case ProductCategory.vehicles:        return 'ယာင်များ / Vehicles';
      case ProductCategory.property:        return 'အိမ်ခြံမြေ / Property';
      case ProductCategory.furniture:       return 'ပရိဘောဂ / Furniture';
      case ProductCategory.homeAppliances:  return 'အိမ်သုံပစ္စည်း / Home Appliances';
      case ProductCategory.beauty:          return 'အလှကုန် / Beauty';
      case ProductCategory.sports:          return 'အားကစား / Sports';
      case ProductCategory.books:           return 'စာအုပ် / Books';
      case ProductCategory.toys:            return 'ကစားစရာ / Toys';
      case ProductCategory.jobs:            return 'အလုပ်အကိုင် / Jobs';
      case ProductCategory.services:        return 'ဝန်ဆောင်မှု / Services';
      case ProductCategory.other:           return 'အခြား / Other';
    }
  }
}

class ProductCategorySelector extends StatelessWidget {
  final ProductCategory value;
  final ValueChanged<ProductCategory> onChanged;
  const ProductCategorySelector({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<ProductCategory>(
    value: value,
    decoration: const InputDecoration(labelText: 'အမျိုအစား / Category', prefixIcon: Icon(Icons.category_outlined)),
    items: ProductCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayLabel))).toList(),
    onChanged: (v) { if (v != null) onChanged(v); },
  );
}
