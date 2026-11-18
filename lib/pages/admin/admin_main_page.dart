
import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/pages/admin/adjustment/adjustment_page.dart';
import 'package:sales_management/pages/admin/category/category_page.dart';
import 'package:sales_management/pages/admin/dashboard/dashboard_page.dart';
import 'package:sales_management/pages/admin/expense/expense_page.dart';
import 'package:sales_management/pages/admin/inventory/inventory_page.dart';
import 'package:sales_management/pages/admin/payment_method/payment_method_page.dart';
import 'package:sales_management/pages/admin/products/product_page.dart';
import 'package:sales_management/pages/admin/uom/uom_page.dart';
import 'package:sales_management/pages/admin/user/user_page.dart';
import 'package:sales_management/services/user_session.dart';
import '../../components/admin_sidebar.dart';

enum AdminSection { 
  dashboard, 
  uoms,
  categories, 
  products, 
  inventories,
  adjustments,
  expenses,
  users,
  paymentMethods,
}

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {

  AdminSection _current = AdminSection.dashboard;
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    //_current = AdminSection.dashboard;
    UserSession().loadUserSession().then((user) {
      setState(() {
        currentUser = user;
      });
    });
  }




  Widget _body() {
    switch (_current) {
      case AdminSection.dashboard:
        return const DashboardPage();
      case AdminSection.uoms:
        return const UomPage();
      case AdminSection.categories:
        return const CategoryPage();
      case AdminSection.products:
        return const ProductPage();
      case AdminSection.adjustments:
        return const AdjustmentPage();
      case AdminSection.expenses:
        return const ExpensePage();
      case AdminSection.inventories:
        return const InventoryPage();
      case AdminSection.users:
        return const UserPage();
      case AdminSection.paymentMethods:
        return const PaymentMethodPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('SamKaha Admin - ${currentUser?['fname'] ?? ''} ${currentUser?['lname'] ?? ''}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
        backgroundColor: ThemeHelper.primaryColor(),
        foregroundColor: Colors.white,
      ),
      drawer: AdminSidebar(
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