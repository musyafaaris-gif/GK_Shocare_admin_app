import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

const List<String> daftarStatus = ['Sudah Diambil', 'Dikerjakan', 'Sudah Selesai'];

Color warnaStatus(String status) {
  switch (status) {
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
    final pinTersimpan = prefs.getString('admin_pin') ?? '12345';
    if (pinController.text == pinTersimpan) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminHomePage()));
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
            ],
          ),
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
          createdAt: p.createdAt,
        );
      }
    });
    final uri = Uri.parse('$firestoreBase/pesanan/${p.id}').replace(queryParameters: {
      'updateMask.fieldPaths': ['status'],
    });
    await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'status': {'stringValue': statusBaru},
        }
      }),
    );
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
                                              if (p.lokerNomor.isNotEmpty)
                                                Text('Loker No. ${p.lokerNomor}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text('Selesai: ${p.tanggalSelesai}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                              Text('Masuk: ${formatWaktu(p.createdAt)}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                            ],
                                          ),
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
