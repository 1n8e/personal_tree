import 'package:flutter/material.dart';

import 'login_screen.dart';

/// Регистрация и вход в дизайне — один поток «код по SMS/почте», поэтому
/// отдельная форма не нужна.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginScreen();
}
