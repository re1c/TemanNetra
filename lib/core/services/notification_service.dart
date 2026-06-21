import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/help_request/domain/models/help_request_model.dart';
import '../../features/help_request/presentation/screens/help_request_detail_screen.dart';
import '../../main.dart';

part 'notification_service.g.dart';

/// Penanganan pesan masuk saat aplikasi berada di latar belakang (background/terminated).
/// Wajib dianotasi @pragma('vm:entry-point') agar dikenali oleh mesin isolate Dart background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'Menerima notifikasi di latar belakang: ${message.messageId}',
    name: 'NotificationService',
    error: message.data,
  );
}

@riverpod
class NotificationService extends _$NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  FutureOr<void> build() async {
    // Registrasi handler untuk pesan latar belakang
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Registrasi listener untuk pesan masuk saat aplikasi aktif (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        'Menerima notifikasi di latar depan: ${message.notification?.title}',
        name: 'NotificationService',
        error: message.data,
      );
    });

    // Menangani pesan awal jika aplikasi dibuka dari keadaan mati (terminated)
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message);
      }
    });

    // Menangani aksi ketukan pada notifikasi untuk membuka aplikasi dari background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        'Aplikasi terbuka via ketukan notifikasi: ${message.messageId}',
        name: 'NotificationService',
      );
      _handleNotificationClick(message);
    });

    // Memantau status autentikasi secara reaktif untuk langganan topik relawan
    ref.listen<AsyncValue<UserModel?>>(authControllerProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null && user.role == UserRole.volunteer) {
        requestPermission().then((granted) {
          if (granted) subscribeToVolunteersTopic();
        });
      } else {
        unsubscribeFromVolunteersTopic();
      }
    });

    // Pengecekan kondisi awal saat inisialisasi aplikasi (restore session)
    final initialUser = ref.read(authControllerProvider).valueOrNull;
    if (initialUser != null && initialUser.role == UserRole.volunteer) {
      requestPermission().then((granted) {
        if (granted) subscribeToVolunteersTopic();
      });
    }
  }

  /// Meminta izin notifikasi runtime secara interaktif (Wajib untuk Android 13+ & iOS).
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      
      developer.log(
        'Status izin notifikasi: ${settings.authorizationStatus}',
        name: 'NotificationService',
      );
      return isAuthorized;
    } catch (e, stackTrace) {
      developer.log(
        'Gagal meminta izin notifikasi runtime',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Mendaftarkan token perangkat relawan ke topik siaran notifikasi 'volunteers'.
  Future<void> subscribeToVolunteersTopic() async {
    try {
      await _messaging.subscribeToTopic('volunteers');
      developer.log(
        'Sukses berlangganan ke topik: volunteers',
        name: 'NotificationService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Gagal berlangganan ke topik volunteers',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Menghapus pendaftaran token perangkat relawan dari topik 'volunteers'.
  Future<void> unsubscribeFromVolunteersTopic() async {
    try {
      await _messaging.unsubscribeFromTopic('volunteers');
      developer.log(
        'Sukses berhenti berlangganan dari topik: volunteers',
        name: 'NotificationService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Gagal membatalkan langganan topik volunteers',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Memproses deep-link ke detail bantuan berdasarkan data payload notifikasi.
  Future<void> _handleNotificationClick(RemoteMessage message) async {
    final data = message.data;
    final ticketId = data['ticketId'] as String?;
    if (ticketId != null && ticketId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('help_requests')
            .doc(ticketId)
            .get();
        if (doc.exists) {
          final ticket = HelpRequestModel.fromMap(doc.data()!, doc.id);
          navigatorKey.currentState?.push(
            MaterialPageRoute<void>(
              builder: (context) => HelpRequestDetailScreen(ticket: ticket),
            ),
          );
        }
      } catch (e, stackTrace) {
        developer.log(
          'Gagal melakukan deep-link ke HelpRequestDetailScreen',
          name: 'NotificationService',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
