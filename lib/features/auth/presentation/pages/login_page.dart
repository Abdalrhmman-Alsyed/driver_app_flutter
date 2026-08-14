import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSignedOut && state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: p.dangerContainer,
                  ),
                );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height - 48,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 64)),
                      const SizedBox(height: 20),
                      Text(
                        'أهلًا بك',
                        textAlign: TextAlign.center,
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'سجّل الدخول لمتابعة رحلاتك',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium
                            ?.copyWith(color: p.textSecondary),
                      ),
                      const SizedBox(height: 36),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          hintText: 'name@company.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          final input = value?.trim() ?? '';
                          if (input.isEmpty) return 'أدخل بريدك الإلكتروني';
                          if (!input.contains('@')) return 'بريد غير صالح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        enabled: !isLoading,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: _obscure ? 'إظهار' : 'إخفاء',
                          ),
                        ),
                        validator: (value) =>
                            (value ?? '').isEmpty ? 'أدخل كلمة المرور' : null,
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: p.onPrimary,
                                ),
                              )
                            : const Text('تسجيل الدخول'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'هذا التطبيق للسائقين فقط',
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
