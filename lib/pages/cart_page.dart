// lib/pages/cart_page.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/checkout_page.dart';
import 'dart:ui';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final void Function(CartItem) onRemoveFromCart;
  final void Function(CartItem, int) onQuantityChanged;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.onRemoveFromCart,
    required this.onQuantityChanged,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Add color scheme to match notification page
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);

  double priceAfterDiscount(ProductModel product) {
    return product.price * (1 - product.discountPercentage / 100);
  }

  double get totalPrice {
    return widget.cartItems.fold(
      0,
      (sum, item) => sum + priceAfterDiscount(item.product) * item.quantity,
    );
  }

  void clearCartAfterCheckout() {
    // Callback ini akan dipanggil dari checkout_page
    // untuk membersihkan keranjang di state induk (HomePage)
    for (var item in List.from(widget.cartItems)) {
      widget.onRemoveFromCart(item);
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
          'Keranjang',
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
        child: widget.cartItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: primaryColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keranjang kosong',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: primaryColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = widget.cartItems[index];
                        final discountedPrice = priceAfterDiscount(cartItem.product);
                        final totalItemPrice = discountedPrice * cartItem.quantity;
                        final int moq = cartItem.product.minimumOrderQuantity > 0
                            ? cartItem.product.minimumOrderQuantity
                            : 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      cartItem.product.thumbnail,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: primaryColor.withOpacity(0.5),
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    cartItem.product.title,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: accentColor,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      // Show confirmation dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            'Hapus Item',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          content: Text(
                                            'Apakah Anda yakin ingin menghapus ${cartItem.product.title} dari keranjang?',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text(
                                                'Batal',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                // First close the dialog
                                                Navigator.pop(context);
                                                // Then remove the item
                                                setState(() {
                                                  widget.onRemoveFromCart(cartItem);
                                                });
                                                // Show snackbar
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.remove_shopping_cart,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          'Item berhasil dihapus',
                                                          style: GoogleFonts.poppins(color: Colors.white),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: accentColor,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    margin: const EdgeInsets.all(20),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                'Hapus',
                                                style: GoogleFonts.poppins(
                                                  color: accentColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "\$${discountedPrice.toStringAsFixed(2)} x ${cartItem.quantity}",
                                          style: GoogleFonts.poppins(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline),
                                            onPressed: () {
                                              final newQuantity = cartItem.quantity - moq;
                                              if (newQuantity < moq) {
                                                widget.onRemoveFromCart(cartItem);
                                              } else {
                                                widget.onQuantityChanged(cartItem, newQuantity);
                                              }
                                            },
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${cartItem.quantity}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline),
                                            onPressed: () {
                                              final newQuantity = cartItem.quantity + moq;
                                              if (newQuantity <= cartItem.product.stock) {
                                                widget.onQuantityChanged(cartItem, newQuantity);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Stok tidak mencukupi!',
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
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Harga:',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '\$${totalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (widget.cartItems.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Keranjang kosong, tidak bisa checkout',
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
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                    cartItems: widget.cartItems,
                                    onCheckoutComplete: clearCartAfterCheckout,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Checkout',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}