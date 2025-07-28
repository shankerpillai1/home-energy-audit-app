import 'package:dio/dio.dart';

class BackendApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

  Future<Map<String, dynamic>> submitLeakageTask(String jsonPayload) async {
    final resp = await _dio.post('/leakage/submit', data: jsonPayload);
    return resp.data;
  }
}
