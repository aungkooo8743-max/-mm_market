import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../product/presentation/widgets/product_preview_card.dart';
import '../providers/favorite_product_providers.dart';
class FavoritesPage extends ConsumerWidget{const FavoritesPage({super.key}); @override Widget build(BuildContext context, WidgetRef ref){final async=ref.watch(favoriteProductsProvider); return Scaffold(appBar:AppBar(title:const Text('Favorites')),body:async.when(loading:()=>const AppLoadingView(), error:(e,_)=>AppEmptyView(title:'Error',message:e.toString()), data:(items)=>items.isEmpty?const AppEmptyView(title:'Favorite မရှိသေးပါ'):GridView.builder(padding:const EdgeInsets.all(12),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.72),itemCount:items.length,itemBuilder:(_,i)=>ProductPreviewCard(product:items[i]))));}}
