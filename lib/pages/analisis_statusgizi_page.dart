import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/pesertadidik.dart';

class AnalisisStatusGiziPage extends StatefulWidget {
  const AnalisisStatusGiziPage({Key? key}) : super(key: key);

  @override
  State<AnalisisStatusGiziPage> createState() => _AnalisisStatusGiziPageState();
}

class _AnalisisStatusGiziPageState extends State<AnalisisStatusGiziPage> {
  bool _loading = true;
  String? _error;
  List<PesertaDidik> _peserta = [];
  Map<String, dynamic>? _statusGiziChartData;
  String? _chartBulan;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final peserta = await ApiService().getPesertaDidikList();
      final chart = await ApiService().getStatusGiziChartData();
      setState(() {
        _peserta = peserta;
        _statusGiziChartData = chart['data'];
        _chartBulan = chart['bulan'];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestStatusGizi(String nis) async {
    if (nis.isEmpty) return null;
    try {
      final list = await ApiService().getStatusGiziByNis(nis);
      if (list.isNotEmpty) {
        // Ambil data status gizi terbaru (asumsi urutan terbaru di depan)
        final latest = list.first;
        // Pastikan field 'status' dan 'z_score' sesuai API
        return {
          'status_gizi': latest['status'] ?? latest['status_gizi'],
          'z_score': latest['z_score'],
        };
      }
    } catch (_) {}
    return null;
  }

  List<PieChartSectionData> _buildPieSections(Map<String, dynamic>? data) {
    if (data == null) return [];
    final colors = [
      const Color(0xFFe57373), // Gizi Kurang
      const Color(0xFF81c784), // Gizi Baik
      const Color(0xFFffd54f), // Gizi Lebih
      const Color(0xFF64b5f6), // Obesitas
    ];
    final labels = ['Gizi Kurang', 'Gizi Baik', 'Gizi Lebih', 'Obesitas'];
    final total = labels.fold<int>(0, (sum, k) => sum + ((data[k] ?? 0) as int));
    return List.generate(labels.length, (i) {
      final value = (data[labels[i]] ?? 0) as int;
      final percent = total > 0 ? (value / total * 100) : 0;
      return PieChartSectionData(
        color: colors[i],
        value: value.toDouble(),
        title: value > 0 ? '${labels[i]}\n${percent.toStringAsFixed(1)}%' : '',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisis Status Gizi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Gagal memuat data: $_error'))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Rekap Status Gizi Kelas A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieSections(_statusGiziChartData?["kelasA"]),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Rekap Status Gizi Kelas B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieSections(_statusGiziChartData?["kelasB"]),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      if (_chartBulan != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Bulan: $_chartBulan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      const SizedBox(height: 32),
                      const Text('Riwayat Status Gizi Peserta Didik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      _peserta.isEmpty
                          ? const Text('Belum ada data peserta didik.')
                          : FutureBuilder<List<Map<String, dynamic>?>>(
                              future: Future.wait(_peserta.map((pd) => _fetchLatestStatusGizi(pd.nis)).toList()),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final statusList = snapshot.data!;
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Nama')),
                                      DataColumn(label: Text('Kelas')),
                                      DataColumn(label: Text('Status Gizi')),
                                      DataColumn(label: Text('Z-Score')),
                                    ],
                                    rows: List.generate(_peserta.length, (i) {
                                      final pd = _peserta[i];
                                      final status = statusList[i];
                                      return DataRow(cells: [
                                        DataCell(Text(pd.namaPd)),
                                        DataCell(Text(pd.kelas)),
                                        DataCell(Text(status != null && status['status_gizi'] != null ? status['status_gizi'].toString() : '-')),
                                        DataCell(Text(status != null && status['z_score'] != null ? status['z_score'].toString() : '-')),
                                      ]);
                                    }),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}
