import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/kernel_theme.dart';
import 'router.dart';

class KernelApp extends ConsumerWidget {
  const KernelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kernel',
      debugShowCheckedModeBanner: false,
      theme: buildKernelTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
