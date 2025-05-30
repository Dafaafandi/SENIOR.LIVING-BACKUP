// Contoh di repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senior_living/model.dart'; // Asumsi Blog adalah User di sini

class Repository {
  final String _baseUrl = 'http://18.140.38.247/api/admin/users'; // Atau URL yang benar
  // Ganti dengan cara Anda mendapatkan token yang benar
  final String _tokenHardcode = "2|kxAMymJGqDLvYxdOX0LbeFeMS3xVBK2dcUchC2AU46ce922b";

  Future<List<Blog>?> getdata() async {
    try {
      print("Memanggil API: $_baseUrl");
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_tokenHardcode', // Anda perlu token yang valid
        },
      );

      if (response.statusCode == 200) {
        print("Response API sukses: ${response.body}");
        Map<String, dynamic> json = jsonDecode(response.body);
        if (json['data'] != null && json['data'] is List) {
          List<dynamic> listData = json['data'];
          List<Blog> blogs = listData.map((e) => Blog.fromJson(e)).toList();
          return blogs;
        } else {
          print("Format data tidak sesuai, 'data' field tidak ditemukan atau bukan List.");
          return []; // Kembalikan list kosong jika format tidak sesuai
        }
      } else {
        print('Gagal mengambil data. Status: ${response.statusCode}');
        print('Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error di repository.getdata: $e');
      return null;
    }
  }
}