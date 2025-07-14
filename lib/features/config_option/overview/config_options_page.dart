// lib/features/config_option/overview/config_options_page.dart

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/core/widget/tip_card.dart';
import 'package:hiddify/features/common/confirmation_dialogs.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/settings/widgets/sections_widgets.dart';
import 'package:hiddify/features/settings/widgets/settings_input_dialog.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:humanizer/humanizer.dart';

// ... بقیه کدهای شما بدون تغییر ...

class ConfigOptionsPage extends HookConsumerWidget {
  ConfigOptionsPage({super.key, String? section})
      : section = section != null ? ConfigOptionSection.values.byName(section) : null;

  final ConfigOptionSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... بقیه کدهای شما بدون تغییر ...

    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        shrinkWrap: true,
        slivers: [
          NestedAppBar(
            // ...
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ...
                  SettingsSection(t.config.section.dns),

                  // ویجت جدید برای فعال‌سازی DNS خودکار
                  SwitchListTile(
                    title: const Text("انتخاب خودکار DNS"),
                    subtitle: const Text(
                      "برنامه به صورت خودکار سریع‌ترین DNS را پیدا و استفاده می‌کند",
                    ),
                    value: ref.watch(ConfigOptions.autoSelectDns),
                    onChanged: ref.read(ConfigOptions.autoSelectDns.notifier).update,
                  ),

                  // گزینه‌های دستی فقط زمانی نمایش داده می‌شوند که حالت خودکار غیرفعال باشد
                  AnimatedVisibility(
                    visible: !ref.watch(ConfigOptions.autoSelectDns),
                    child: Column(
                      children: [
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.remoteDnsAddress),
                          preferences: ref.watch(ConfigOptions.remoteDnsAddress.notifier),
                          title: t.config.remoteDnsAddress,
                        ),
                        ChoicePreferenceWidget(
                          selected: ref.watch(ConfigOptions.remoteDnsDomainStrategy),
                          preferences: ref.watch(ConfigOptions.remoteDnsDomainStrategy.notifier),
                          choices: DomainStrategy.values,
                          title: t.config.remoteDnsDomainStrategy,
                          presentChoice: (value) => value.displayName,
                        ),
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.directDnsAddress),
                          preferences: ref.watch(ConfigOptions.directDnsAddress.notifier),
                          title: t.config.directDnsAddress,
                        ),
                        ChoicePreferenceWidget(
                          selected: ref.watch(ConfigOptions.directDnsDomainStrategy),
                          preferences: ref.watch(ConfigOptions.directDnsDomainStrategy.notifier),
                          choices: DomainStrategy.values,
                          title: t.config.directDnsDomainStrategy,
                          presentChoice: (value) => value.displayName,
                        ),
                      ],
                    ),
                  ),

                  SwitchListTile(
                    title: Text(t.config.enableDnsRouting),
                    value: ref.watch(ConfigOptions.enableDnsRouting),
                    onChanged: ref.watch(ConfigOptions.enableDnsRouting.notifier).update,
                  ),
                  
                  // ... بقیه کدهای شما بدون تغییر ...
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
