import 'package:flutter/material.dart';

@immutable
class AppNavigationColors extends ThemeExtension<AppNavigationColors> {
  const AppNavigationColors({
    required this.recipes,
    required this.planner,
    required this.settings,
  });
  final Color recipes;
  final Color planner;
  final Color settings;

  static const light = AppNavigationColors(
    recipes: Color(0xFFAF542B),
    planner: Color(0xFF177A84),
    settings: Color(0xFF7D56A3),
  );
  static const dark = AppNavigationColors(
    recipes: Color(0xFFFFB18B),
    planner: Color(0xFF81CED3),
    settings: Color(0xFFCBB0EC),
  );

  @override
  AppNavigationColors copyWith({
    Color? recipes,
    Color? planner,
    Color? settings,
  }) => AppNavigationColors(
    recipes: recipes ?? this.recipes,
    planner: planner ?? this.planner,
    settings: settings ?? this.settings,
  );

  @override
  AppNavigationColors lerp(covariant AppNavigationColors? other, double t) =>
      other == null
      ? this
      : AppNavigationColors(
          recipes: Color.lerp(recipes, other.recipes, t)!,
          planner: Color.lerp(planner, other.planner, t)!,
          settings: Color.lerp(settings, other.settings, t)!,
        );
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.running,
    required this.paused,
    required this.completed,
    required this.warning,
  });
  final Color running;
  final Color paused;
  final Color completed;
  final Color warning;
  static const light = AppSemanticColors(
    running: Color(0xFF355E46),
    paused: Color(0xFF5F6970),
    completed: Color(0xFF487253),
    warning: Color(0xFF936000),
  );
  static const dark = AppSemanticColors(
    running: Color(0xFFA8CDB0),
    paused: Color(0xFFBCC7D0),
    completed: Color(0xFFA2C7AB),
    warning: Color(0xFFF0BE65),
  );
  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);
  @override
  AppSemanticColors copyWith({
    Color? running,
    Color? paused,
    Color? completed,
    Color? warning,
  }) => AppSemanticColors(
    running: running ?? this.running,
    paused: paused ?? this.paused,
    completed: completed ?? this.completed,
    warning: warning ?? this.warning,
  );
  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) =>
      other == null
      ? this
      : AppSemanticColors(
          running: Color.lerp(running, other.running, t)!,
          paused: Color.lerp(paused, other.paused, t)!,
          completed: Color.lerp(completed, other.completed, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
        );
}

class AppTheme {
  static ThemeData get light => forBrightness(Brightness.light);
  static ThemeData get dark => forBrightness(Brightness.dark);
  static ThemeData forBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF355E46),
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFFA8CDB0) : const Color(0xFF355E46),
          onPrimary: dark ? const Color(0xFF193423) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF2E4435)
              : const Color(0xFFE4EEE3),
          onPrimaryContainer: dark
              ? const Color(0xFFE0EFDF)
              : const Color(0xFF233D2C),
          secondary: dark ? const Color(0xFFBCC7D0) : const Color(0xFF5F6970),
          onSecondary: dark ? const Color(0xFF222A2F) : Colors.white,
          tertiary: dark ? const Color(0xFFA2C7AB) : const Color(0xFF487253),
          onTertiary: dark ? const Color(0xFF173622) : Colors.white,
          error: dark ? const Color(0xFFFFB4A8) : const Color(0xFFB44435),
          onError: dark ? const Color(0xFF4B2621) : Colors.white,
          errorContainer: dark
              ? const Color(0xFF4B2621)
              : const Color(0xFFFBE8E4),
          onErrorContainer: dark
              ? const Color(0xFFFBE8E4)
              : const Color(0xFF69251D),
          surface: dark ? const Color(0xFF232B25) : Colors.white,
          onSurface: dark ? const Color(0xFFECEEE6) : const Color(0xFF282D28),
          onSurfaceVariant: dark
              ? const Color(0xFFB8C3B8)
              : const Color(0xFF5D675D),
          surfaceDim: dark ? const Color(0xFF191E1A) : const Color(0xFFF2F0E9),
          surfaceBright: dark ? const Color(0xFF303B32) : Colors.white,
          surfaceContainerLowest: dark ? const Color(0xFF171C18) : Colors.white,
          surfaceContainerLow: dark
              ? const Color(0xFF202722)
              : const Color(0xFFF4F4ED),
          surfaceContainer: dark
              ? const Color(0xFF28322B)
              : const Color(0xFFEEEFE7),
          surfaceContainerHigh: dark
              ? const Color(0xFF303B33)
              : const Color(0xFFE7EBE2),
          surfaceContainerHighest: dark
              ? const Color(0xFF39463B)
              : const Color(0xFFDEE4D9),
          outline: dark ? const Color(0xFF879587) : const Color(0xFF788273),
          outlineVariant: dark
              ? const Color(0xFF3D4B3F)
              : const Color(0xFFD7DDD1),
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
    );
    const numbers = [FontFeature.tabularFigures()];
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium!.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -.6,
      ),
      headlineSmall: base.textTheme.headlineSmall!.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -.4,
      ),
      titleLarge: base.textTheme.titleLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFeatures: numbers,
      ),
      titleSmall: base.textTheme.titleSmall!.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge!.copyWith(fontSize: 15, height: 1.5),
      bodyMedium: base.textTheme.bodyMedium!.copyWith(
        fontSize: 14,
        height: 1.45,
        fontFeatures: numbers,
      ),
      bodySmall: base.textTheme.bodySmall!.copyWith(
        fontSize: 12,
        height: 1.4,
        color: colors.onSurfaceVariant,
        fontFeatures: numbers,
      ),
      labelLarge: base.textTheme.labelLarge!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFeatures: numbers,
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF191E1A)
          : const Color(0xFFF7F5EF),
      extensions: [
        dark ? AppSemanticColors.dark : AppSemanticColors.light,
        dark ? AppNavigationColors.dark : AppNavigationColors.light,
      ],
      appBarTheme: AppBarThemeData(
        backgroundColor: dark
            ? const Color(0xFF191E1A)
            : const Color(0xFFF7F5EF),
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        toolbarHeight: 72,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: shape,
          side: BorderSide(color: colors.outlineVariant),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: shape,
          foregroundColor: colors.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: shape.copyWith(side: BorderSide(color: colors.outlineVariant)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
        headingTextStyle: text.titleSmall,
        dataTextStyle: text.bodyMedium,
        horizontalMargin: 16,
        columnSpacing: 24,
        dividerThickness: .6,
        dataRowMinHeight: 64,
        dataRowMaxHeight: 80,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium!.copyWith(
          color: colors.onSurfaceVariant,
        ),
        shape: shape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colors.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: text.bodySmall!.copyWith(color: colors.onInverseSurface),
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}
