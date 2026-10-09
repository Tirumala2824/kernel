import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/data_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/kernel_app_bar.dart';
import 'buyer_home.dart';
import 'farmer_home.dart';
import 'fpo_home.dart';
import 'household_home.dart';

/// Home tab: the dashboard for the active role.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider);
    return Scaffold(
      appBar: const KernelAppBar(showMenu: true),
      body: AsyncView<Role?>(
        value: role,
        data: (role) => switch (role) {
          null => const SizedBox.shrink(),
          Role.farmer => const FarmerHome(),
          Role.household => const HouseholdHome(),
          Role.storageFpo => const FpoHome(),
          Role.buyer => const BuyerHome(),
        },
      ),
    );
  }
}

/// Open inspections that belong to [items].
List<Inspection> openFor(List<Inspection> open, List<GrainItem> items) {
  final ids = {for (final item in items) item.id};
  return open.where((i) => ids.contains(i.itemId)).toList();
}
