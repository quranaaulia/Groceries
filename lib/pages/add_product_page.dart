// lib/pages/add_product_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/product_provider.dart';

class AddProductPage extends StatefulWidget {
  final UserModel currentUser;

  const AddProductPage({super.key, required this.currentUser});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controller yang sudah disesuaikan ---
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(
    text: '0',
  ); // Field diskon ditambahkan kembali
  final _stockController = TextEditingController();
  final _imageUrlController =
      TextEditingController(); // Hanya satu field untuk gambar
  final _moqController = TextEditingController(text: '1');
  final _tagsController = TextEditingController();

  // --- Pilihan untuk Dropdown Pengiriman ---
  final List<String> _shippingOptions = [
    'Pengiriman Reguler',
    'Gratis Ongkir (Free Shipping)',
  ];
  String _selectedShipping = 'Pengiriman Reguler'; // Nilai default

  // Add color scheme to match notification page
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final productProvider = context.read<ProductProvider>();

    final imageUrl = _imageUrlController.text;
    final stock = int.tryParse(_stockController.text) ?? 0;

    final newProduct = ProductModel(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      stock: stock,
      thumbnail: imageUrl, // Gambar utama untuk thumbnail
      images: [
        imageUrl,
      ], // Gambar utama juga menjadi satu-satunya gambar di list
      discountPercentage: double.tryParse(_discountController.text) ?? 0.0,
      minimumOrderQuantity: int.tryParse(_moqController.text) ?? 1,
      shippingInformation: _selectedShipping, // Menggunakan nilai dari dropdown
      tags: _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((t) => t.isNotEmpty)
          .toList(),

      // Data yang ditetapkan otomatis
      category: 'groceries',
      rating: 0.0,
      uploaderUsername: widget.currentUser.username,
      availabilityStatus: stock > 0 ? 'In Stock' : 'Out of Stock',

      // Field opsional
      reviews: [],
      weight: null,
      dimensions: null,
      warrantyInformation: null,
      returnPolicy: null,
    );

    await productProvider.addLocalProduct(newProduct);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk baru berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _moqController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        title: Text(
          'Tambah Produk Baru',
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle("Informasi Utama"),
              _buildTextField(
                _titleController,
                'Nama Produk*',
                'Contoh: Pasta Gigi Herbal',
              ),
              _buildTextField(
                _descriptionController,
                'Deskripsi*',
                'Jelaskan keunggulan produk Anda',
                maxLines: 4,
              ),
              _buildTextField(
                _tagsController,
                'Tags (pisahkan koma)',
                'Contoh: organik, segar, promo',
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Harga & Stok"),
              _buildTextField(
                _priceController,
                'Harga (USD)*',
                'Contoh: 4.99',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                _discountController,
                'Diskon (%)*',
                'Contoh: 10',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                _stockController,
                'Jumlah Stok*',
                'Contoh: 150',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                _moqController,
                'Minimal Pembelian*',
                'Contoh: 5',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Gambar & Pengiriman"),
              _buildTextField(
                _imageUrlController,
                'URL Gambar Produk*',
                'URL gambar utama produk',
                keyboardType: TextInputType.url,
              ),

              // --- Dropdown untuk Info Pengiriman ---
              _buildDropdownField(
                value: _selectedShipping,
                label: 'Info Pengiriman*',
                items: _shippingOptions,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedShipping = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submitProduct,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Simpan Produk'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: primaryColor),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.black38),
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
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          alignLabelWithHint: maxLines > 1,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 16 : 12,
          ),
        ),
        validator: (value) {
          if (label.endsWith('*') && (value == null || value.isEmpty)) {
            return '${label.replaceAll('*', '')} tidak boleh kosong';
          }
          if (label.toLowerCase().contains('harga') ||
              label.toLowerCase().contains('stok') ||
              label.toLowerCase().contains('pembelian')) {
            if (double.tryParse(value!) == null || double.parse(value) <= 0) {
              return 'Masukkan angka yang valid dan lebih dari 0';
            }
          }
          if (label.toLowerCase().contains('diskon')) {
            if (double.tryParse(value!) == null ||
                double.parse(value) < 0 ||
                double.parse(value) > 100) {
              return 'Masukkan diskon antara 0-100';
            }
          }
          if (label.toLowerCase().contains('url') && label.endsWith('*')) {
            final uri = Uri.tryParse(value!);
            if (uri == null || !uri.isAbsolute) return 'URL tidak valid';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.poppins(color: Colors.black87),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: primaryColor),
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
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
        dropdownColor: Colors.white,
        validator: (value) => value == null ? 'Pilih salah satu opsi' : null,
      ),
    );
  }
}
