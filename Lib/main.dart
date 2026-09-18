import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

const String firestoreProjectId = 'gk-shoecare';
const String firestoreBase =
    'https://firestore.googleapis.com/v1/projects/$firestoreProjectId/databases/(default)/documents';

const List<String> daftarStatus = ['Menunggu Verifikasi', 'Sudah Diambil', 'Dikerjakan', 'Sudah Selesai'];

Color warnaStatus(String status) {
  switch (status) {
    case 'Menunggu Verifikasi':
      return Colors.red[700]!;
    case 'Dikerjakan':
      return Colors.orange[700]!;
    case 'Sudah Selesai':
      return Colors.green[700]!;
    default:
      return Colors.blueGrey;
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

double angkaDouble(Map<String, dynamic> fields, String key) {
  final f = fields[key];
  if (f == null) return 0;
  if (f['doubleValue'] != null) return (f['doubleValue'] as num).toDouble();
  if (f['integerValue'] != null) return double.tryParse(f['integerValue'].toString()) ?? 0;
  return 0;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final pinController = TextEditingController();
  String? errorText;

  Future<void> cekPin() async {
    final prefs = await SharedPreferences.getInstance();
    final adaPinTersimpan = prefs.containsKey('admin_pin');
    final pinTersimpan = prefs.getString('admin_pin') ?? '12345';
    if (pinController.text == pinTersimpan) {
      if (!mounted) return;
      if (!adaPinTersimpan) {
        // PIN masih default (belum pernah diganti) -> paksa ganti dulu sebelum masuk
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForceGantiPinPage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminHomePage()));
      }
    } else {
      setState(() => errorText = 'PIN salah');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      body: SafeArea(
        child: Center(
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
      ),
    );
  }
}

class ForceGantiPinPage extends StatefulWidget {
  const ForceGantiPinPage({super.key});

  @override
  State<ForceGantiPinPage> createState() => _ForceGantiPinPageState();
}

class _ForceGantiPinPageState extends State<ForceGantiPinPage> {
  final pinBaruController = TextEditingController();
  final pinKonfirmasiController = TextEditingController();
  String? errorText;

  Future<void> simpanPinBaru() async {
    if (pinBaruController.text.trim().length < 4) {
      setState(() => errorText = 'PIN minimal 4 digit');
      return;
    }
    if (pinBaruController.text != pinKonfirmasiController.text) {
      setState(() => errorText = 'Konfirmasi PIN tidak cocok');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_pin', pinBaruController.text);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminHomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Amankan Akun Admin',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'PIN kamu masih default. Silakan buat PIN baru sebelum melanjutkan.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: pinBaruController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'PIN Baru',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinKonfirmasiController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Konfirmasi PIN Baru',
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
                    onPressed: simpanPinBaru,
                    child: const Text('Simpan & Lanjutkan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('GK. SHOECARE ADMIN'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Pesanan Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DaftarPesananPage()));
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.price_change),
                title: const Text('Kelola Treatment & Harga', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KelolaTreatmentPage()));
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Kelola Jenis Barang', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KelolaJenisBarangPage()));
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inbox),
                title: const Text('Kelola Loker', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KelolaLokerPage()));
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delivery_dining),
                title: const Text('Kelola Ongkir', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KelolaOngkirPage()));
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Kelola Lokasi Toko', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KelolaLokasiPage()));
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Pencatatan Keuangan', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KeuanganPage()));
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.contacts),
                title: const Text('Kontak Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KontakPage()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final pinLamaController = TextEditingController();
  final pinBaruController = TextEditingController();
  final pinKonfirmasiController = TextEditingController();

  Future<void> gantiPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pinTersimpan = prefs.getString('admin_pin') ?? '12345';
    if (pinLamaController.text != pinTersimpan) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN lama salah')));
      return;
    }
    if (pinBaruController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN baru wajib diisi')));
      return;
    }
    if (pinBaruController.text != pinKonfirmasiController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi PIN tidak cocok')));
      return;
    }
    await prefs.setString('admin_pin', pinBaruController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN berhasil diubah')));
    pinLamaController.clear();
    pinBaruController.clear();
    pinKonfirmasiController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ganti PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: pinLamaController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'PIN Lama',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinBaruController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'PIN Baru',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinKonfirmasiController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Konfirmasi PIN Baru',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                  onPressed: gantiPin,
                  child: const Text('Simpan PIN Baru'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullscreenFotoPage extends StatelessWidget {
  final String url;
  const FullscreenFotoPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto Barang'),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            child: Image.network(
              url,
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}

class Pesanan {
  final String id;
  final String namaCustomer;
  final String noWaCustomer;
  final String jenisBarang;
  final String treatment;
  final bool warnaPutih;
  final int jumlah;
  final int hargaSatuan;
  final int subtotal;
  final String tanggalSelesai;
  final String fotoUrl;
  final String status;
  final String lokerNomor;
  final String metodePesan;
  final int ongkir;
  final DateTime createdAt;

  Pesanan({
    required this.id,
    required this.namaCustomer,
    required this.noWaCustomer,
    required this.jenisBarang,
    required this.treatment,
    required this.warnaPutih,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    required this.tanggalSelesai,
    required this.fotoUrl,
    required this.status,
    required this.lokerNomor,
    required this.metodePesan,
    required this.ongkir,
    required this.createdAt,
  });

  factory Pesanan.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>;
    final name = doc['name'] as String;
    String getString(String key) => fields[key]?['stringValue'] ?? '';
    int getInt(String key) => int.tryParse(fields[key]?['integerValue']?.toString() ?? '0') ?? 0;
    bool getBool(String key) => fields[key]?['booleanValue'] ?? false;

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(fields['createdAt']?['timestampValue'] ?? '');
    } catch (_) {
      createdAt = DateTime.now();
    }
    final statusMentah = getString('status');

    return Pesanan(
      id: name.split('/').last,
      namaCustomer: getString('namaCustomer'),
      noWaCustomer: getString('noWaCustomer'),
      jenisBarang: getString('jenisBarang'),
      treatment: getString('treatment'),
      warnaPutih: getBool('warnaPutih'),
      jumlah: getInt('jumlah'),
      hargaSatuan: getInt('hargaSatuan'),
      subtotal: getInt('subtotal'),
      tanggalSelesai: getString('tanggalSelesai'),
      fotoUrl: getString('fotoUrl'),
      status: statusMentah.isEmpty ? 'Sudah Diambil' : statusMentah,
      lokerNomor: getString('lokerNomor'),
      metodePesan: getString('metodePesan'),
      ongkir: getInt('ongkir'),
      createdAt: createdAt,
    );
  }
}

class DaftarPesananPage extends StatefulWidget {
  const DaftarPesananPage({super.key});

  @override
  State<DaftarPesananPage> createState() => _DaftarPesananPageState();
}

class _DaftarPesananPageState extends State<DaftarPesananPage> {
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
      final uri = Uri.parse('$firestoreBase/pesanan');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Gagal memuat data (${response.statusCode})');
      }
      final data = jsonDecode(response.body);
      final docs = (data['documents'] as List?) ?? [];
      final hasil = docs.map((doc) => Pesanan.fromFirestore(doc)).toList();
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

  Future<void> ubahStatus(Pesanan p, String statusBaru) async {
    final statusLama = p.status;
    setState(() {
      final index = daftarPesanan.indexWhere((x) => x.id == p.id);
      if (index != -1) {
        daftarPesanan[index] = Pesanan(
          id: p.id,
          namaCustomer: p.namaCustomer,
          noWaCustomer: p.noWaCustomer,
          jenisBarang: p.jenisBarang,
          treatment: p.treatment,
          warnaPutih: p.warnaPutih,
          jumlah: p.jumlah,
          hargaSatuan: p.hargaSatuan,
          subtotal: p.subtotal,
          tanggalSelesai: p.tanggalSelesai,
          fotoUrl: p.fotoUrl,
          status: statusBaru,
          lokerNomor: p.lokerNomor,
          metodePesan: p.metodePesan,
          ongkir: p.ongkir,
          createdAt: p.createdAt,
        );
      }
    });
    final uri = Uri.parse('$firestoreBase/pesanan/${p.id}').replace(queryParameters: {
      'updateMask.fieldPaths': ['status'],
    });
    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'status': {'stringValue': statusBaru},
        }
      }),
    );

    // Kalau gagal di server, kembalikan tampilan ke status lama dan beri tahu admin
    // supaya data lokal tidak tampak berubah padahal sebenarnya belum tersimpan.
    if (response.statusCode != 200) {
      if (!mounted) return;
      setState(() {
        final index = daftarPesanan.indexWhere((x) => x.id == p.id);
        if (index != -1) {
          daftarPesanan[index] = Pesanan(
            id: p.id,
            namaCustomer: p.namaCustomer,
            noWaCustomer: p.noWaCustomer,
            jenisBarang: p.jenisBarang,
            treatment: p.treatment,
            warnaPutih: p.warnaPutih,
            jumlah: p.jumlah,
            hargaSatuan: p.hargaSatuan,
            subtotal: p.subtotal,
            tanggalSelesai: p.tanggalSelesai,
            fotoUrl: p.fotoUrl,
            status: statusLama,
            lokerNomor: p.lokerNomor,
            metodePesan: p.metodePesan,
            ongkir: p.ongkir,
            createdAt: p.createdAt,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ubah status (${response.statusCode}), coba lagi.')),
      );
      return;
    }

    // Status berhasil diubah. Kalau ini transisi PERTAMA keluar dari 'Menunggu Verifikasi'
    // (artinya admin baru saja konfirmasi bukti transfer valid), catat otomatis sebagai
    // pemasukan di halaman Keuangan supaya admin tidak perlu input manual lagi.
    if (statusLama == 'Menunggu Verifikasi' && statusBaru != 'Menunggu Verifikasi') {
      await catatPemasukanOtomatis(p);
    }
  }

  Future<void> catatPemasukanOtomatis(Pesanan p) async {
    final totalItem = p.subtotal + p.ongkir;
    await http.post(
      Uri.parse('$firestoreBase/keuangan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'jenis': {'stringValue': 'masuk'},
          'keterangan': {'stringValue': '${p.namaCustomer} - ${p.treatment} (${p.jenisBarang})'},
          'jumlah': {'integerValue': totalItem.toString()},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      }),
    );
  }

  Future<void> hapusPesanan(Pesanan p) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pesanan?'),
        content: Text('Pesanan ${p.jenisBarang} - ${p.treatment} akan dihapus permanen. Yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Hapus')),
        ],
      ),
    );
    if (konfirmasi != true) return;
    final response = await http.delete(Uri.parse('$firestoreBase/pesanan/${p.id}'));
    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() => daftarPesanan.removeWhere((x) => x.id == p.id));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pesanan (${response.statusCode}), coba lagi.')),
      );
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
      body: SafeArea(
        child: sedangMemuat
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context,
                                                MaterialPageRoute(builder: (context) => FullscreenFotoPage(url: p.fotoUrl)));
                                          },
                                          child: ClipRRect(
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
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${p.jenisBarang} - ${p.treatment}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('${p.jumlah}x${p.warnaPutih ? ' (putih)' : ''} • ${formatRupiah(p.subtotal)}'),
                                              if (p.namaCustomer.isNotEmpty)
                                                Text('${p.namaCustomer} • ${p.noWaCustomer}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                              if (p.metodePesan.isNotEmpty)
                                                Text(
                                                    p.metodePesan == 'Loker'
                                                        ? 'Loker No. ${p.lokerNomor}'
                                                        : '${p.metodePesan}${p.ongkir > 0 ? ' (Ongkir ${formatRupiah(p.ongkir)})' : ''}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text('Selesai: ${p.tanggalSelesai}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                              Text('Masuk: ${formatWaktu(p.createdAt)}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => hapusPesanan(p),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                          color: warnaStatus(p.status), borderRadius: BorderRadius.circular(8)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: p.status,
                                          isExpanded: true,
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                          items: daftarStatus
                                              .map((s) => DropdownMenuItem(
                                                    value: s,
                                                    child: Text(s, style: TextStyle(color: warnaStatus(s))),
                                                  ))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) ubahStatus(p, val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class JenisBarangDoc {
  final String id;
  final String nama;
  JenisBarangDoc({required this.id, required this.nama});

  factory JenisBarangDoc.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final name = doc['name'] as String;
    return JenisBarangDoc(id: name.split('/').last, nama: fields['nama']?['stringValue'] ?? '');
  }
}

class KelolaJenisBarangPage extends StatefulWidget {
  const KelolaJenisBarangPage({super.key});

  @override
  State<KelolaJenisBarangPage> createState() => _KelolaJenisBarangPageState();
}

class _KelolaJenisBarangPageState extends State<KelolaJenisBarangPage> {
  List<JenisBarangDoc> daftar = [];
  bool sedangMemuat = true;

  @override
  void initState() {
    super.initState();
    muatData();
  }

  Future<void> muatData() async {
    setState(() => sedangMemuat = true);
    final response = await http.get(Uri.parse('$firestoreBase/jenisBarang'));
    final data = jsonDecode(response.body);
    final docs = (data['documents'] as List?) ?? [];
    final hasil = docs.map((doc) => JenisBarangDoc.fromFirestore(doc)).toList();
    hasil.sort((a, b) => a.nama.compareTo(b.nama));
    setState(() {
      daftar = hasil;
      sedangMemuat = false;
    });
  }

  Future<void> tambahJenisBarang(String nama) async {
    await http.post(
      Uri.parse('$firestoreBase/jenisBarang'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {'nama': {'stringValue': nama}}
      }),
    );
    muatData();
  }

  Future<void> hapusJenisBarang(JenisBarangDoc j) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jenis barang?'),
        content: Text('"${j.nama}" akan dihapus. Treatment yang sudah ada di kategori ini tidak ikut terhapus. Yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Hapus')),
        ],
      ),
    );
    if (konfirmasi != true) return;
    await http.delete(Uri.parse('$firestoreBase/jenisBarang/${j.id}'));
    muatData();
  }

  void bukaFormTambah() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambah Jenis Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nama Jenis Barang')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      tambahJenisBarang(controller.text.trim());
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('Kelola Jenis Barang'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: bukaFormTambah,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: sedangMemuat
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: daftar.length,
                itemBuilder: (context, index) {
                  final j = daftar[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(j.nama),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => hapusJenisBarang(j),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class LokerInfo {
  final String nomor;
  final bool terisi;
  final String namaCustomer;
  LokerInfo({required this.nomor, required this.terisi, required this.namaCustomer});

  factory LokerInfo.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final name = doc['name'] as String;
    return LokerInfo(
      nomor: name.split('/').last,
      terisi: fields['terisi']?['booleanValue'] ?? false,
      namaCustomer: fields['namaCustomer']?['stringValue'] ?? '',
    );
  }
}

class KelolaLokerPage extends StatefulWidget {
  const KelolaLokerPage({super.key});

  @override
  State<KelolaLokerPage> createState() => _KelolaLokerPageState();
}

class _KelolaLokerPageState extends State<KelolaLokerPage> {
  List<LokerInfo> daftar = [];
  bool sedangMemuat = true;
  bool sedangIsi = false;

  @override
  void initState() {
    super.initState();
    muatLoker();
  }

  Future<void> muatLoker() async {
    setState(() => sedangMemuat = true);
    final response = await http.get(Uri.parse('$firestoreBase/lokers'));
    final data = jsonDecode(response.body);
    final docs = (data['documents'] as List?) ?? [];
    final hasil = docs.map((doc) => LokerInfo.fromFirestore(doc)).toList();
    hasil.sort((a, b) => (int.tryParse(a.nomor) ?? 0).compareTo(int.tryParse(b.nomor) ?? 0));
    setState(() {
      daftar = hasil;
      sedangMemuat = false;
    });
  }

  Future<void> isiDataAwal() async {
    setState(() => sedangIsi = true);
    for (int i = 1; i <= 15; i++) {
      await http.post(
        Uri.parse('$firestoreBase/lokers').replace(queryParameters: {'documentId': '$i'}),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'terisi': {'booleanValue': false},
            'namaCustomer': {'stringValue': ''},
          }
        }),
      );
    }
    setState(() => sedangIsi = false);
    muatLoker();
  }

  Future<void> kosongkanLoker(LokerInfo l) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kosongkan Loker ${l.nomor}?'),
        content: const Text('Pastikan barang sudah diambil secara fisik dari loker ini. Yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Kosongkan')),
        ],
      ),
    );
    if (konfirmasi != true) return;
    final uri = Uri.parse('$firestoreBase/lokers/${l.nomor}').replace(queryParameters: {
      'updateMask.fieldPaths': ['terisi', 'namaCustomer'],
    });
    await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'terisi': {'booleanValue': false},
          'namaCustomer': {'stringValue': ''},
        }
      }),
    );
    muatLoker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('Kelola Loker'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: muatLoker)],
      ),
      body: SafeArea(
        child: sedangMemuat
            ? const Center(child: CircularProgressIndicator())
            : daftar.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Belum ada data loker.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                            onPressed: sedangIsi ? null : isiDataAwal,
                            child: sedangIsi
                                ? const SizedBox(
                                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Isi Data Awal (15 Loker)'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: daftar.length,
                    itemBuilder: (context, index) {
                      final l = daftar[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: l.terisi ? Colors.red[400] : Colors.green[400],
                            child: Text(l.nomor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(l.terisi ? 'Terisi' : 'Kosong'),
                          subtitle: l.terisi && l.namaCustomer.isNotEmpty ? Text(l.namaCustomer) : null,
                          trailing: l.terisi
                              ? TextButton(
                                  onPressed: () => kosongkanLoker(l),
                                  child: const Text('Kosongkan'),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class OngkirTier {
  final String id;
  final double jarakMin;
  final double jarakMax;
  final int tarif;
  OngkirTier({required this.id, required this.jarakMin, required this.jarakMax, required this.tarif});

  factory OngkirTier.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>;
    final name = doc['name'] as String;
    int getInt(String key) => int.tryParse(fields[key]?['integerValue']?.toString() ?? '0') ?? 0;
    return OngkirTier(
      id: name.split('/').last,
      jarakMin: angkaDouble(fields, 'jarakMin'),
      jarakMax: angkaDouble(fields, 'jarakMax'),
      tarif: getInt('tarif'),
    );
  }
}

class KelolaOngkirPage extends StatefulWidget {
  const KelolaOngkirPage({super.key});

  @override
  State<KelolaOngkirPage> createState() => _KelolaOngkirPageState();
}

class _KelolaOngkirPageState extends State<KelolaOngkirPage> {
  List<OngkirTier> daftar = [];
  bool sedangMemuat = true;

  @override
  void initState() {
    super.initState();
    muatData();
  }

  Future<void> muatData() async {
    setState(() => sedangMemuat = true);
    final response = await http.get(Uri.parse('$firestoreBase/ongkirTiers'));
    final data = jsonDecode(response.body);
    final docs = (data['documents'] as List?) ?? [];
    final hasil = docs.map((doc) => OngkirTier.fromFirestore(doc)).toList();
    hasil.sort((a, b) => a.jarakMin.compareTo(b.jarakMin));
    setState(() {
      daftar = hasil;
      sedangMemuat = false;
    });
  }

  Future<void> simpanTier({String? id, required double min, required double max, required int tarif}) async {
    final body = jsonEncode({
      'fields': {
        'jarakMin': {'doubleValue': min},
        'jarakMax': {'doubleValue': max},
        'tarif': {'integerValue': tarif.toString()},
      }
    });
    if (id == null) {
      await http.post(Uri.parse('$firestoreBase/ongkirTiers'), headers: {'Content-Type': 'application/json'}, body: body);
    } else {
      final uri = Uri.parse('$firestoreBase/ongkirTiers/$id').replace(queryParameters: {
        'updateMask.fieldPaths': ['jarakMin', 'jarakMax', 'tarif'],
      });
      await http.patch(uri, headers: {'Content-Type': 'application/json'}, body: body);
    }
    muatData();
  }

  Future<void> hapusTier(OngkirTier t) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tarif?'),
        content: Text('Tarif ${t.jarakMin}-${t.jarakMax} km akan dihapus. Yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Hapus')),
        ],
      ),
    );
    if (konfirmasi != true) return;
    await http.delete(Uri.parse('$firestoreBase/ongkirTiers/${t.id}'));
    muatData();
  }

  void bukaForm({OngkirTier? existing}) {
    final minController = TextEditingController(text: existing?.jarakMin.toString() ?? '');
    final maxController = TextEditingController(text: existing?.jarakMax.toString() ?? '');
    final tarifController = TextEditingController(text: existing?.tarif.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Tambah Tarif' : 'Edit Tarif',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: minController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Jarak Minimal (km)'),
              ),
              TextField(
                controller: maxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Jarak Maksimal (km)'),
              ),
              TextField(
                controller: tarifController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tarif (Rp)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    simpanTier(
                      id: existing?.id,
                      min: double.tryParse(minController.text) ?? 0,
                      max: double.tryParse(maxController.text) ?? 0,
                      tarif: int.tryParse(tarifController.text) ?? 0,
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('Kelola Ongkir'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => bukaForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: sedangMemuat
            ? const Center(child: CircularProgressIndicator())
            : daftar.isEmpty
                ? const Center(child: Text('Belum ada tarif ongkir'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: daftar.length,
                    itemBuilder: (context, index) {
                      final t = daftar[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${t.jarakMin} - ${t.jarakMax} km'),
                          subtitle: Text(formatRupiah(t.tarif)),
                          onTap: () => bukaForm(existing: t),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => hapusTier(t)),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class KelolaLokasiPage extends StatefulWidget {
  const KelolaLokasiPage({super.key});

  @override
  State<KelolaLokasiPage> createState() => _KelolaLokasiPageState();
}

class _KelolaLokasiPageState extends State<KelolaLokasiPage> {
  final latController = TextEditingController();
  final lngController = TextEditingController();
  bool sedangMemuat = true;

  @override
  void initState() {
    super.initState();
    muatData();
  }

  Future<void> muatData() async {
    try {
      final response = await http.get(Uri.parse('$firestoreBase/pengaturan/toko'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fields = data['fields'] as Map<String, dynamic>? ?? {};
        latController.text = angkaDouble(fields, 'lat').toString();
        lngController.text = angkaDouble(fields, 'lng').toString();
      }
    } catch (_) {}
    setState(() => sedangMemuat = false);
  }

  Future<void> simpanLokasi() async {
    final lat = double.tryParse(latController.text);
    final lng = double.tryParse(lngController.text);
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lat/Lng harus angka')));
      return;
    }
    final uri = Uri.parse('$firestoreBase/pengaturan/toko').replace(queryParameters: {
      'updateMask.fieldPaths': ['lat', 'lng'],
    });
    await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'lat': {'doubleValue': lat},
          'lng': {'doubleValue': lng},
        }
      }),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lokasi toko disimpan')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('Kelola Lokasi Toko'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: sedangMemuat
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Ambil titik koordinat toko dari Google Maps (tekan lama di lokasi toko), lalu masukkan di sini.',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Latitude',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Longitude',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                        onPressed: simpanLokasi,
                        child: const Text('Simpan Lokasi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class KeuanganDoc {
  final String id;
  final String jenis;
  final String keterangan;
  final int jumlah;
  final DateTime createdAt;

  KeuanganDoc({
    required this.id,
    required this.jenis,
    required this.keterangan,
    required this.jumlah,
    required this.createdAt,
  });

  factory KeuanganDoc.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>;
    final name = doc['name'] as String;
    String getString(String key) => fields[key]?['stringValue'] ?? '';
    int getInt(String key) => int.tryParse(fields[key]?['integerValue']?.toString() ?? '0') ?? 0;
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(fields['createdAt']?['timestampValue'] ?? '');
    } catch (_) {
      createdAt = DateTime.now();
    }
    return KeuanganDoc(
      id: name.split('/').last,
      jenis: getString('jenis'),
      keterangan: getString('keterangan'),
      jumlah: getInt('jumlah'),
      createdAt: createdAt,
    );
  }
}

class KeuanganPage extends StatefulWidget {
  const KeuanganPage({super.key});

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage> {
  List<KeuanganDoc> daftar = [];
  bool sedangMemuat = true;

  @override
  void initState() {
    super.initState();
    muatData();
  }

  Future<void> muatData() async {
    setState(() => sedangMemuat = true);
    final response = await http.get(Uri.parse('$firestoreBase/keuangan'));
    final data = jsonDecode(response.body);
    final docs = (data['documents'] as List?) ?? [];
    final hasil = docs.map((doc) => KeuanganDoc.fromFirestore(doc)).toList();
    hasil.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      daftar = hasil;
      sedangMemuat = false;
    });
  }

  Future<void> tambahTransaksi(String jenis, String keterangan, int jumlah) async {
    await http.post(
      Uri.parse('$firestoreBase/keuangan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'jenis': {'stringValue': jenis},
          'keterangan': {'stringValue': keterangan},
          'jumlah': {'integerValue': jumlah.toString()},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      }),
    );
    muatData();
  }

  Future<void> hapusTransaksi(KeuanganDoc k) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${k.keterangan}" akan dihapus. Yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Hapus')),
        ],
      ),
    );
    if (konfirmasi != true) return;
    await http.delete(Uri.parse('$firestoreBase/keuangan/${k.id}'));
    muatData();
  }

  void bukaFormTambah() {
    final keteranganController = TextEditingController();
    final jumlahController = TextEditingController();
    String jenisTerpilih = 'masuk';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tambah Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Masuk'),
                          value: 'masuk',
                          groupValue: jenisTerpilih,
                          onChanged: (val) => setSheetState(() => jenisTerpilih = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Keluar'),
                          value: 'keluar',
                          groupValue: jenisTerpilih,
                          onChanged: (val) => setSheetState(() => jenisTerpilih = val!),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: keteranganController,
                    decoration: const InputDecoration(labelText: 'Keterangan'),
                  ),
                  TextField(
                    controller: jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      onPressed: () {
                        if (keteranganController.text.trim().isEmpty) return;
                        final jumlah = int.tryParse(jumlahController.text) ?? 0;
                        Navigator.pop(context);
                        tambahTransaksi(jenisTerpilih, keteranganController.text.trim(), jumlah);
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMasuk = daftar.where((k) => k.jenis == 'masuk').fold(0, (sum, k) => sum + k.jumlah);
    final totalKeluar = daftar.where((k) => k.jenis == 'keluar').fold(0, (sum, k) => sum + k.jumlah);
    final saldo = totalMasuk - totalKeluar;

    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('Pencatatan Keuangan'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: muatData)],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: bukaFormTambah,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: sedangMemuat
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: Colors.black,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Masuk', style: TextStyle(color: Colors.greenAccent)),
                                Text(formatRupiah(totalMasuk),
                                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Keluar', style: TextStyle(color: Colors.redAccent)),
                                Text(formatRupiah(totalKeluar),
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Saldo', style: TextStyle(color: Colors.white, fontSize: 16)),
                                Text(formatRupiah(saldo),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: daftar.isEmpty
                        ? const Center(child: Text('Belum ada catatan'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: daftar.length,
                            itemBuilder: (context, index) {
                              final k = daftar[index];
                              final masuk = k.jenis == 'masuk';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(masuk ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: masuk ? Colors.green : Colors.red),
                                  title: Text(k.keterangan),
                                  subtitle: Text(formatWaktu(k.createdAt)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${masuk ? '+' : '-'}${formatRupiah(k.jumlah)}',
                                          style: TextStyle(
                                              color: masuk ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => hapusTransaksi(k),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class KontakDoc {
  final String id;
  final String nama;
  final String noWa;

  KontakDoc({required this.id, required this.nama, required this.noWa});

  factory KontakDoc.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>;
    final name = doc['name'] as String;
    return KontakDoc(
      id: name.split('/').last,
      nama: fields['nama']?['stringValue'] ?? '',
      noWa: fields['noWa']?['stringValue'] ?? '',
    );
  }
}

class KontakPage extends StatefulWidget {
  const KontakPage({super.key});

  @override
  State<KontakPage> createState() => _KontakPageState();
}

class _KontakPageState extends State<KontakPage> {
  List<KontakDoc> daftar = [];
  bool sedangMemuat = true;
  bool sedangSinkron = false;

  @override
  void initState() {
    super.initState();
    muatData();
  }

  Future<void> muatData() async {
    setState(() => sedangMemuat = true);
    final response = await http.get(Uri.parse('$firestoreBase/customers'));
    final data = jsonDecode(response.body);
    final docs = (data['documents'] as List?) ?? [];
    final hasil = docs.map((doc) => KontakDoc.fromFirestore(doc)).toList();
    hasil.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    setState(() {
      daftar = hasil;
      sedangMemuat = false;
    });
  }

  // Ambil nama & nomor WA dari semua pesanan yang pernah masuk, lalu tambahkan
  // ke daftar kontak kalau nomor itu belum ada di sana. Aman dipanggil berkali-kali
  // (tidak akan menduplikasi nomor yang sama).
  Future<void> sinkronkanDariPesanan() async {
    setState(() => sedangSinkron = true);
    try {
      final resPesanan = await http.get(Uri.parse('$firestoreBase/pesanan'));
      final dataPesanan = jsonDecode(resPesanan.body);
      final docsPesanan = (dataPesanan['documents'] as List?) ?? [];

      final Map<String, String> ditemukan = {}; // noWa -> nama (ambil kemunculan terakhir)
      for (final doc in docsPesanan) {
        final fields = doc['fields'] as Map<String, dynamic>? ?? {};
        final nama = fields['namaCustomer']?['stringValue'] ?? '';
        final noWa = fields['noWaCustomer']?['stringValue'] ?? '';
        if (noWa.isNotEmpty) ditemukan[noWa] = nama;
      }

      final noWaSudahAda = daftar.map((k) => k.noWa).toSet();
      int ditambahkan = 0;
      for (final entry in ditemukan.entries) {
        if (noWaSudahAda.contains(entry.key)) continue;
        await http.post(
          Uri.parse('$firestoreBase/customers'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fields': {
              'nama': {'stringValue': entry.value},
              'noWa': {'stringValue': entry.key},
            }
          }),
        );
        ditambahkan++;
      }

      await muatData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$ditambahkan kontak baru ditambahkan dari riwayat pesanan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal sinkronkan kontak: $e')),
      );
    } finally {
      if (mounted) setState(() => sedangSinkron = false);
    }
  }

  Future<void> simpanKontak(KontakDoc? existing, String nama, String noWa) async {
    if (existing == null) {
      await http.post(
        Uri.parse('$firestoreBase/customers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'nama': {'stringValue': nama},
            'noWa': {'stringValue': noWa},
          }
        }),
      );
    } else {
      final uri = Uri.parse('$firestoreBase/customers/${existing.id}').replace(queryParameters: {
        'updateMask.fieldPaths': ['nama', 'noWa'],
      });
      await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'nama': {'stringValue': nama},
            'noWa': {'stringValue': noWa},
          }
        }),
      );
    }
    muatData();
  }

  Future<void> hapusKontak(KontakDoc k) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kontak?'),
        content: Text('${k.nama} (${k.noWa}) akan dihapus dari daftar kontak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Hapus')),
        ],
      ),
    );
    if (konfirmasi != true) return;
    await http.delete(Uri.parse('$firestoreBase/customers/${k.id}'));
    setState(() => daftar.removeWhere((x) => x.id == k.id));
  }

  void bukaFormEdit({KontakDoc? existing}) {
    final namaController = TextEditingController(text: existing?.nama ?? '');
    final noWaController = TextEditingController(text: existing?.noWa ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(existing == null ? 'Tambah Kontak' : 'Edit Kontak',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noWaController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor WhatsApp', border: OutlineInputBorder(), hintText: '62812xxxxxxxx'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
              onPressed: () {
                final nama = namaController.text.trim();
                final noWa = noWaController.text.trim();
                if (nama.isEmpty || noWa.isEmpty) return;
                simpanKontak(existing, nama, noWa);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('Kontak Customer'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: sedangSinkron
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync),
            tooltip: 'Sinkronkan dari riwayat pesanan',
            onPressed: sedangSinkron ? null : sinkronkanDariPesanan,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                  onPressed: daftar.isEmpty
                      ? null
                      : () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => BroadcastPage(kontak: daftar)));
                        },
                  icon: const Icon(Icons.campaign),
                  label: Text('Broadcast ke ${daftar.length} Kontak'),
                ),
              ),
            ),
            Expanded(
              child: sedangMemuat
                  ? const Center(child: CircularProgressIndicator())
                  : daftar.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Belum ada kontak. Tap ikon sinkronisasi di kanan atas untuk mengambil nama & nomor dari riwayat pesanan yang sudah masuk.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: daftar.length,
                          itemBuilder: (context, index) {
                            final k = daftar[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(k.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(k.noWa),
                                onTap: () => bukaFormEdit(existing: k),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => bukaFormEdit(existing: k)),
                                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => hapusKontak(k)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => bukaFormEdit(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class BroadcastPage extends StatefulWidget {
  final List<KontakDoc> kontak;
  const BroadcastPage({super.key, required this.kontak});

  @override
  State<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  final pesanController = TextEditingController();
  late List<bool> terpilih;
  bool sedangBroadcast = false;
  int indexSekarang = 0;

  @override
  void initState() {
    super.initState();
    terpilih = List.filled(widget.kontak.length, true);
  }

  List<KontakDoc> get kontakTerpilih {
    final hasil = <KontakDoc>[];
    for (int i = 0; i < widget.kontak.length; i++) {
      if (terpilih[i]) hasil.add(widget.kontak[i]);
    }
    return hasil;
  }

  Future<void> bukaWaUntuk(KontakDoc k) async {
    final uri = Uri.parse('https://wa.me/${k.noWa}?text=${Uri.encodeComponent(pesanController.text)}');
    final berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!berhasil && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka WhatsApp, pastikan WhatsApp terinstall')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sedangBroadcast) {
      final daftar = kontakTerpilih;
      if (indexSekarang >= daftar.length) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5B315),
          appBar: AppBar(title: const Text('Broadcast Selesai'), backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text('Selesai kirim ke ${daftar.length} kontak', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      child: const Text('Selesai'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final k = daftar[indexSekarang];
      return Scaffold(
        backgroundColor: const Color(0xFFF5B315),
        appBar: AppBar(
          title: Text('Kirim ${indexSekarang + 1} / ${daftar.length}'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(k.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(k.noWa, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                  onPressed: () => bukaWaUntuk(k),
                  icon: const Icon(Icons.chat),
                  label: const Text('Buka WhatsApp & Kirim'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => indexSekarang++),
                  child: const Text('Sudah Terkirim, Lanjut →'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => indexSekarang++),
                  child: const Text('Lewati Kontak Ini'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(title: const Text('Broadcast'), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: pesanController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Pesan promo',
                  hintText: 'Contoh: Halo! GK Shoecare lagi ada promo cuci sepatu diskon 20% minggu ini...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${kontakTerpilih.length} dari ${widget.kontak.length} kontak dipilih'),
                  TextButton(
                    onPressed: () => setState(() {
                      final semuaTerpilih = terpilih.every((v) => v);
                      terpilih = List.filled(widget.kontak.length, !semuaTerpilih);
                    }),
                    child: const Text('Pilih Semua / Tidak'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.kontak.length,
                itemBuilder: (context, index) {
                  final k = widget.kontak[index];
                  return CheckboxListTile(
                    value: terpilih[index],
                    onChanged: (val) => setState(() => terpilih[index] = val ?? false),
                    title: Text(k.nama),
                    subtitle: Text(k.noWa),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                  onPressed: (pesanController.text.trim().isEmpty || kontakTerpilih.isEmpty)
                      ? null
                      : () => setState(() {
                            sedangBroadcast = true;
                            indexSekarang = 0;
                          }),
                  child: const Text('Mulai Kirim Satu-Satu'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TreatmentDoc {
  final String id;
  final String jenisBarang;
  final String nama;
  final int harga;
  final int estimasiHari;

  TreatmentDoc({
    required this.id,
    required this.jenisBarang,
    required this.nama,
    required this.harga,
    required this.estimasiHari,
  });

  factory TreatmentDoc.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>;
    final name = doc['name'] as String;
    String getString(String key) => fields[key]?['stringValue'] ?? '';
    int getInt(String key) => int.tryParse(fields[key]?['integerValue']?.toString() ?? '0') ?? 0;
    return TreatmentDoc(
      id: name.split('/').last,
      jenisBarang: getString('jenisBarang'),
      nama: getString('nama'),
      harga: getInt('harga'),
      estimasiHari: getInt('estimasiHari'),
    );
  }
}

const List<Map<String, dynamic>> treatmentAwal = [
  {'jenisBarang': 'Sepatu Dewasa', 'nama': 'Fast Cleaning', 'harga': 25000, 'estimasiHari': 2},
  {'jenisBarang': 'Sepatu Dewasa', 'nama': 'Deep Cleaning', 'harga': 35000, 'estimasiHari': 4},
  {'jenisBarang': 'Sepatu Dewasa', 'nama': 'Leather Shoes Care', 'harga': 40000, 'estimasiHari': 4},
  {'jenisBarang': 'Sepatu Dewasa', 'nama': 'Suede Shoes Care', 'harga': 40000, 'estimasiHari': 3},
  {'jenisBarang': 'Sepatu Dewasa', 'nama': 'Unyellowing', 'harga': 40000, 'estimasiHari': 5},
  {'jenisBarang': 'Sepatu Dewasa', 'nama': 'Unyellowing + Deep Cleaning', 'harga': 70000, 'estimasiHari': 5},
  {'jenisBarang': 'Sepatu Dewasa', 'nama': 'Express', 'harga': 70000, 'estimasiHari': 1},
  {'jenisBarang': 'Sepatu Anak', 'nama': 'Cuci Sepatu Anak', 'harga': 25000, 'estimasiHari': 3},
  {'jenisBarang': 'Sandal (Wanita/Gunung/Flat Shoes)', 'nama': 'Cuci Sandal', 'harga': 25000, 'estimasiHari': 3},
  {'jenisBarang': 'Topi', 'nama': 'Wash', 'harga': 35000, 'estimasiHari': 4},
  {'jenisBarang': 'Topi', 'nama': 'Hat Repaint (1 warna)', 'harga': 90000, 'estimasiHari': 5},
  {'jenisBarang': 'Tas Wanita', 'nama': 'Wash', 'harga': 35000, 'estimasiHari': 4},
  {'jenisBarang': 'Backpack/Carrier/Tas Olahraga', 'nama': 'Backpack', 'harga': 45000, 'estimasiHari': 5},
  {'jenisBarang': 'Backpack/Carrier/Tas Olahraga', 'nama': 'Carrier', 'harga': 60000, 'estimasiHari': 5},
  {'jenisBarang': 'Backpack/Carrier/Tas Olahraga', 'nama': 'Tas Olahraga', 'harga': 40000, 'estimasiHari': 5},
];

class KelolaTreatmentPage extends StatefulWidget {
  const KelolaTreatmentPage({super.key});

  @override
  State<KelolaTreatmentPage> createState() => _KelolaTreatmentPageState();
}

class _KelolaTreatmentPageState extends State<KelolaTreatmentPage> {
  List<TreatmentDoc> daftar = [];
  List<String> daftarJenisBarang = [];
  bool sedangMemuat = true;
  bool sedangIsiAwal = false;

  @override
  void initState() {
    super.initState();
    muatSemua();
  }

  Future<void> muatSemua() async {
    setState(() => sedangMemuat = true);
    final resTreatment = await http.get(Uri.parse('$firestoreBase/treatments'));
    final dataTreatment = jsonDecode(resTreatment.body);
    final docsTreatment = (dataTreatment['documents'] as List?) ?? [];
    final hasilTreatment = docsTreatment.map((doc) => TreatmentDoc.fromFirestore(doc)).toList();
    hasilTreatment.sort((a, b) {
      final c = a.jenisBarang.compareTo(b.jenisBarang);
      return c != 0 ? c : a.nama.compareTo(b.nama);
    });

    final resJenis = await http.get(Uri.parse('$firestoreBase/jenisBarang'));
    final dataJenis = jsonDecode(resJenis.body);
    final docsJenis = (dataJenis['documents'] as List?) ?? [];
    final hasilJenis = docsJenis.map((doc) {
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      return fields['nama']?['stringValue'] as String? ?? '';
    }).where((s) => s.isNotEmpty).toList();
    hasilJenis.sort();

    setState(() {
      daftar = hasilTreatment;
      daftarJenisBarang = hasilJenis;
      sedangMemuat = false;
    });
  }

  Future<void> isiDataAwal() async {
    setState(() => sedangIsiAwal = true);
    for (final t in treatmentAwal) {
      await http.post(
        Uri.parse('$firestoreBase/treatments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'jenisBarang': {'stringValue': t['jenisBarang']},
            'nama': {'stringValue': t['nama']},
            'harga': {'integerValue': t['harga'].toString()},
            'estimasiHari': {'integerValue': t['estimasiHari'].toString()},
          }
        }),
      );
    }
    setState(() => sedangIsiAwal = false);
    muatSemua();
  }

  Future<void> hapusTreatment(TreatmentDoc t) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus treatment?'),
        content: Text('"${t.nama}" akan dihapus. Yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Hapus')),
        ],
      ),
    );
    if (konfirmasi != true) return;
    await http.delete(Uri.parse('$firestoreBase/treatments/${t.id}'));
    muatSemua();
  }

  Future<void> simpanTreatment({
    String? id,
    required String jenisBarang,
    required String nama,
    required int harga,
    required int estimasiHari,
  }) async {
    final body = jsonEncode({
      'fields': {
        'jenisBarang': {'stringValue': jenisBarang},
        'nama': {'stringValue': nama},
        'harga': {'integerValue': harga.toString()},
        'estimasiHari': {'integerValue': estimasiHari.toString()},
      }
    });
    if (id == null) {
      await http.post(Uri.parse('$firestoreBase/treatments'),
          headers: {'Content-Type': 'application/json'}, body: body);
    } else {
      final uri = Uri.parse('$firestoreBase/treatments/$id').replace(queryParameters: {
        'updateMask.fieldPaths': ['jenisBarang', 'nama', 'harga', 'estimasiHari'],
      });
      await http.patch(uri, headers: {'Content-Type': 'application/json'}, body: body);
    }
    muatSemua();
  }

  void bukaFormTreatment({TreatmentDoc? existing}) {
    if (daftarJenisBarang.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Belum ada jenis barang, tambah dulu di menu Kelola Jenis Barang')));
      return;
    }
    final namaController = TextEditingController(text: existing?.nama ?? '');
    final hargaController = TextEditingController(text: existing?.harga.toString() ?? '');
    final hariController = TextEditingController(text: existing?.estimasiHari.toString() ?? '');
    String jenisTerpilih = existing?.jenisBarang ?? daftarJenisBarang.first;
    if (!daftarJenisBarang.contains(jenisTerpilih)) jenisTerpilih = daftarJenisBarang.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(existing == null ? 'Tambah Treatment' : 'Edit Treatment',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: jenisTerpilih,
                    decoration: const InputDecoration(labelText: 'Jenis Barang'),
                    items: daftarJenisBarang
                        .map((j) => DropdownMenuItem(value: j, child: Text(j, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) => setSheetState(() => jenisTerpilih = val!),
                  ),
                  TextField(
                    controller: namaController,
                    decoration: const InputDecoration(labelText: 'Nama Treatment'),
                  ),
                  TextField(
                    controller: hargaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                  ),
                  TextField(
                    controller: hariController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Estimasi Hari'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        simpanTreatment(
                          id: existing?.id,
                          jenisBarang: jenisTerpilih,
                          nama: namaController.text,
                          harga: int.tryParse(hargaController.text) ?? 0,
                          estimasiHari: int.tryParse(hariController.text) ?? 1,
                        );
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<TreatmentDoc>>{};
    for (final t in daftar) {
      grouped.putIfAbsent(t.jenisBarang, () => []).add(t);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5B315),
      appBar: AppBar(
        title: const Text('Kelola Treatment & Harga'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => bukaFormTreatment(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: sedangMemuat
            ? const Center(child: CircularProgressIndicator())
            : daftar.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Belum ada data treatment.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                            onPressed: sedangIsiAwal ? null : isiDataAwal,
                            child: sedangIsiAwal
                                ? const SizedBox(
                                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Isi Data Awal (dari yang sudah ada)'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          ...entry.value.map((t) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(t.nama),
                                  subtitle: Text('${formatRupiah(t.harga)} • ${t.estimasiHari} hari'),
                                  onTap: () => bukaFormTreatment(existing: t),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => hapusTreatment(t),
                                  ),
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
