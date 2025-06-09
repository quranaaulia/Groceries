import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../pages/cart_page.dart';
import 'success_page.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../providers/order_provider.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final void Function() onCheckoutComplete;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.onCheckoutComplete,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _courierController = TextEditingController(
    text: "Gratis Ongkir",
  );

  String? selectedCourier;
  String? selectedPayment;
  String? selectedCurrency = 'USD';

  bool _isFreeShipping = false;

  late NotificationService _notificationService;
  late UserModel? _currentUser;

  final Map<String, double> courierPrices = {
    'JNE': 5.0,
    'SiCepat': 7.0,
    'AnterAja': 4.5,
  };
  final List<String> paymentMethods = ['Transfer Bank', 'QRIS', 'Kartu Kredit'];
  final Map<String, double> currencyRates = {
    'USD': 1.0,
    'IDR': 15000,
    'JPY': 155,
    'EUR': 0.9,
  };

  @override
  void initState() {
    super.initState();
    _checkFreeShipping();
    _initServices();
  }

  void _checkFreeShipping() {
    if (widget.cartItems.isNotEmpty &&
        widget.cartItems.every((item) => item.product.hasFreeShipping)) {
      setState(() {
        _isFreeShipping = true;
        selectedCourier = 'Gratis Ongkir';
      });
    }
  }

  Future<void> _initServices() async {
    if (!Hive.isBoxOpen('notificationBox')) {
      await Hive.openBox<NotificationModel>('notificationBox');
    }
    final userBox = Hive.box<UserModel>('userBox');
    final authService = AuthService(userBox);
    _currentUser = await authService.getLoggedInUser();

    _notificationService = NotificationService(
      Hive.box<NotificationModel>('notificationBox'),
    );

    if (_currentUser != null) {
      _nameController.text = _currentUser!.fullName;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _courierController.dispose();
    super.dispose();
  }

  double get subtotal => widget.cartItems.fold(
    0,
    (sum, item) => sum + item.product.finalPrice * item.quantity,
  );
  double get courierCost =>
      _isFreeShipping ? 0.0 : (courierPrices[selectedCourier] ?? 0.0);
  double get totalUSD => subtotal + courierCost;
  double get totalConverted =>
      totalUSD * (currencyRates[selectedCurrency] ?? 1.0);
  
  // PERBAIKAN: Getter formattedTotal yang diperbaiki
  String get formattedTotal {
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: selectedCurrency == 'IDR' ? 'Rp ' : '\$',
      decimalDigits: selectedCurrency == 'IDR' ? 0 : 2,
    );
    return format.format(totalConverted);
  }

  // --- METHOD LBS YANG DIKEMBALIKAN ---
  Future<void> _getCurrentLocationAndFillAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Layanan lokasi tidak aktif. Mohon aktifkan GPS.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak permanen. Buka pengaturan aplikasi.',
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.country}";
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      }
    }
  }

  void _checkout() async {
    final isCourierValid = _isFreeShipping || selectedCourier != null;
    if (!_formKey.currentState!.validate() ||
        !isCourierValid ||
        selectedPayment == null ||
        _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data dan pastikan Anda login!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String actualSellerUsername =
          widget.cartItems.first.product.uploaderUsername ?? 'admin_store';

      List<OrderProductItem> orderItems = widget.cartItems.map((cartItem) {
        return OrderProductItem(
          productId: cartItem.product.id,
          productName: cartItem.product.title,
          productImageUrl: cartItem.product.thumbnail,
          price: cartItem.product.price,
          discountPercentage: cartItem.product.discountPercentage,
          quantity: cartItem.quantity,
        );
      }).toList();

      final newOrder = OrderModel(
        customerUsername: _currentUser!.username,
        customerName: _nameController.text,
        customerAddress: _addressController.text,
        customerPhoneNumber: _currentUser!.phoneNumber,
        items: orderItems,
        subtotalAmount: subtotal,
        courierService: selectedCourier!,
        courierCost: courierCost,
        totalAmount: totalUSD,
        paymentMethod: selectedPayment!,
        selectedCurrency: selectedCurrency ?? 'USD',
        sellerUsername: actualSellerUsername,
      );

      await context.read<OrderProvider>().addOrder(newOrder);

      // In-App Notification
      await _notificationService.addNotification(
        targetUsername: _currentUser!.username,
        type: NotificationType.orderPaid,
        title: 'Pembayaran Berhasil!',
        body:
            'Pesanan Anda #${newOrder.orderId.substring(0, 8)} sedang diproses.',
        referenceId: newOrder.orderId,
      );
      await _notificationService.addNotification(
        targetUsername: actualSellerUsername,
        type: NotificationType.newOrder,
        title: 'Pesanan Baru!',
        body: 'Anda menerima pesanan baru dari ${_currentUser!.fullName}.',
        referenceId: newOrder.orderId,
      );

      // Push Notification
      await LocalNotificationService.showNotification(
        id: newOrder.hashCode,
        title: 'Pembayaran Berhasil!',
        body:
            'Pesanan Anda #${newOrder.orderId.substring(0, 8)} sedang diproses oleh penjual.',
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessPage()),
        );
        widget.onCheckoutComplete();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat checkout: ${e.toString()}'),
          backgroundColor: Colors.red,
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
          'Checkout',
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Delivery Information
              _buildSectionTitle('Informasi Pengiriman', Icons.location_on),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Nama Penerima',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Alamat Lengkap',
                icon: Icons.home,
                maxLines: 3,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _getCurrentLocationAndFillAddress,
                  icon: Icon(Icons.my_location, color: primaryColor),
                  label: Text(
                    'Gunakan Lokasi Saya',
                    style: GoogleFonts.poppins(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Shipping Method
              _buildSectionTitle('Metode Pengiriman', Icons.local_shipping),
              const SizedBox(height: 16),
              _isFreeShipping
                  ? _buildTextField(
                      controller: _courierController,
                      label: 'Jasa Kirim',
                      icon: Icons.local_shipping,
                      readOnly: true,
                      filled: true,
                      fillColor: primaryColor.withOpacity(0.1),
                    )
                  : _buildDropdown(
                      value: selectedCourier,
                      label: 'Jasa Kirim',
                      hint: 'Pilih Jasa Kirim',
                      items: courierPrices.keys.map((courier) {
                        return DropdownMenuItem(
                          value: courier,
                          child: Text('$courier (+\$${courierPrices[courier]})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedCourier = val),
                      icon: Icons.local_shipping,
                    ),
              const SizedBox(height: 24),

              // Payment Method
              _buildSectionTitle('Pembayaran', Icons.payment),
              const SizedBox(height: 16),
              _buildDropdown(
                value: selectedPayment,
                label: 'Metode Pembayaran',
                hint: 'Pilih Metode Pembayaran',
                items: paymentMethods
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedPayment = val),
                icon: Icons.payment,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                value: selectedCurrency,
                label: 'Mata Uang',
                hint: 'Pilih Mata Uang',
                items: currencyRates.keys
                    .map((currency) => DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedCurrency = val),
                icon: Icons.currency_exchange,
              ),
              const SizedBox(height: 24),

              // Order Summary
              _buildSectionTitle('Ringkasan Pesanan', Icons.receipt),
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPriceRow('Subtotal', subtotal),
                    _buildPriceRow(
                      'Ongkos Kirim',
                      courierCost,
                      isGreen: _isFreeShipping,
                    ),
                    const Divider(height: 24),
                    _buildPriceRow(
                      'Total Pembayaran',
                      totalUSD,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _checkout,
                  child: Text(
                    'Bayar Sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    bool filled = false,
    Color? fillColor,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: primaryColor),
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        filled: filled,
        fillColor: fillColor,
      ),
      validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: primaryColor),
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      validator: (val) => val == null ? 'Wajib dipilih' : null,
    );
  }

  // PERBAIKAN: Method _buildPriceRow yang diperbaiki
  Widget _buildPriceRow(String label, double amount,
      {bool isTotal = false, bool isGreen = false}) {
    
    // Konversi amount ke mata uang yang dipilih
    double convertedAmount = amount * (currencyRates[selectedCurrency] ?? 1.0);
    
    final formattedAmount = NumberFormat.currency(
      locale: 'en_US',
      symbol: selectedCurrency == 'IDR' ? 'Rp ' : '\$',
      decimalDigits: selectedCurrency == 'IDR' ? 0 : 2,
    ).format(convertedAmount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            (isGreen && amount == 0) ? 'GRATIS' : formattedAmount,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isGreen
                  ? Colors.green
                  : isTotal
                      ? primaryColor
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}