import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../forms/product_form_validator.dart';
import 'product_category_selector.dart';
import 'product_condition_selector.dart';

class ProductFormFields extends StatelessWidget {
  final TextEditingController titleController, descriptionController, priceController, cityController, townshipController, addressController;
  final ProductCategory category; final ProductCondition condition; final bool isNegotiable;
  final ValueChanged<ProductCategory> onCategoryChanged; final ValueChanged<ProductCondition> onConditionChanged; final ValueChanged<bool> onNegotiableChanged;
  const ProductFormFields({super.key, required this.titleController, required this.descriptionController, required this.priceController, required this.cityController, required this.townshipController, required this.addressController, required this.category, required this.condition, required this.isNegotiable, required this.onCategoryChanged, required this.onConditionChanged, required this.onNegotiableChanged});
  @override Widget build(BuildContext context) => Column(children: [
    TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'ကုန်ပစ္စည်း အမည် / Product Title', hintText: 'ဥပမာ: iPhone 14 Pro Max', prefixIcon: Icon(Icons.title_outlined)), validator: ProductFormValidator.title), const SizedBox(height: 12),
    TextFormField(controller: descriptionController, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'ဖော်ပြချက် / Description', hintText: 'ကုန်ပစ္စည်းအကြောင်း အသေးစိတ် ဖော်ပြပါ...', prefixIcon: Icon(Icons.description_outlined), alignLabelWithHint: true), validator: ProductFormValidator.description), const SizedBox(height: 12),
    ProductCategorySelector(value: category, onChanged: onCategoryChanged), const SizedBox(height: 12),
    ProductConditionSelector(value: condition, onChanged: onConditionChanged), const SizedBox(height: 12),
    TextFormField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'စျေးနှုန်း / Price', hintText: 'ဥပမာ: 500000', suffixText: 'MMK', prefixIcon: Icon(Icons.payments_outlined)), validator: ProductFormValidator.price),
    SwitchListTile(value: isNegotiable, contentPadding: EdgeInsets.zero, title: const Text('စျေးညှိနိုင်သည် / Negotiable'), subtitle: const Text('ဈေးနှုန်း ညှိနှိုင်းနိုင်ပါသည် / Price can be negotiated'), onChanged: onNegotiableChanged), const SizedBox(height: 12),
    TextFormField(controller: cityController, decoration: const InputDecoration(labelText: 'မြို့ / City', hintText: 'ဥပမာ: ရန်ကုန် / Yangon', prefixIcon: Icon(Icons.location_city_outlined)), validator: ProductFormValidator.city), const SizedBox(height: 12),
    TextFormField(controller: townshipController, decoration: const InputDecoration(labelText: 'မြို့နယ် / Township', hintText: 'ဥပမာ: ဗဟန်း / Bahan', prefixIcon: Icon(Icons.location_on_outlined)), validator: ProductFormValidator.township), const SizedBox(height: 12),
    TextFormField(controller: addressController, maxLines: 2, decoration: const InputDecoration(labelText: 'လိပ်စာ (ရွေးချယ်နိုင်) / Address (Optional)', hintText: 'အသေးစိတ် လိပ်စာ ထည့်ပါ...', prefixIcon: Icon(Icons.map_outlined))),
  ]);
}
