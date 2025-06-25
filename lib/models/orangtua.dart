class Orangtua {
  final int id;
  final int? userId;
  final String namaOrtu;
  final String notelpOrtu;
  final String alamat;
  final String emailOrtu;
  final String nickname;

  Orangtua({
    required this.id,
    this.userId,
    required this.namaOrtu,
    required this.notelpOrtu,
    required this.alamat,
    required this.emailOrtu,
    required this.nickname,
  });

  factory Orangtua.fromJson(Map<String, dynamic> json) {
    return Orangtua(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] == null ? null : (json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString())),
      namaOrtu: json['namaortu']?.toString() ?? '',
      notelpOrtu: json['notelportu']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',
      emailOrtu: json['emailortu']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'namaortu': namaOrtu,
    'notelportu': notelpOrtu,
    'alamat': alamat,
    'emailortu': emailOrtu,
    'nickname': nickname,
  };
}
