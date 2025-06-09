import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  final UserModel currentUser; // Menerima objek user yang sedang login

  const NotificationPage({super.key, required this.currentUser});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late NotificationService _notificationService;
  List<NotificationModel> _notifications = [];

  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);

  @override
  void initState() {
    super.initState();
    _initServiceAndLoadNotifications();
  }

  Future<void> _initServiceAndLoadNotifications() async {
    // Pastikan Hive Box sudah terbuka
    if (!Hive.isBoxOpen('notificationBox')) {
      await Hive.openBox<NotificationModel>('notificationBox');
    }
    _notificationService = NotificationService(Hive.box<NotificationModel>('notificationBox'));
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = _notificationService.getNotificationsForUser(widget.currentUser.username);
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationService.markNotificationAsRead(notification);
      _loadNotifications(); // Reload notifikasi setelah diupdate
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
          'Notifikasi',
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
        child: _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 80, color: primaryColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada notifikasi saat ini.',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: primaryColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: notification.isRead 
                                  ? Colors.grey.withOpacity(0.2)
                                  : primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: notification.isRead
                                    ? Colors.grey.withOpacity(0.1)
                                    : primaryColor.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: notification.isRead
                                    ? Colors.grey.withOpacity(0.1)
                                    : primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: notification.isRead
                                    ? Colors.grey
                                    : primaryColor,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: GoogleFonts.poppins(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  notification.body,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy, HH:mm')
                                          .format(notification.timestamp),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: notification.isRead
                                ? null
                                : Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () => _markAsRead(notification),
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

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderPaid:
        return Icons.payment;
      case NotificationType.orderShipped:
        return Icons.local_shipping;
      case NotificationType.newOrder:
        return Icons.inbox;
      case NotificationType.orderCompleted:
        return Icons.check_circle;
      case NotificationType.custom:
      default:
        return Icons.notifications;
    }
  }
}
