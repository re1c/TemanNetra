// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get helpRequestDetailsTitle => 'Detail Bantuan';

  @override
  String get backButtonLabel => 'Kembali';

  @override
  String get volunteerWaitingAnnouncement =>
      'Permintaan bantuan berhasil dikirim. Sedang mencari relawan terdekat. Mohon tunggu, Anda dapat mengirim pesan setelah relawan terhubung.';

  @override
  String get ticketStatusPending => 'Menunggu Relawan';

  @override
  String get ticketStatusClaimed => 'Sedang Dibantu';

  @override
  String get ticketStatusResolved => 'Selesai';

  @override
  String get securityWarningAnnouncement =>
      'Peringatan Keamanan: Jangan pernah menyebutkan kata sandi atau informasi keuangan Anda.';
}
