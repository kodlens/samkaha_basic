import 'package:sales_management/models/category.dart';

class CategorySeed {
  

    //initial data for categories
  final List<Map<String, dynamic>> categories = [
    {'category': 'Beverages'},
    {'category': 'Food'},
  ];

  

  void categorySeed() async{
    // Add seeding logic here
     final exists = await Category().hasCategories();
    
    if(!exists){
      for (var item in categories) {
        await Category().insertCategory({
          'id': 0,
          'category': item['category']
        });
      }
    }
  }

}