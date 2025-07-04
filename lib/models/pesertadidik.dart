class PesertaDidik {
  final String nis;
  final int idOrtu;
  final String namaPd;
  final String tanggalLahir;
  final String jenisKelamin;
  final String kelas;
  final String fase;
  final double tinggiBadan;
  final double beratBadan;
  final String? foto;
  final String? filePenilaian;
  final String? statusGizi;
  final double? zScore;

  PesertaDidik({
    required this.nis,
    required this.idOrtu,
    required this.namaPd,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.kelas,
    required this.fase,
    required this.tinggiBadan,
    required this.beratBadan,
    this.foto,
    this.filePenilaian,
    this.statusGizi,
    this.zScore,
  });

  factory PesertaDidik.fromJson(Map<String, dynamic> json) {
    return PesertaDidik(
      nis: json['nis'].toString(),
      idOrtu: int.tryParse(json['idortu'].toString()) ?? 0,
      namaPd: json['namapd'] ?? '',
      tanggalLahir: json['tanggallahir'] ?? '',
      jenisKelamin: json['jeniskelamin'] ?? '',
      kelas: json['kelas'] ?? '',
      fase: json['fase'] ?? '',
      tinggiBadan: double.tryParse(json['tinggibadan'].toString()) ?? 0.0,
      beratBadan: double.tryParse(json['beratbadan'].toString()) ?? 0.0,
      foto: json['foto'],
      filePenilaian: json['file_penilaian'],
      statusGizi: json['status_gizi'],
      zScore: json['z_score'] != null ? double.tryParse(json['z_score'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nis': nis,
      'idortu': idOrtu,
      'namapd': namaPd,
      'tanggallahir': tanggalLahir,
      'jeniskelamin': jenisKelamin,
      'kelas': kelas,
      'fase': fase,
      'tinggibadan': tinggiBadan,
      'beratbadan': beratBadan,
      'foto': foto,
      'file_penilaian': filePenilaian,
      'status_gizi': statusGizi,
      'z_score': zScore,
    };
  }
}
