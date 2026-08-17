import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/localization.dart';
import '../providers/locale_provider.dart';

class LanguagePickerButton extends StatelessWidget {
  final bool isCompact;

  const LanguagePickerButton({
    super.key,
    this.isCompact = false,
  });

  static const List<Map<String, String>> languages = [
    {
      'code': 'en',
      'name': 'English',
      'native': 'English',
      'subtitle': 'Default POS billing language',
    },
    {
      'code': 'hi',
      'name': 'Hindi',
      'native': 'हिंदी (Hindi)',
      'subtitle': 'सरल हिंदी में बिलिंग एवं खाता',
    },
    {
      'code': 'mr',
      'name': 'Marathi',
      'native': 'मराठी (Marathi)',
      'subtitle': 'मराठीमध्ये सोपी बिलिंग व उधारी वही',
    },
    {
      'code': 'gu',
      'name': 'Gujarati',
      'native': 'ગુજરાતી (Gujarati)',
      'subtitle': 'સરળ ગુજરાતીમાં બિલિંગ અને ખાતાવહી',
    },
    {
      'code': 'ta',
      'name': 'Tamil',
      'native': 'தமிழ் (Tamil)',
      'subtitle': 'எளிய தமிழில் பில்லிங் மற்றும் கடன் புத்தகம்',
    },
    {
      'code': 'te',
      'name': 'Telugu',
      'native': 'తెలుగు (Telugu)',
      'subtitle': 'సులభమైన తెలుగులో బిల్లింగ్ మరియు ఖాతా పుస్తకం',
    },
  ];

  static void showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final currentLocale = sheetContext.watch<LocaleProvider>().locale;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.language_rounded, color: AppColors.terracotta, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          sheetContext.tr('choose_language'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final lang = languages[index];
                    final isSelected = currentLocale == lang['code'];

                    return InkWell(
                      onTap: () {
                        sheetContext.read<LocaleProvider>().setLocale(lang['code']!);
                        Navigator.pop(sheetContext);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.terracotta.withValues(alpha: 0.08) : AppColors.canvas,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.terracotta : AppColors.borderSubtle,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['native']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? AppColors.terracotta : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lang['subtitle']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: AppColors.terracotta, size: 20)
                            else
                              Icon(Icons.radio_button_unchecked_rounded, color: AppColors.borderStrong, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = context.watch<LocaleProvider>().locale;
    final currentLang = languages.firstWhere(
      (l) => l['code'] == currentCode,
      orElse: () => languages.first,
    );

    if (isCompact) {
      return IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(Icons.language_rounded, size: 18, color: AppColors.terracotta),
        ),
        onPressed: () => showLanguageBottomSheet(context),
        tooltip: context.tr('choose_language'),
      );
    }

    return InkWell(
      onTap: () => showLanguageBottomSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 16, color: AppColors.terracotta),
            const SizedBox(width: 6),
            Text(
              currentLang['name']!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
