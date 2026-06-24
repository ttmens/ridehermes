import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';

class LoginForm extends ConsumerWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;

  const LoginForm({
    super.key,
    required this.phoneController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: '手机号',
            prefixIcon: Icon(Icons.phone),
            hintText: '请输入11位手机号',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '密码',
            prefixIcon: Icon(Icons.lock),
            hintText: '请输入密码',
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: authState.isLoading
              ? null
              : () {
                  ref.read(authProvider.notifier).login(
                        phoneController.text,
                        passwordController.text,
                      );
                },
          child: authState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('登录 / 注册'),
        ),
        if (authState.error != null) ...[
          const SizedBox(height: 16),
          Text(
            authState.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
