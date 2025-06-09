// lib/pages/submit_review_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';

class SubmitReviewPage extends StatefulWidget {
  final OrderModel order;
  final UserModel currentUser;

  const SubmitReviewPage({
    super.key,
    required this.order,
    required this.currentUser,
  });

  @override
  State<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  // Add color scheme to match notification page
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);

  final Map<String, int> _ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.order.items) {
      _ratings[item.productId] = 0;
      _commentControllers[item.productId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _commentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Update SnackBar styling in _submitAllReviews method
  void _submitAllReviews() {
    final productProvider = context.read<ProductProvider>();
    final orderProvider = context.read<OrderProvider>();

    bool allReviewed = true;

    for (var item in widget.order.items) {
      final rating = _ratings[item.productId]!;
      final comment = _commentControllers[item.productId]!.text;

      if (rating == 0 || comment.isEmpty) {
        allReviewed = false;
        break;
      }

      final newReview = ProductReview(
        rating: rating,
        comment: comment,
        date: DateFormat(
          "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        ).format(DateTime.now().toUtc()),
        reviewerName: widget.currentUser.fullName,
        reviewerEmail: widget.currentUser.email,
      );

      productProvider.addReview(item.productId, newReview);
    }

    if (allReviewed) {
      orderProvider.markOrderAsReviewed(widget.order.orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terima kasih atas ulasan Anda!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mohon isi semua rating dan ulasan produk.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
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
          'Ulas Pesanan #${widget.order.orderId.substring(0, 8)}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ...widget.order.items.map((item) => _buildReviewForm(item)).toList(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitAllReviews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Kirim Semua Ulasan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm(OrderProductItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.productImageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                item.productName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(color: Colors.grey),
            Text(
              'Bagaimana rating Anda?',
              style: GoogleFonts.poppins(
                color: secondaryColor,
                fontSize: 16,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    index < _ratings[item.productId]!
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () =>
                      setState(() => _ratings[item.productId] = index + 1),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentControllers[item.productId],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                labelText: 'Tulis pengalaman Anda...',
                labelStyle: GoogleFonts.poppins(color: primaryColor),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
              ),
              style: GoogleFonts.poppins(),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
