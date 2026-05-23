import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temannetra/main.dart';

void main() {
  testWidgets('TemanNetra smoke test', (WidgetTester tester) async {
    // Memuat aplikasi dalam ProviderScope Riverpod untuk menguji integrasi awal
    await tester.pumpWidget(
      const ProviderScope(
        child: TemanNetraApp(),
      ),
    );

    // Memverifikasi teks selamat datang TemanNetra muncul di layar
    expect(find.textContaining('TemanNetra'), findsAtLeastNWidgets(1));
  });
}
