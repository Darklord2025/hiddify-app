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

// این یک نمونه ساده است، شما باید آن را مطابق با ساختار پروژه خود تطبیق دهید
class ConfigOptionRepository with ExceptionHandler, InfraLogger {
  ConfigOptionRepository({
    required this.preferences,
    required this.getConfigOptions,
  });

  final SharedPreferences preferences;
  final Future<SingboxConfigOption> Function() getConfigOptions;

  TaskEither<ConfigOptionFailure, SingboxConfigOption> getFullSingboxConfigOption() {
    return exceptionHandler(
      () async {
        return right(await getConfigOptions());
      },
      ConfigOptionUnexpectedFailure.new,
    );
  }
}


class ConfigOptions {
  static final autoSelectDns = PreferencesNotifier.create<bool, bool>(
    "auto-select-dns",
    true,
  );

  // بقیه گزینه‌های شما اینجا قرار می‌گیرند...
  static final serviceMode = PreferencesNotifier.create<ServiceMode, String>("service-mode", ServiceMode.defaultMode, mapFrom: (value) => ServiceMode.choices.firstWhere((e) => e.key == value), mapTo: (value) => value.key);
  static final region = PreferencesNotifier.create<Region, String>("region", Region.other, mapFrom: Region.values.byName, mapTo: (value) => value.name);
  static final useXrayCoreWhenPossible = PreferencesNotifier.create<bool, bool>("use-xray-core-when-possible", false);
  static final blockAds = PreferencesNotifier.create<bool, bool>("block-ads", false);
  static final logLevel = PreferencesNotifier.create<LogLevel, String>("log-level", LogLevel.warn, mapFrom: LogLevel.values.byName, mapTo: (value) => value.name);
  static final resolveDestination = PreferencesNotifier.create<bool, bool>("resolve-destination", false);
  static final ipv6Mode = PreferencesNotifier.create<IPv6Mode, String>("ipv6-mode", IPv6Mode.disable, mapFrom: (value) => IPv6Mode.values.firstWhere((e) => e.key == value), mapTo: (value) => value.key);
  static final remoteDnsAddress = PreferencesNotifier.create<String, String>("remote-dns-address", "udp://1.1.1.1");
  static final remoteDnsDomainStrategy = PreferencesNotifier.create<DomainStrategy, String>("remote-dns-domain-strategy", DomainStrategy.auto, mapFrom: (value) => DomainStrategy.values.firstWhere((e) => e.key == value), mapTo: (value) => value.key);
  static final directDnsAddress = PreferencesNotifier.create<String, String>("direct-dns-address", "udp://1.1.1.1");
  static final directDnsDomainStrategy = PreferencesNotifier.create<DomainStrategy, String>("direct-dns-domain-strategy", DomainStrategy.auto, mapFrom: (value) => DomainStrategy.values.firstWhere((e) => e.key == value), mapTo: (value) => value.key);
  // ... بقیه گزینه‌ها

  static final singboxConfigOptions = FutureProvider<SingboxConfigOption>(
    (ref) async {
      final autoSelect = ref.watch(autoSelectDns);
      String remoteDnsValue;
      String directDnsValue;

      if (autoSelect) {
        final dnsRepo = ref.read(dnsRepositoryProvider);
        final fastestDns = await dnsRepo.findFastestDns();
        remoteDnsValue = "udp://$fastestDns"; // ensure format is correct
        directDnsValue = "udp://$fastestDns";
      } else {
        remoteDnsValue = ref.watch(remoteDnsAddress);
        directDnsValue = ref.watch(directDnsAddress);
      }

      final mode = ref.watch(serviceMode);
      return SingboxConfigOption(
        logLevel: ref.watch(logLevel),
        remoteDnsAddress: remoteDnsValue,
        directDnsAddress: directDnsValue,
        // ... تمام گزینه‌های دیگر را اینجا قرار دهید
        region: ref.watch(region).name,
        blockAds: ref.watch(blockAds),
        useXrayCoreWhenPossible: ref.watch(useXrayCoreWhenPossible),
        executeConfigAsIs: false,
        resolveDestination: ref.watch(resolveDestination),
        ipv6Mode: ref.watch(ipv6Mode),
        remoteDnsDomainStrategy: ref.watch(remoteDnsDomainStrategy),
        directDnsDomainStrategy: ref.watch(directDnsDomainStrategy),
        mixedPort: 2334,
        tproxyPort: 2335,
        localDnsPort: 6450,
        tunImplementation: TunImplementation.gvisor,
        mtu: 9000,
        strictRoute: true,
        connectionTestUrl: "http://cp.cloudflare.com",
        urlTestInterval: const Duration(minutes: 10),
        enableClashApi: true,
        clashApiPort: 6756,
        enableTun: mode == ServiceMode.tun,
        setSystemProxy: mode == ServiceMode.systemProxy,
        rules: [],
      );
    },
  );
}
