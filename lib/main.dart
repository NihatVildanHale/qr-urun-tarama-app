import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tarım Deposu Ürün Tarama',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const UrunTaramaSayfasi(),
    );
  }
}

const String backendUrl = 'https://tarimdeposu-backend.onrender.com';

class Urun {
  final String isim;
  final String sku;
  final num fiyat;
  final String paraBirimi;
  final int stok;
  final String? resimUrl;
  final String aciklama;
  final String? marka;

  Urun({
    required this.isim,
    required this.sku,
    required this.fiyat,
    required this.paraBirimi,
    required this.stok,
    required this.resimUrl,
    required this.aciklama,
    required this.marka,
  });

  factory Urun.fromJson(Map<String, dynamic> j) => Urun(
        isim: j['name'] ?? 'İsimsiz Ürün',
        sku: j['sku'] ?? '',
        fiyat: (j['price'] ?? 0) as num,
        paraBirimi: j['currency'] ?? 'TL',
        stok: (j['stock'] ?? 0) as int,
        resimUrl: j['image'],
        aciklama: j['description'] ?? '',
        marka: j['brand'],
      );
}

class UrunTaramaSayfasi extends StatefulWidget {
  const UrunTaramaSayfasi({super.key});

  @override
  State<UrunTaramaSayfasi> createState() => _UrunTaramaSayfasiState();
}

class _UrunTaramaSayfasiState extends State<UrunTaramaSayfasi> {
  bool isProcessing = false;
  bool isLoading = false;

  Future<void> _urunAra(String gelenKod) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      isLoading = true;
    });

    final String temizKod = gelenKod.trim();

    try {
      final uri = Uri.parse('$backendUrl/product?code=${Uri.encodeComponent(temizKod)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final urun = Urun.fromJson(data);
        if (mounted) _urunPenceresiGoster(urun);
      } else if (response.statusCode == 404) {
        if (mounted) _uyariGoster('Ürün bulunamadı (Kod: $temizKod)');
      } else {
        if (mounted) _uyariGoster('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) _uyariGoster('Bağlantı hatası, tekrar deneyin');
    } finally {
      if (mounted) setState(() => isLoading = false);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => isProcessing = false);
    }
  }

  void _urunPenceresiGoster(Urun urun) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (urun.resimUrl != null && urun.resimUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      urun.resimUrl!,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: const Icon(Icons.inventory_2, size: 60, color: Colors.green),
                  ),
                const SizedBox(height: 16),
                Text(
                  urun.isim,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (urun.marka != null && urun.marka!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    urun.marka!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${urun.fiyat} ${urun.paraBirimi}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: urun.stok > 0 ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    urun.stok > 0 ? 'Stokta: ${urun.stok} adet' : 'Stokta Yok',
                    style: TextStyle(
                      color: urun.stok > 0 ? Colors.green[800] : Colors.red[800],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stok Kodu: ${urun.sku}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (urun.aciklama.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    urun.aciklama.length > 300
                        ? '${urun.aciklama.substring(0, 300)}...'
                        : urun.aciklama,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                    textAlign: TextAlign.left,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tarım Deposu Tarayıcı'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Kamera hatası: ${error.errorCode}\n${error.errorDetails?.message ?? ""}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _urunAra(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Tarama çerçevesi
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isProcessing ? Colors.orange : Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Üst bilgi yazısı
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isProcessing ? 'Sorgulanıyor...' : 'Karekodu çerçeveye getirin',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}