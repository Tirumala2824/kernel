import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../brand/illustrations.dart';
import '../../brand/kernel_brand.dart';
import '../../l10n/l10n.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../role/role_selection_screen.dart';

/// First launch: privacy, how to scan, then pick a role. Completing it sets
/// the role and `onboardingDone`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageCount = 3;
  final _pages = PageController();
  int _page = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Duration get _pageDuration =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
      ? const Duration(milliseconds: 1)
      : KernelMotion.slow;

  void _goTo(int page) => _pages.animateToPage(
    page,
    duration: _pageDuration,
    curve: KernelMotion.emphasized,
  );

  /// Saves the role and marks onboarding done. Navigation is left to the
  /// router redirect, which moves to Home once both settings streams have
  /// emitted the new values; navigating here raced those emissions. The
  /// role cards stay disabled until then so a second tap cannot interleave.
  Future<void> _pick(Role role) async {
    if (_saving) return;
    final l = context.l10n;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await settings.setActiveRole(role);
      await settings.setOnboardingDone(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l.roleSaveFailed('$e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = ref.watch(activeRoleProvider).value;
    final last = _page == _pageCount - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KernelSpace.page,
                KernelSpace.md,
                KernelSpace.sm,
                0,
              ),
              child: Row(
                children: [
                  KernelLogo(height: 26, label: l.appTitle),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      key: const Key('onboarding-skip'),
                      onPressed: () => _goTo(_pageCount - 1),
                      child: Text(l.onboardingSkip),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _InfoPage(
                    key: const Key('onboarding-page-0'),
                    illustration: KernelIllustrations.privacy,
                    eyebrow: l.onboardingStep(1, _pageCount),
                    title: l.onboardingPrivacyTitle,
                    points: [
                      (Icons.phonelink_lock_rounded, l.onboardingPrivacy1),
                      (Icons.cloud_off_rounded, l.onboardingPrivacy2),
                      (Icons.delete_sweep_rounded, l.onboardingPrivacy3),
                    ],
                  ),
                  _InfoPage(
                    key: const Key('onboarding-page-1'),
                    illustration: KernelIllustrations.howToScan,
                    eyebrow: l.onboardingStep(2, _pageCount),
                    title: l.onboardingHowTitle,
                    points: [
                      (Icons.smartphone_rounded, l.onboardingHow1),
                      (Icons.volume_off_rounded, l.onboardingHow2),
                      (Icons.timer_rounded, l.onboardingHow3),
                      (Icons.person_search_rounded, l.onboardingHow4),
                    ],
                  ),
                  ListView(
                    key: const Key('onboarding-page-2'),
                    padding: const EdgeInsets.all(KernelSpace.page),
                    children: [
                      ScreenHeader(
                        eyebrow: l.onboardingStep(3, _pageCount),
                        title: l.onboardingRoleTitle,
                        subtitle: l.roleSelectSubtitle,
                      ),
                      const SizedBox(height: KernelSpace.md),
                      RolePicker(
                        current: current,
                        enabled: !_saving,
                        onSelect: _pick,
                      ),
                      QuietNote(l.roleSwitchKeepsRecords),
                      if (_error != null) ...[
                        const SizedBox(height: KernelSpace.md),
                        ErrorNote(_error!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KernelSpace.page,
                KernelSpace.sm,
                KernelSpace.page,
                KernelSpace.lg,
              ),
              child: Row(
                children: [
                  _Dots(count: _pageCount, index: _page),
                  const SizedBox(width: KernelSpace.md),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: KernelSpace.sm,
                      runSpacing: KernelSpace.sm,
                      children: [
                        if (_page > 0)
                          TextButton(
                            key: const Key('onboarding-back'),
                            onPressed: () => _goTo(_page - 1),
                            child: Text(l.onboardingBack),
                          ),
                        if (!last)
                          FilledButton.icon(
                            key: const Key('onboarding-next'),
                            onPressed: () => _goTo(_page + 1),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(l.onboardingNext),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    super.key,
    required this.illustration,
    required this.eyebrow,
    required this.title,
    required this.points,
  });

  final String illustration;
  final String eyebrow;
  final String title;
  final List<(IconData, String)> points;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(KernelSpace.page),
      children: [
        Center(child: KernelIllustration(illustration, height: 190)),
        const SizedBox(height: KernelSpace.lg),
        ScreenHeader(eyebrow: eyebrow, title: title),
        const SizedBox(height: KernelSpace.sm),
        for (final (icon, text) in points)
          Padding(
            padding: const EdgeInsets.only(bottom: KernelSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: KernelColors.sage,
                    borderRadius: BorderRadius.circular(KernelRadii.sm),
                  ),
                  child: Icon(icon, color: KernelColors.forest),
                ),
                const SizedBox(width: KernelSpace.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(text, style: textTheme.bodyLarge),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.onboardingStep(index + 1, count),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: KernelMotion.medium,
              margin: const EdgeInsets.only(right: 6),
              width: i == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? KernelColors.forest : KernelColors.sageDeep,
                borderRadius: BorderRadius.circular(KernelRadii.pill),
              ),
            ),
        ],
      ),
    );
  }
}
