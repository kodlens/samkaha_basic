import 'package:sales_management/seeder/category_seed.dart';
import 'package:sales_management/seeder/payment_method_seed.dart';
import 'package:sales_management/seeder/product_seed.dart';
import 'package:sales_management/seeder/uom_seeder.dart';
import 'package:sales_management/seeder/user_seed.dart';

class DBSeed {

  void seed() {
    // Add seeding logic here
    UserSeed().userSeed();
    UomSeeder().uomSeed();
    CategorySeed().categorySeed();
    ProductSeed().productSeed();
    PaymentMethodSeed().paymentMethodSeed();
  }
}