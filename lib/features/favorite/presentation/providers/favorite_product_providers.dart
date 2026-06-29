import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_providers.dart';
import 'favorite_providers.dart';
final favoriteProductsProvider=FutureProvider<List<Product>>((ref) async{final favs=await ref.watch(myFavoritesProvider.future); final repo=ref.watch(productRepositoryProvider); final products=<Product>[]; for(final f in favs){final p=await repo.getProductById(f.productId); if(p!=null&&p.isVisible)products.add(p);} return products;});
