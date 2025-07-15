// lib/features/config_option/data/dns_repository.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hiddify/core/utils/exception_handler.dart'; // فرض بر وجود این فایل
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dns_repository.g.dart';

class DnsServer {
  const DnsServer({required this.name, required this.address, this.dohUrl});
  final String name;
  final String address;
  final String? dohUrl;
}

abstract interface class DnsRepository {
  Future<String> findFastestDns();
}

class DnsRepositoryImpl implements DnsRepository {
  DnsRepositoryImpl(this._dio);
  final Dio _dio;

  static const _dnsServers = [
    DnsServer(name: 'Cloudflare', address: '1.1.1.1', dohUrl: 'https://cloudflare-dns.com/dns-query'),
    DnsServer(name: 'Google', address: '8.8.8.8', dohUrl: 'https://dns.google/resolve'),
    DnsServer(name: 'Quad9', address: '9.9.9.9', dohUrl: 'https://dns.quad9.net:5053/dns-query'),
    DnsServer(name: 'Shecan', address: '178.22.122.100', dohUrl: 'https://free.shecan.ir/dns-query'),
    DnsServer(name: 'Electro', address: '78.157.42.100', dohUrl: 'https://dns.electroteam.org/dns-query'),
  ];

  @override
  Future<String> findFastestDns() async {
    final latencies = <String, int>{};
    final tests = _dnsServers.map((server) async {
      final stopwatch = Stopwatch()..start();
      try {
        if (server.dohUrl != null) {
          await _dio.get(
            server.dohUrl!,
            queryParameters: {'name': 'google.com'},
            options: Options(sendTimeout: const Duration(seconds: 3), receiveTimeout: const Duration(seconds: 3)),
          );
          stopwatch.stop();
          latencies[server.address] = stopwatch.elapsedMilliseconds;
        }
      } catch (_) {
        latencies[server.address] = 9999;
      }
    });

    await Future.wait(tests);

    if (latencies.entries.where((e) => e.value < 9999).isEmpty) {
      return _dnsServers.first.address;
    }

    final fastest = latencies.entries.where((e) => e.value < 9999).reduce((a, b) => a.value < b.value ? a : b);
    return fastest.key;
  }
}

@Riverpod(keepAlive: true)
DnsRepository dnsRepository(DnsRepositoryRef ref) {
  // شما باید یک provider برای Dio داشته باشید. اینجا یک نمونه ساده قرار داده شده است.
  final dio = Dio();
  return DnsRepositoryImpl(dio);
}
