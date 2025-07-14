// lib/features/config_option/data/dns_repository.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
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

  final DioHttpClient _dio;

  static const _dnsServers = [
    DnsServer(name: 'Cloudflare', address: '1.1.1.1', dohUrl: 'https://cloudflare-dns.com/dns-query'),
    DnsServer(name: 'Google', address: '8.8.8.8', dohUrl: 'https://dns.google/resolve'),
    DnsServer(name: 'Quad9', address: '9.9.9.9', dohUrl: 'https://dns.quad9.net:5053/dns-query'),
    DnsServer(name: 'OpenDNS', address: '208.67.222.222'),
    // Add more public DNS servers if needed
  ];

  @override
  Future<String> findFastestDns() async {
    final latencies = <String, int>{};

    final tests = _dnsServers.map((server) async {
      final stopwatch = Stopwatch()..start();
      try {
        final dohUrl = server.dohUrl;
        // We prefer DoH for testing as it's a standard HTTP request.
        if (dohUrl != null) {
          await _dio.get(
            dohUrl,
            queryParameters: {'name': 'google.com'},
            options: Options(sendTimeout: const Duration(seconds: 3), receiveTimeout: const Duration(seconds: 3)),
          );
        } else {
          // Fallback for non-DoH servers would be more complex (e.g., native ping)
          // For now, we prioritize DoH-compatible servers for ranking.
          return;
        }
        
        stopwatch.stop();
        latencies[server.address] = stopwatch.elapsedMilliseconds;
      } catch (_) {
        latencies[server.address] = 9999; // Mark as very slow/failed
      }
    });

    await Future.wait(tests);

    if (latencies.isEmpty) {
      // Fallback to a default DNS if all tests fail
      return _dnsServers.first.address;
    }

    // Find the server with the minimum latency
    final fastest = latencies.entries.reduce((a, b) => a.value < b.value ? a : b);
    return fastest.key;
  }
}


@Riverpod(keepAlive: true)
DnsRepository dnsRepository(DnsRepositoryRef ref) {
  return DnsRepositoryImpl(ref.watch(dioHttpClientProvider));
}
