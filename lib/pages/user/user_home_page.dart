import 'package:flutter/material.dart';
import 'package:sales_management/components/user_sidebar.dart';
import 'package:sales_management/pages/admin/expense/expense_page.dart';
import 'package:sales_management/pages/user/dashboard/user_dashboard.dart';
import 'package:sales_management/pages/user/pos/pos_page.dart';
import 'package:sales_management/pages/user/transaction/user_transaction.dart';

import '../../components/theme_helper.dart';
import '../../services/user_session.dart';


enum UserSection {
  userDashboard,
  pos,
  transactions,
  expenses
}


class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {

  UserSection _current = UserSection.userDashboard;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    UserSession().loadUserSession().then((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }


  Widget _body() {
    switch (_current){
      case UserSection.userDashboard:
        return const UserDashboard();

      case UserSection.pos:
        // TODO: Handle this case.
        return const PosPage();

      case UserSection.transactions:
        return const UserTransaction();

      case UserSection.expenses:
        return const ExpensePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('SamKaha - ${_currentUser?['fname'] ?? ''} ${_currentUser?['lname'] ?? ''}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
        backgroundColor: ThemeHelper.primaryColor(),
        foregroundColor: Colors.white,
      ),
      drawer: UserSidebar(
        currentSection: _current,
        onSelect: (section) {
          setState(() => _current = section);
          Navigator.pop(context); // close drawer
        },
      ),
      body: SafeArea(
        top: false,
        child: _body(),
      ),
    );
  }

  
}
