import 'package:sales_management/models/user.dart';

class UserSeed {

  final List<Map<String, dynamic>> users = [
    {
      'id': 0,
      'lname': 'Admin',
      'fname': 'System',
      'mname': '',
      'sex': 'MALE',
      'role': 'admin',
      'username': 'admin',
      'password': '1234',
    },
    {
      'id': 0,
      'lname': 'Cashier',
      'fname': 'Front',
      'mname': '',
      'sex': 'FEMALE',
      'role': 'cashier',
      'username': 'cashier',
      'password': '1234',
    },
  ];


  void userSeed() async {

    final exists = await User().hasUsers();
    if (!exists) {
      for (var user in users) {
        await User().insertUser({
          'id': 0,
          'username': user['username'],
          'password': user['password'],
          'fname': user['fname'],
          'mname': user['mname'],
          'lname': user['lname'],
          'sex': user['sex'],
          'role': user['role'],
        });
      }
    }
  }



}