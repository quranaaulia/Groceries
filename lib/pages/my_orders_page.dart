// lib/pages/my_orders_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/user_model.dart'; // <-- IMPORT MODEL USER
import '../providers/order_provider.dart';
import 'submit_review_page.dart'; // <-- IMPORT HALAMAN REVIEW BARU

class MyOrdersPage extends StatelessWidget {
  // --- PERUBAHAN: Menerima objek UserModel lengkap ---
  final UserModel currentUser;

  // Add color scheme to match notification page
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);

  const MyOrdersPage({super.key, required this.currentUser});

  // Helper untuk mendapatkan warna dan teks status
  Map<String, dynamic> _getStatusStyle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return {'color': Colors.orange.shade700, 'text': 'Menunggu Konfirmasi'};
      case OrderStatus.confirmed:
        return {'color': Colors.blue.shade700, 'text': 'Dikonfirmasi'};
      case OrderStatus.processing:
        return {'color': Colors.purple.shade700, 'text': 'Diproses'};
      case OrderStatus.shipped:
        return {'color': Colors.cyan.shade700, 'text': 'Dikirim'};
      case OrderStatus.delivered:
        return {'color': Colors.green.shade700, 'text': 'Selesai'};
      case OrderStatus.cancelled:
        return {'color': Colors.red.shade700, 'text': 'Dibatalkan'};
      default:
        return {'color': Colors.grey, 'text': 'Tidak Diketahui'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Riwayat Pesanan Saya',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.3),
              backgroundColor,
              Colors.white,
              accentColor.withOpacity(0.2),
              accentColor.withOpacity(0.3),
            ],
            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          ),
        ),
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            final myOrders = orderProvider.getOrdersForCustomer(
              currentUser.username,
            );

            if (orderProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (myOrders.isEmpty) {
              return Center(
                child: Text(
                  'Anda belum memiliki riwayat pesanan.',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: myOrders.length,
              itemBuilder: (context, index) {
                final order = myOrders[index];
                final statusStyle = _getStatusStyle(order.status);

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.orderId.substring(0, 8)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusStyle['color'].withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusStyle['text'],
                                style: GoogleFonts.poppins(
                                  color: statusStyle['color'],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(
                          'Penjual: ${order.sellerUsername}',
                          style: GoogleFonts.poppins(),
                        ),
                        Text(
                          'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate)}',
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 10),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.productImageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: GoogleFonts.poppins(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'x${item.quantity}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: primaryColor,
                            ),
                          ),
                        ),

                        // --- ALUR TOMBOL YANG BENAR ---

                        // 1. Tombol untuk konfirmasi penerimaan (muncul saat status 'shipped')
                        if (order.status == OrderStatus.shipped)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.read<OrderProvider>().updateOrderStatus(
                                    order.orderId,
                                    OrderStatus.delivered,
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text("Pesanan Diterima"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // 2. Tombol untuk memberi ulasan (muncul saat 'delivered' dan belum diulas)
                        if (order.status == OrderStatus.delivered &&
                            !(order.hasBeenReviewed ??
                                false)) // <-- PERBAIKAN DI SINI
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SubmitReviewPage(
                                        order: order,
                                        currentUser: currentUser,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.rate_review_outlined),
                                label: const Text("Beri Ulasan"),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: accentColor),
                                  foregroundColor: accentColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
