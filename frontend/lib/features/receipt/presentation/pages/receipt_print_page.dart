import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:sagawa_pos/core/constants/app_constants.dart';
import 'package:sagawa_pos/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos/features/home/presentation/bloc/home_cubit.dart';
import 'package:sagawa_pos/features/home/presentation/pages/home_page.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos/features/receipt/presentation/bloc/receipt_cubit.dart';
import 'package:sagawa_pos/features/receipt/presentation/bloc/receipt_state.dart';
import 'package:sagawa_pos/features/receipt/presentation/widgets/receipt_preview.dart';

class ReceiptPrintPage extends StatefulWidget {
  final Receipt receipt;

  const ReceiptPrintPage({super.key, required this.receipt});

  @override
  State<ReceiptPrintPage> createState() => _ReceiptPrintPageState();
}

class _ReceiptPrintPageState extends State<ReceiptPrintPage> {
  late ReceiptCubit _receiptCubit;
  bool _isPrinted = false;
  int _printQuantity = 1;

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
        // Jika sudah print, clear cart TANPA restore stock dan langsung ke home
        try {
          context.read<HomeCubit>().clearCartAfterCheckout();
        } catch (e) {
          // HomeCubit might not be available in this context (e.g., called from payment page)
          print('DEBUG: HomeCubit not available: $e');
        }
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
            leading: IconButton(
              onPressed: _isPrinted
                  ? null
                  : () {
                      // Navigate back to payment method page
                      Navigator.of(context).pop();
                    },
              icon: SvgPicture.asset(
                AppImages.backArrow,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _isPrinted ? Colors.white.withOpacity(0.5) : Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              tooltip: 'Kembali ke Metode Pembayaran',
            ),
            title: const Text(
              'Cetak Struk',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              BlocBuilder<ReceiptCubit, ReceiptState>(
                bloc: _receiptCubit,
                builder: (context, state) {
                  final isSharing = state is ReceiptSharing;
                  return IconButton(
                    onPressed: isSharing || _isPrinted
                        ? null
                        : () => _receiptCubit.shareReceipt(),
                    icon: isSharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.share_rounded,
                            color: _isPrinted
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white,
                          ),
                    tooltip: 'Bagikan Struk',
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
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

                // Clear cart setelah berhasil print TANPA restore stock
                try {
                  context.read<HomeCubit>().clearCartAfterCheckout();
                } catch (e) {
                  // HomeCubit might not be available in this context
                  print('DEBUG: HomeCubit not available: $e');
                }

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
              } else if (state is ReceiptDownloaded) {
                setState(() {
                  _isPrinted = true;
                });

                // Clear cart setelah berhasil download TANPA restore stock
                try {
                  context.read<HomeCubit>().clearCartAfterCheckout();
                } catch (e) {
                  // HomeCubit might not be available in this context
                  print('DEBUG: HomeCubit not available: $e');
                }

                // Show success dialog with file location
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2E7D32),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Download Berhasil',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'File PDF telah tersimpan di:',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.folder_outlined,
                                color: Color(0xFFFF4B4B),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.filePath,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          // Auto navigate ke home
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                                (route) => false,
                              );
                            }
                          });
                        },
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is ReceiptShared) {
                setState(() {
                  _isPrinted = true;
                });

                // Clear cart setelah berhasil share TANPA restore stock
                try {
                  context.read<HomeCubit>().clearCartAfterCheckout();
                } catch (e) {
                  // HomeCubit might not be available in this context
                  print('DEBUG: HomeCubit not available: $e');
                }

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
                          // Quantity Selector Row
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Jumlah Cetak',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Decrease Button
                                    GestureDetector(
                                      onTap:
                                          _isPrinted || state is ReceiptPrinting
                                          ? null
                                          : () {
                                              if (_printQuantity > 1) {
                                                setState(() {
                                                  _printQuantity--;
                                                });
                                              }
                                            },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                              _printQuantity > 1 &&
                                                  !_isPrinted &&
                                                  state is! ReceiptPrinting
                                              ? const Color(0xFFFF4B4B)
                                              : const Color(0xFFBDBDBD),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    // Quantity Display
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        '$_printQuantity',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F1F1F),
                                        ),
                                      ),
                                    ),
                                    // Increase Button
                                    GestureDetector(
                                      onTap:
                                          _isPrinted || state is ReceiptPrinting
                                          ? null
                                          : () {
                                              if (_printQuantity < 10) {
                                                setState(() {
                                                  _printQuantity++;
                                                });
                                              }
                                            },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                              _printQuantity < 10 &&
                                                  !_isPrinted &&
                                                  state is! ReceiptPrinting
                                              ? const Color(0xFFFF4B4B)
                                              : const Color(0xFFBDBDBD),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Print Button (Full Width)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: state is ReceiptPrinting || _isPrinted
                                  ? null
                                  : () {
                                      _receiptCubit.printViaBluetooth(
                                        copies: _printQuantity,
                                      );
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
                                      Icons.print_rounded,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _printQuantity > 1
                                    ? 'Cetak $_printQuantity Lembar'
                                    : 'Cetak Sekarang',
                                style: const TextStyle(
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
