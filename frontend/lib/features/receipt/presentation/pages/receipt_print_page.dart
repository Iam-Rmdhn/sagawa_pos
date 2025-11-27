import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/features/home/presentation/bloc/home_cubit.dart';
import 'package:sagawa_pos_new/features/home/presentation/pages/home_page.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos_new/features/receipt/presentation/bloc/receipt_cubit.dart';
import 'package:sagawa_pos_new/features/receipt/presentation/bloc/receipt_state.dart';
import 'package:sagawa_pos_new/features/receipt/presentation/widgets/receipt_preview.dart';

class ReceiptPrintPage extends StatefulWidget {
  final Receipt receipt;

  const ReceiptPrintPage({super.key, required this.receipt});

  @override
  State<ReceiptPrintPage> createState() => _ReceiptPrintPageState();
}

class _ReceiptPrintPageState extends State<ReceiptPrintPage> {
  late ReceiptCubit _receiptCubit;
  bool _isPrinted = false;

  @override
  void initState() {
    super.initState();
    _receiptCubit = ReceiptCubit();
    // Generate receipt on init
    _receiptCubit.generateReceipt(widget.receipt);
  }

  @override
  void dispose() {
    _receiptCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation until printed
        if (!_isPrinted) {
          CustomSnackbar.show(
            context,
            message: 'Mohon cetak struk terlebih dahulu',
            type: SnackbarType.warning,
          );
          return false;
        }
        // Jika sudah print, clear cart dan langsung ke home
        context.read<HomeCubit>().clearCart();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
        return false;
      },
      child: BlocProvider.value(
        value: _receiptCubit,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFFFF4B4B),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Cetak Struk',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
          body: BlocConsumer<ReceiptCubit, ReceiptState>(
            listener: (context, state) {
              if (state is ReceiptPrinted) {
                setState(() {
                  _isPrinted = true;
                });

                // Clear cart setelah berhasil print
                context.read<HomeCubit>().clearCart();

                CustomSnackbar.show(
                  context,
                  message: state.message,
                  type: SnackbarType.success,
                );

                // Auto navigate ke home setelah 2 detik
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  }
                });
              } else if (state is ReceiptShared) {
                CustomSnackbar.show(
                  context,
                  message: state.message,
                  type: SnackbarType.success,
                );
              } else if (state is ReceiptError) {
                CustomSnackbar.show(
                  context,
                  message: state.message,
                  type: SnackbarType.error,
                );
              }
            },
            builder: (context, state) {
              if (state is ReceiptGenerating) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF4B4B),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Membuat struk...',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Receipt Preview or Success Animation
                  Expanded(
                    child: _isPrinted
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(
                                  'assets/animations/payment_successful.json',
                                  width: 300,
                                  height: 300,
                                  repeat: false,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Struk Berhasil Dicetak!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00C896),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Kembali ke beranda dalam beberapa saat...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: ReceiptPreview(receipt: widget.receipt),
                          ),
                  ),

                  // Bottom Button Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bluetooth Print Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: state is ReceiptPrinting || _isPrinted
                                  ? null
                                  : () {
                                      // Langsung cetak tanpa pilih printer
                                      _receiptCubit.printViaBluetooth();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4B4B),
                                disabledBackgroundColor: const Color(
                                  0xFFFF4B4B,
                                ).withOpacity(0.5),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: state is ReceiptPrinting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.bluetooth,
                                      color: Colors.white,
                                    ),
                              label: const Text(
                                'Cetak via Bluetooth',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
