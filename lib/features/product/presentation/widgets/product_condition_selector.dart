import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';

extension ProductConditionLabel on ProductCondition {
  String get displayLabel {
    switch (this) {
      case ProductCondition.newItem:      return 'အသစ် / New';
      case ProductCondition.likeNew:      return 'အသစ်နှယ်သော / Like New';
      case ProductCondition.used:         return 'အသုံးပြီးပြီး / Used';
      case ProductCondition.refurbished:  return 'ပြင်းဆောင်ပြီး / Refurbished';
    }
  }
}

class ProductConditionSelector extends StatelessWidget {
  final ProductCondition value;
  final ValueChanged<ProductCondition> onChanged;
  const ProductConditionSelector({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<ProductCondition>(
    value: value,
    decoration: const InputDecoration(labelText: 'အခြေအစား / Condition', prefixIcon: Icon(Icons.inventory_2_outlined)),
    items: ProductCondition.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayLabel))).toList(),
    onChanged: (v) { if (v != null) onChanged(v); },
  );
}
