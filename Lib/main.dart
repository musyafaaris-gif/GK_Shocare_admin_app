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

const String firestoreProjectId = 'gk-shoecare';
const String firestoreBase = 'https://firestore.googleapis.com/v1/projects/$firestoreProjectId/databases/(default)/documents';

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
  static const String pinBenar = '12345';
  String? errorText;

  void cekPin() {
    if (pinController.text == pinBenar) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHomePage()),
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
      ),
      body: Padding(
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
          ],
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                            if (p.namaCustomer.isNotEmpty)
                                              Text('${p.namaCustomer} • ${p.noWaCustomer}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.black87)),
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

const List<String> jenisBarangList = [
  'Sepatu Dewasa',
  'Sepatu Anak',
  'Sandal (Wanita/Gunung/Flat Shoes)',
  'Topi',
  'Tas Wanita',
  'Backpack/Carrier/Tas Olahraga',
];

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
  bool sedangMemuat = true;
  bool sedangIsiAwal = false;

  @override
  void initState() {
    super.initState();
    muatTreatment();
  }

  Future<void> muatTreatment() async {
    setState(() => sedangMemuat = true);
    final uri = Uri.parse('$firestoreBase/treatments');
    final response = await http.get(uri);
    final data = jsonDecode(response.body);
    final docs = (data['documents'] as List?) ?? [];
    final hasil = docs.map((doc) => TreatmentDoc.fromFirestore(doc)).toList();
    hasil.sort((a, b) {
      final c = a.jenisBarang.compareTo(b.jenisBarang);
      return c != 0 ? c : a.nama.compareTo(b.nama);
    });
    setState(() {
      daftar = hasil;
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
    muatTreatment();
  }

  Future<void> hapusTreatment(TreatmentDoc t) async {
    await http.delete(Uri.parse('$firestoreBase/treatments/${t.id}'));
    muatTreatment();
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
    muatTreatment();
  }

  void bukaFormTreatment({TreatmentDoc? existing}) {
    final namaController = TextEditingController(text: existing?.nama ?? '');
    final hargaController = TextEditingController(text: existing?.harga.toString() ?? '');
    final hariController = TextEditingController(text: existing?.estimasiHari.toString() ?? '');
    String jenisTerpilih = existing?.jenisBarang ?? jenisBarangList.first;

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
                    items: jenisBarangList
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
      body: sedangMemuat
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
    );
  }
}
