// lib/features/config_option/data/config_option_repository.dart

import 'package:dartx/dartx.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/core/utils/json_converters.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/config_option/data/dns_repository.dart'; // import جدید
import 'package:hiddify/features/config_option/model/config_option_failure.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_rule.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ConfigOptions {
  // افزودن گزینه جدید برای انتخاب خودکار DNS
  static final autoSelectDns = PreferencesNotifier.create<bool, bool>(
    "auto-select-dns",
    true, // به صورت پیش‌فرض فعال است
  );

  static final serviceMode = PreferencesNotifier.create<ServiceMode, String>(
    "service-mode",
    ServiceMode.defaultMode,
    mapFrom: (value) => ServiceMode.choices.firstWhere((e) => e.key == value),
    mapTo: (value) => value.key,
  );

  // ... بقیه کدهای شما بدون تغییر ...

  static final singboxConfigOptions = FutureProvider<SingboxConfigOption>(
    (ref) async {
      final autoSelect = ref.watch(autoSelectDns);
      
      String remoteDnsValue;
      String directDnsValue;

      if (autoSelect) {
        // اگر انتخاب خودکار فعال بود، سریع‌ترین DNS را پیدا کن
        final dnsRepo = ref.read(dnsRepositoryProvider);
        final fastestDns = await dnsRepo.findFastestDns();
        remoteDnsValue = fastestDns;
        directDnsValue = fastestDns; // برای سادگی، برای هر دو استفاده می‌شود
      } else {
        // در غیر این صورت، از مقادیر دستی استفاده کن
        remoteDnsValue = ref.watch(remoteDnsAddress);
        directDnsValue = ref.watch(directDnsAddress);
      }

      final mode = ref.watch(serviceMode);
      final rules = <SingboxRule>[];

      return SingboxConfigOption(
        region: ref.watch(region).name,
        blockAds: ref.watch(blockAds),
        useXrayCoreWhenPossible: ref.watch(useXrayCoreWhenPossible),
        executeConfigAsIs: false,
        logLevel: ref.watch(logLevel),
        resolveDestination: ref.watch(resolveDestination),
        ipv6Mode: ref.watch(ipv6Mode),
        remoteDnsAddress: remoteDnsValue,       // مقدار جدید
        remoteDnsDomainStrategy: ref.watch(remoteDnsDomainStrategy),
        directDnsAddress: directDnsValue,       // مقدار جدید
        directDnsDomainStrategy: ref.watch(directDnsDomainStrategy),
        mixedPort: ref.watch(mixedPort),
        tproxyPort: ref.watch(tproxyPort),
        localDnsPort: ref.watch(localDnsPort),
        tunImplementation: ref.watch(tunImplementation),
        mtu: ref.watch(mtu),
        strictRoute: ref.watch(strictRoute),
        connectionTestUrl: ref.watch(connectionTestUrl),
        urlTestInterval: ref.watch(urlTestInterval),
        enableClashApi: ref.watch(enableClashApi),
        clashApiPort: ref.watch(clashApiPort),
        enableTun: mode == ServiceMode.tun,
        enableTunService: mode == ServiceMode.tunService,
        setSystemProxy: mode == ServiceMode.systemProxy,
        bypassLan: ref.watch(bypassLan),
        allowConnectionFromLan: ref.watch(allowConnectionFromLan),
        enableFakeDns: ref.watch(enableFakeDns),
        enableDnsRouting: ref.watch(enableDnsRouting),
        independentDnsCache: ref.watch(independentDnsCache),
        mux: SingboxMuxOption(
          enable: ref.watch(enableMux),
          padding: ref.watch(muxPadding),
          maxStreams: ref.watch(muxMaxStreams),
          protocol: ref.watch(muxProtocol),
        ),
        tlsTricks: SingboxTlsTricks(
          enableFragment: ref.watch(enableTlsFragment),
          fragmentSize: ref.watch(tlsFragmentSize),
          fragmentSleep: ref.watch(tlsFragmentSleep),
          mixedSniCase: ref.watch(enableTlsMixedSniCase),
          enablePadding: ref.watch(enableTlsPadding),
          paddingSize: ref.watch(tlsPaddingSize),
        ),
        warp: SingboxWarpOption(
          enable: ref.watch(enableWarp),
          mode: ref.watch(warpDetourMode),
          wireguardConfig: ref.watch(warpWireguardConfig),
          licenseKey: ref.watch(warpLicenseKey),
          accountId: ref.watch(warpAccountId),
          accessToken: ref.watch(warpAccessToken),
          cleanIp: ref.watch(warpCleanIp),
          cleanPort: ref.watch(warpPort),
          noise: ref.watch(warpNoise),
          noiseMode: ref.watch(warpNoiseMode),
          noiseSize: ref.watch(warpNoiseSize),
          noiseDelay: ref.watch(warpNoiseDelay),
        ),
        warp2: SingboxWarpOption(
          enable: ref.watch(enableWarp),
          mode: ref.watch(warpDetourMode),
          wireguardConfig: ref.watch(warp2WireguardConfig),
          licenseKey: ref.watch(warp2LicenseKey),
          accountId: ref.watch(warp2AccountId),
          accessToken: ref.watch(warp2AccessToken),
          cleanIp: ref.watch(warpCleanIp),
          cleanPort: ref.watch(warpPort),
          noise: ref.watch(warpNoise),
          noiseMode: ref.watch(warpNoiseMode),
          noiseSize: ref.watch(warpNoiseSize),
          noiseDelay: ref.watch(warpNoiseDelay),
        ),
        rules: rules,
      );
    },
  );

  // ... بقیه کدهای شما بدون تغییر ...
}
