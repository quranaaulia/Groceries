import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class FavoritePage extends StatefulWidget {
  final List<ProductModel> favoriteProducts;

  const FavoritePage({super.key, required this.favoriteProducts});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  // Add color scheme to match notification page
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);

  void removeFromFavorites(ProductModel product) {
    setState(() {
      widget.favoriteProducts.remove(product);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.favorite_border,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              '${product.title} dihapus dari favorit',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: accentColor, // Using our accent color (orange)
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating, // Makes it float above content
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          right: 20,
          left: 20,
        ),
        elevation: 6,
        action: SnackBarAction(
          label: 'BATALKAN',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              widget.favoriteProducts.add(product);
            });
          },
        ),
      ),
    );
  }

  void addToFavorites(ProductModel product) {
    setState(() {
      widget.favoriteProducts.add(product);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.favorite,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              '${product.title} ditambahkan ke favorit',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor, // Using our primary color (green)
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          right: 20,
          left: 20,
        ),
        elevation: 6,
        action: SnackBarAction(
          label: 'BATALKAN',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              widget.favoriteProducts.remove(product);
            });
          },
        ),
      ),
    );
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
          'Favorit',
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
        child: widget.favoriteProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 80,
                      color: primaryColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada produk favorit',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: primaryColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = widget.favoriteProducts[index];
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
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product.images.first,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              product.title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
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
                                    "\$${product.price.toStringAsFixed(2)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.favorite,
                                color: accentColor,
                                size: 28,
                              ),
                              onPressed: () => removeFromFavorites(product),
                            ),
                            onTap: () {
                              // Navigate to detail page
                            },
                          ),
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
