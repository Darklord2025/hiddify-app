// lib/features/config_option/data/dns_repository.dart

import 'dart:async';
import 'package.dio/dio.dart';
// توجه: این فایل به dio_http_client شما نیاز دارد. اگر وجود ندارد، باید آن را ایجاد کنید.
// import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dns_repository.g.dart';

class DnsServer {
  const DnsServer({required this.name, required this.address, this.dohUrl});

  final String name;
  final String address;
  final String? dohUrl; // DNS-over-HTTPS url for testing
}

abstract interface class DnsRepository {
  Future<String> findFastestDns();
}

class DnsRepositoryImpl implements DnsRepository {
  DnsRepositoryImpl(this._dio);

  // فرض می‌کنیم شما یک Dio provider دارید. اگر نه، باید آن را بسازید.
  final Dio _dio;

  static const _dnsServers = [
    DnsServer(name: 'Cloudflare', address: '1.1.1.1', dohUrl: 'https://cloudflare-dns.com/dns-query'),
    DnsServer(name: 'Google', address: '8.8.8.8', dohUrl: 'https://dns.google/resolve'),
    DnsServer(name: 'Quad9', address: '9.9.9.9', dohUrl: 'https://dns.quad9.net:5053/dns-query'),
    DnsServer(name: 'OpenDNS', address: '208.67.222.222'),
    DnsServer(name: 'Shecan', address: '178.22.122.100'),
    DnsServer(name: 'Electro', address: '78.157.42.100'),
  ];

  @override
  Future<String> findFastestDns() async {
    final latencies = <String, int>{};

    final tests = _dnsServers.map((server) async {
      final stopwatch = Stopwatch()..start();
      try {
        final dohUrl = server.dohUrl;
        if (dohUrl != null) {
          await _dio.get(
            dohUrl,
            queryParameters: {'name': 'google.com'},
            options: Options(sendTimeout: const Duration(seconds: 3), receiveTimeout: const Duration(seconds: 3)),
          );
        } else {
          return;
        }
        
        stopwatch.stop();
        latencies[server.address] = stopwatch.elapsedMilliseconds;
      } catch (_) {
        latencies[server.address] = 9999;
      }
    });

    await Future.wait(tests);

    if (latencies.isEmpty) {
      return _dnsServers.first.address;
    }

    final fastest = latencies.entries.reduce((a, b) => a.value < b.value ? a : b);
    return fastest.key;
  }
}

// این provider را در پروژه خود بر اساس نحوه ارائه Dio تنظیم کنید
@Riverpod(keepAlive: true)
DnsRepository dnsRepository(DnsRepositoryRef ref) {
  // return DnsRepositoryImpl(ref.watch(dioHttpClientProvider));
  // خط بالا را با provider صحیح Dio در پروژه خود جایگزین کنید
  return DnsRepositoryImpl(Dio()); // به عنوان مثال
}
