import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RoleBasedWidget extends StatelessWidget {
  final Widget adminWidget;
  final Widget? memberWidget;
  final bool showAlways;

  const RoleBasedWidget({
    super.key,
    required this.adminWidget,
    this.memberWidget,
    this.showAlways = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    if (auth.isAdmin) {
      return adminWidget;
    } else if (memberWidget != null) {
      return memberWidget!;
    } else if (showAlways) {
      return adminWidget;
    }
    return const SizedBox.shrink();
  }
}