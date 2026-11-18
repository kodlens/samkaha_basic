import 'package:sales_management/models/uom.dart';

class UomSeeder {

  final List<Map<String, dynamic>> uoms = [
    {'uom': 'PCS'},
    {'uom': 'OZ'},
  ];

  void uomSeed() async {
    final exists = await Uom().hasUoms();
    if(!exists){
      for (var item in uoms) {
        await Uom().insertUom({
          'id': 0,
          'uom': item['uom']
        });
      }
    }
  }

}