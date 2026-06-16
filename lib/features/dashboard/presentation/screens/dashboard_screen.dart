import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animations/animations.dart';
import 'package:clutr/features/cleanup/presentation/screens/cleanup_screen.dart';
import 'package:clutr/features/cleanup/providers/media_provider.dart';
import 'package:clutr/features/dashboard/presentation/widgets/scanning_indicator.dart';
import 'package:clutr/features/settings/providers/settings_provider.dart';
import 'package:clutr/core/utils/size_formatter.dart';
import 'package:clutr/features/cleanup/presentation/trash_screen.dart';
import 'package:clutr/core/platform/storage_channel.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);
    final settingsState = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 32,
                      height: 32,
                      color: settingsState.useDynamicColor
                          ? colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Clutr',
                        style: textTheme.displaySmall?.copyWith(
                          fontFamily: 'Newstalgia',
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 32),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: mediaState.when(
                    loading: () => SizedBox(
                      key: const ValueKey('loading'),
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScanningIndicator(
                              text: 'SEARCHING',
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    error: (err, stack) => SizedBox(
                      key: const ValueKey('error'),
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(child: Text('Error: $err')),
                    ),
                    data: (mediaList) {
                      // UN-SCANNED STATE
                      if (mediaList == null) {
                        return Column(
                          key: const ValueKey('unscanned'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(
                                  0.4,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedRocket01,
                                size: 80.0,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 64),
                          Text(
                            'Ready to\nclean up?',
                            style: textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Find out how much space you can free up by swiping through your unwanted photos and videos.',
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  ref.read(mediaProvider.notifier).startScan(),
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedSearch01,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Scan Device',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                        ],
                      );
                    }

                    // SCANNED STATE (RESULTS)
                    double totalBytes = 0;
                    Map<String, double> folderSizes = {};
                    Map<String, int> folderCounts = {};
                    int duplicatedCount = 0;
                    double duplicatedSize = 0;
                    Set<double> seenSizes = {};

                    for (var item in mediaList) {
                      final size = (item['size'] as num?)?.toDouble() ?? 0.0;
                      totalBytes += size;

                      if (size > 0 && seenSizes.contains(size)) {
                        duplicatedCount++;
                        duplicatedSize += size;
                      } else if (size > 0) {
                        seenSizes.add(size);
                      }

                      final path = item['path'] as String?;
                      if (path != null) {
                        final parts = path.split('/');
                        final folderName = parts.length > 1
                            ? parts[parts.length - 2]
                            : 'Unknown';
                        folderSizes[folderName] =
                            (folderSizes[folderName] ?? 0) + size;
                        folderCounts[folderName] =
                            (folderCounts[folderName] ?? 0) + 1;
                      }
                    }

                    final sizeText = SizeFormatter.formatBytes(
                      totalBytes.toInt(),
                    );
                    final sortedFolders = folderSizes.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    double getRawSizeForApp(String keyword) {
                      double size = 0;
                      for (var entry in folderSizes.entries) {
                        if (entry.key.toLowerCase().contains(
                          keyword.toLowerCase(),
                        )) {
                          size += entry.value;
                        }
                      }
                      return size;
                    }

                    String getSizeForApp(String keyword) {
                      final size = getRawSizeForApp(keyword);
                      return size > 0
                          ? SizeFormatter.formatBytes(size.toInt())
                          : '0 B';
                    }

                    final List<Color> heatmapColors = const [
                      Color(0xFFFF5252), // Lighter Red
                      Color(0xFFFB8C00), // Orange
                      Color(0xFFFFB300), // Amber
                      Color(0xFF43A047), // Green
                      Color(0xFF00ACC1), // Cyan
                      Color(0xFF1E88E5), // Blue
                      Color(0xFF8E24AA), // Purple
                      Color(0xFF546E7A), // BlueGrey
                    ];

                    return Column(
                      key: const ValueKey('scanned'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Summary Box
                        Card(
                          elevation: 0,
                          color: colorScheme.secondaryContainer,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              isSmallScreen ? 24.0 : 32.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        isSmallScreen ? 12 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: HugeIcon(
                                        icon: HugeIcons.strokeRoundedPieChart,
                                        size: isSmallScreen ? 36.0 : 48.0,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 16 : 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Space to Free',
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSecondaryContainer
                                                      .withOpacity(0.8),
                                                ),
                                          ),
                                          TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                              begin: 0,
                                              end: totalBytes,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 1500,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, value, child) {
                                              final sizeStr =
                                                  SizeFormatter.formatBytes(
                                                    value.toInt(),
                                                  );
                                              final parts = sizeStr.split(' ');
                                              final val = parts.isNotEmpty
                                                  ? parts[0]
                                                  : '';
                                              final unit = parts.length > 1
                                                  ? parts[1].toLowerCase()
                                                  : '';
                                              return RichText(
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: val,
                                                      style: textTheme
                                                          .displayMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            color: colorScheme
                                                                .primary,
                                                            fontSize:
                                                                isSmallScreen
                                                                ? 36
                                                                : 48,
                                                          ),
                                                    ),
                                                    TextSpan(
                                                      text: ' $unit',
                                                      style: textTheme
                                                          .headlineMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            color: colorScheme
                                                                .primary
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (totalBytes > 0) ...[
                                  const SizedBox(height: 24),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(
                                      milliseconds: 1500,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return LayoutBuilder(
                                        builder: (context, constraints) {
                                          final availableWidth =
                                              constraints.maxWidth;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  height: 16,
                                                  width: double.infinity,
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  child: Row(
                                                    children: [
                                                      for (
                                                        int i = 0;
                                                        i <
                                                            sortedFolders
                                                                .length;
                                                        i++
                                                      )
                                                        if (sortedFolders[i]
                                                                .value >
                                                            0)
                                                          Container(
                                                            width:
                                                                availableWidth *
                                                                (sortedFolders[i]
                                                                        .value /
                                                                    totalBytes) *
                                                                value,
                                                            color:
                                                                heatmapColors[i %
                                                                    heatmapColors
                                                                        .length],
                                                          ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Wrap(
                                                spacing: 12,
                                                runSpacing: 8,
                                                children: [
                                                  for (
                                                    int i = 0;
                                                    i < sortedFolders.length &&
                                                        i < 6;
                                                    i++
                                                  )
                                                    if (sortedFolders[i].value >
                                                        0)
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 10,
                                                            height: 10,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  heatmapColors[i %
                                                                      heatmapColors
                                                                          .length],
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            sortedFolders[i]
                                                                .key,
                                                            style: textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: colorScheme
                                                                      .onSurfaceVariant,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        if (duplicatedCount > 0) ...[
                          const SizedBox(height: 16),
                          // Duplicated Summary Box
                          Card(
                            elevation: 0,
                            color: colorScheme.tertiaryContainer,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                isSmallScreen ? 24.0 : 32.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      isSmallScreen ? 12 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.onTertiaryContainer
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedCopy01,
                                      size: isSmallScreen ? 36.0 : 48.0,
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 16 : 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Duplicated Files',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onTertiaryContainer
                                                    .withOpacity(0.8),
                                              ),
                                        ),
                                        TweenAnimationBuilder<int>(
                                          tween: IntTween(
                                            begin: 0,
                                            end: duplicatedCount,
                                          ),
                                          duration: const Duration(
                                            milliseconds: 1500,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, child) {
                                            return Text(
                                              '$value Dupes',
                                              style: textTheme.displayMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    color: colorScheme
                                                        .onTertiaryContainer,
                                                    fontSize: isSmallScreen
                                                        ? 32
                                                        : 40,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            );
                                          },
                                        ),
                                        if (duplicatedCount > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                            ),
                                            child: Text(
                                              'Wasting ${SizeFormatter.formatBytes(duplicatedSize.toInt())}',
                                              style: textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onTertiaryContainer
                                                        .withOpacity(0.8),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                        Text(
                          'Storage Breakdown',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Folder List Breakdown
                        if (sortedFolders.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Center(
                              child: Text(
                                'No clutter found! 🎉',
                                style: textTheme.titleLarge?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isSmallScreen ? 1 : 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: isSmallScreen ? 1.3 : 1.1,
                                ),
                            itemCount: sortedFolders.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final folder = sortedFolders[index];
                              final folderName = folder.key;
                              final folderSize = folder.value;
                              final itemCount = folderCounts[folderName] ?? 0;

                              return OpenContainer(
                                transitionType: ContainerTransitionType.fade,
                                openColor: colorScheme.surface,
                                closedColor: Colors.transparent,
                                closedElevation: 0,
                                openElevation: 0,
                                closedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                openBuilder: (context, _) =>
                                    CleanupScreen(folderFilter: folderName),
                                closedBuilder: (context, openContainer) {
                                  return Card(
                                    elevation: 0,
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                      side: BorderSide(
                                        color: colorScheme.outlineVariant
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                    color: colorScheme.surfaceContainerHighest
                                        .withOpacity(0.3),
                                    child: InkWell(
                                      onTap: openContainer,
                                      borderRadius: BorderRadius.circular(32),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          isSmallScreen ? 12.0 : 16.0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: isSmallScreen
                                                          ? 56.0
                                                          : 68.0,
                                                      height: isSmallScreen
                                                          ? 56.0
                                                          : 68.0,
                                                      child: TweenAnimationBuilder<double>(
                                                        tween: Tween<double>(
                                                          begin: 0,
                                                          end: totalBytes > 0
                                                              ? (folderSize /
                                                                    totalBytes)
                                                              : 0,
                                                        ),
                                                        duration: const Duration(milliseconds: 1500),
                                                        curve: Curves.easeOutCubic,
                                                        builder: (context, value, child) {
                                                          return CircularProgressIndicator(
                                                            value: value,
                                                            color:
                                                                heatmapColors[index %
                                                                    heatmapColors
                                                                        .length],
                                                            backgroundColor:
                                                                colorScheme.primary
                                                                    .withOpacity(
                                                                      0.05,
                                                                    ),
                                                            strokeWidth: 4.0,
                                                            strokeCap:
                                                                StrokeCap.round,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                        isSmallScreen ? 12 : 16,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: colorScheme
                                                            .primary
                                                            .withOpacity(0.05),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: HugeIcon(
                                                        icon: _getIconForFolder(
                                                          folderName,
                                                        ),
                                                        color:
                                                            colorScheme.primary,
                                                        size: isSmallScreen
                                                            ? 28.0
                                                            : 32.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Container(
                                                    height: 1.5,
                                                    color: colorScheme
                                                        .outlineVariant
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        heatmapColors[index %
                                                                heatmapColors
                                                                    .length]
                                                            .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${(totalBytes > 0 ? (folderSize / totalBytes) * 100 : 0).toStringAsFixed(1)}%',
                                                    style: textTheme.labelLarge
                                                        ?.copyWith(
                                                          color:
                                                              heatmapColors[index %
                                                                  heatmapColors
                                                                      .length],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Text(
                                              folderName,
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Builder(
                                                  builder: (context) {
                                                    final sizeStr =
                                                        SizeFormatter.formatBytes(
                                                          folderSize.toInt(),
                                                        );
                                                    final parts = sizeStr.split(
                                                      ' ',
                                                    );
                                                    final val = parts.isNotEmpty
                                                        ? parts[0]
                                                        : '';
                                                    final unit =
                                                        parts.length > 1
                                                        ? parts[1].toLowerCase()
                                                        : '';
                                                    return RichText(
                                                      text: TextSpan(
                                                        children: [
                                                          TextSpan(
                                                            text: val,
                                                            style: textTheme
                                                                .titleLarge
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  color: colorScheme
                                                                      .primary,
                                                                ),
                                                          ),
                                                          TextSpan(
                                                            text: ' $unit',
                                                            style: textTheme
                                                                .titleSmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  color: colorScheme
                                                                      .primary
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme
                                                        .secondaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '$itemCount',
                                                        style: textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: colorScheme
                                                                  .onSecondaryContainer,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      HugeIcon(
                                                        icon: HugeIcons
                                                            .strokeRoundedArrowRight01,
                                                        color: colorScheme
                                                            .onSecondaryContainer,
                                                        size: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 100), // padding for FAB
                      ],
                    );
                  },
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFab({
    required VoidCallback onPressed,
    required dynamic icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required bool isExtended,
  }) {
    return const SizedBox.shrink();
  }

  Widget _buildMinimalStorageBreakdown(
    Map<String, double> folderSizes,
    double totalBytes,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (folderSizes.isEmpty || totalBytes == 0) return const SizedBox.shrink();

    final sortedFolders = folderSizes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFF1565C0), // Blue 800
      const Color(0xFF00695C), // Teal 800
      const Color(0xFFFF5252), // Lighter Red
      const Color(0xFFEF6C00), // Orange 800
      const Color(0xFF4527A0), // Deep Purple 800
      const Color(0xFF2E7D32), // Green 800
    ];

    List<Widget> barSegments = [];
    List<Widget> legendItems = [];
    int colorIndex = 0;

    double otherSize = 0;
    for (int i = 4; i < sortedFolders.length; i++) {
      otherSize += sortedFolders[i].value;
    }

    int itemsToShow = sortedFolders.length > 4 ? 4 : sortedFolders.length;

    for (int i = 0; i < itemsToShow; i++) {
      final folder = sortedFolders[i];
      final percentage = folder.value / totalBytes;
      final flex = (percentage * 1000).toInt();
      if (flex <= 0) continue;

      final color = colors[colorIndex % colors.length];

      barSegments.add(
        Expanded(
          flex: flex,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: colorScheme.surface, width: 1.5),
              borderRadius: BorderRadius.horizontal(
                left: i == 0 ? const Radius.circular(8) : Radius.zero,
                right: (i == itemsToShow - 1 && otherSize == 0)
                    ? const Radius.circular(8)
                    : Radius.zero,
              ),
            ),
          ),
        ),
      );

      legendItems.add(
        Padding(
          padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '${folder.key} (${(percentage * 100).toStringAsFixed(1)}%)',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

      colorIndex++;
    }

    if (otherSize > 0) {
      final percentage = otherSize / totalBytes;
      final flex = (percentage * 1000).toInt();
      if (flex > 0) {
        barSegments.add(
          Expanded(
            flex: flex,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border.all(color: colorScheme.surface, width: 1.5),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(8),
                ),
              ),
            ),
          ),
        );

        legendItems.add(
          Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Other (${(percentage * 100).toStringAsFixed(1)}%)',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(children: barSegments),
        ),
        const SizedBox(height: 16),
        Wrap(children: legendItems),
      ],
    );
  }

  dynamic _getIconForFolder(String folderName) {
    final lower = folderName.toLowerCase();
    if (lower.contains('whatsapp'))
      return HugeIcons.strokeRoundedMessageMultiple01;
    if (lower.contains('download')) return HugeIcons.strokeRoundedDownload01;
    if (lower.contains('pin')) return HugeIcons.strokeRoundedPinLocation01;
    if (lower.contains('dcim') || lower.contains('camera'))
      return HugeIcons.strokeRoundedCamera01;
    if (lower.contains('picture') || lower.contains('image'))
      return HugeIcons.strokeRoundedImage01;
    if (lower.contains('movie') || lower.contains('video'))
      return HugeIcons.strokeRoundedVideo01;
    if (lower.contains('screenshot')) return HugeIcons.strokeRoundedCamera02;
    if (lower.contains('telegram')) return HugeIcons.strokeRoundedTelegram;
    if (lower.contains('instagram')) return HugeIcons.strokeRoundedInstagram;
    if (lower.contains('facebook')) return HugeIcons.strokeRoundedFacebook01;
    if (lower.contains('twitter') || lower == 'x')
      return HugeIcons.strokeRoundedTwitter;
    if (lower.contains('document')) return HugeIcons.strokeRoundedFile01;
    if (lower.contains('bluetooth')) return HugeIcons.strokeRoundedBluetooth;
    return HugeIcons.strokeRoundedFolder01;
  }
}
