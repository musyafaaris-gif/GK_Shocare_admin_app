import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GK Shoecare Admin',
      theme: ThemeData(useMaterial3: true),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final pinController = TextEditingController();
  static const String pinBenar = '12345';
  String? errorText;

  void cekPin() {
    if (pinController.text == pinBenar) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DaftarPesananPage()),
      );
    } else {
      setState(() => errorText = 'PIN salah');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GK. SHOECARE ADMIN',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'PIN',
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                  onPressed: cekPin,
                  child: const Text('Masuk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Pesanan {
  final String jenisBarang;
  final String treatment;
  final bool warnaPutih;
  final int jumlah;
  final int hargaSatuan;
  final int subtotal;
  final String tanggalSelesai;
  final String fotoUrl;
  final DateTime createdAt;

  Pesanan({
    required this.jenisBarang,
    required this.treatment,
    required this.warnaPutih,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    required this.tanggalSelesai,
    required this.fotoUrl,
    required this.createdAt,
  });

  factory Pesanan.fromFirestore(Map<String, dynamic> fields) {
    String getString(String key) => fields[key]?['stringValue'] ?? '';
    int getInt(String key) => int.tryParse(fields[key]?['integerValue']?.toString() ?? '0') ?? 0;
    bool getBool(String key) => fields[key]?['booleanValue'] ?? false;

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(fields['createdAt']?['timestampValue'] ?? '');
    } catch (_) {
      createdAt = DateTime.now();
    }

    return Pesanan(
      jenisBarang: getString('jenisBarang'),
      treatment: getString('treatment'),
      warnaPutih: getBool('warnaPutih'),
      jumlah: getInt('jumlah'),
      hargaSatuan: getInt('hargaSatuan'),
      subtotal: getInt('subtotal'),
      tanggalSelesai: getString('tanggalSelesai'),
      fotoUrl: getString('fotoUrl'),
      createdAt: createdAt,
    );
  }
}

String formatRupiah(int angka) {
  final s = angka.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return 'Rp$buffer';
}

String formatWaktu(DateTime d) {
  const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  final jam = d.hour.toString().padLeft(2, '0');
  final menit = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${bulan[d.month]} ${d.year}, $jam:$menit';
}

class DaftarPesananPage extends StatefulWidget {
  const DaftarPesananPage({super.key});

  @override
  State<DaftarPesananPage> createState() => _DaftarPesananPageState();
}

class _DaftarPesananPageState extends State<DaftarPesananPage> {
  static const String firestoreProjectId = 'gk-shoecare';
  List<Pesanan> daftarPesanan = [];
  bool sedangMemuat = true;
  String? pesanError;

  @override
  void initState() {
    super.initState();
    muatPesanan();
  }

  Future<void> muatPesanan() async {
    setState(() {
      sedangMemuat = true;
      pesanError = null;
    });
    try {
      final uri = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$firestoreProjectId/databases/(default)/documents/pesanan');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Gagal memuat data (${response.statusCode})');
      }
      final data = jsonDecode(response.body);
      final docs = (data['documents'] as List?) ?? [];
      final hasil = docs
          .map((doc) => Pesanan.fromFirestore(doc['fields'] as Map<String, dynamic>))
          .toList();
      hasil.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        daftarPesanan = hasil;
        sedangMemuat = false;
      });
    } catch (e) {
      setState(() {
        pesanError = 'Gagal memuat pesanan: $e';
        sedangMemuat = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: muatPesanan),
        ],
      ),
      body: sedangMemuat
          ? const Center(child: CircularProgressIndicator())
          : pesanError != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(pesanError!)))
              : daftarPesanan.isEmpty
                  ? const Center(child: Text('Belum ada pesanan'))
                  : RefreshIndicator(
                      onRefresh: muatPesanan,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: daftarPesanan.length,
                        itemBuilder: (context, index) {
                          final p = daftarPesanan[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      p.fotoUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image)),
                                      loadingBuilder: (context, child, progress) => progress == null
                                          ? child
                                          : const SizedBox(
                                              width: 70,
                                              height: 70,
                                              child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${p.jenisBarang} - ${p.treatment}',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${p.jumlah}x${p.warnaPutih ? ' (putih)' : ''} • ${formatRupiah(p.subtotal)}'),
                                        Text('Selesai: ${p.tanggalSelesai}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                        Text('Masuk: ${formatWaktu(p.createdAt)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
