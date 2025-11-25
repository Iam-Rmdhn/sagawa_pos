import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/features/home/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    final idInput = _emailController.text.trim();
    final password = _passwordController.text;
    if (idInput.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan ID dan password')));
      return;
    }

    final id = idInput.toUpperCase(); // send uppercase to match DB IDs

    setState(() => _isLoading = true);

    Future<List<String>> _discoverCandidates() async {
      final candidates = <String>[
        'http://10.0.2.2:8080', // Android emulator -> host
        'http://127.0.0.1:8080',
        'http://localhost:8080',
      ];

      try {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            // add host LAN IPs so device can reach host on same network
            candidates.add('http://${addr.address}:8080');
          }
        }
      } catch (_) {
        // ignore networking errors
      }

      // dedupe while preserving order
      final seen = <String>{};
      final out = <String>[];
      for (final c in candidates) {
        if (seen.add(c)) out.add(c);
      }
      return out;
    }

    try {
      final candidates = await _discoverCandidates();
      // ignore: avoid_print
      print('Login candidates: $candidates');

      Response? lastResponse;
      Object? lastError;

      for (final base in candidates) {
        final url = '$base/api/v1/kasir/login';
        final dio = Dio();
        // avoid Dio throwing for non-2xx so we can handle status codes uniformly
        dio.options.validateStatus = (status) => true;
        // increase timeouts to cover slower dev machines
        dio.options.connectTimeout = const Duration(seconds: 12);
        dio.options.receiveTimeout = const Duration(seconds: 12);

        // ignore: avoid_print
        print('Attempting login at $url');

        try {
          final response = await dio.post(
            url,
            data: {'id': id, 'password': password},
          );
          lastResponse = response;
          // ignore: avoid_print
          print(
            'Response from $url -> status=${response.statusCode}, body=${response.data}',
          );

          if (response.statusCode == 200) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
            return;
          }

          // non-200: try next candidate
        } catch (e) {
          // log and continue trying next candidate
          lastError = e;
          // ignore: avoid_print
          print('Error contacting $url : $e');
          continue;
        }
      }

      // after trying all candidates, show best-available error
      String msg = 'Login gagal';
      if (lastResponse != null) {
        try {
          final body = lastResponse.data;
          if (body is Map && body['error'] != null)
            msg = body['error'].toString();
          else if (body is String && body.isNotEmpty)
            msg = body;
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } else if (lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan jaringan: $lastError')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      // ignore: avoid_print
      print('Unexpected login error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -size.width * 0.15,
              left: -size.width * 0.25,
              child: Image.asset(
                'assets/element/shape_login2.png',
                width: size.width * 0.55,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox();
                },
              ),
            ),

            Positioned(
              bottom: -size.width * 0.50,
              right: -size.width * 0.53,
              child: Image.asset(
                'assets/element/shape_login1.png',
                width: size.width * 1.4,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox();
                },
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 25,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AppImages.appLogo,
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.store,
                                  size: 120,
                                  color: Color(0xFFFF4B4B),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Login',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Selamat datang, silahkan masuk dengan akun yang sudah diberikan oleh admin Sagawa Group.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.black54,
                                    height: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 32),
                            _LoginField(
                              controller: _emailController,
                              label: 'User ID',
                              hintText: 'User ID',
                              iconPath: AppImages.userCard,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            _LoginField(
                              controller: _passwordController,
                              label: 'Password',
                              hintText: '********',
                              iconPath: AppImages.passIcon,
                              obscureText: _obscurePassword,
                              trailing: IconButton(
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4B4B),
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  shadowColor: const Color(0x66FF4B4B),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => _login(context),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text(
                                            'Masuk',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.iconPath,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String iconPath;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black87, width: 1.2),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.black38),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}
