import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/app_notifier.dart';
import '../core/constants.dart';
import '../core/api_service.dart';
import '../core/localization.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class ShopMember {
  final String id;
  final String name;
  final String role;
  final String phone;
  final bool isActive;

  ShopMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.isActive = true,
  });
}

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final List<ShopMember> _members = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() async {
    final auth = context.read<AuthProvider>();
    final targetBase = auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl;
    final apiService = ApiService(baseUrl: targetBase, apiKey: auth.apiKey);

    setState(() => _isLoading = true);
    final remoteStaff = await apiService.getStaffMembers();
    setState(() => _isLoading = false);

    setState(() {
      _members.clear();
      for (final m in remoteStaff) {
        _members.add(
          ShopMember(
            id: m['member_id'] ?? m['memberId'] ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
            name: m['name'] ?? 'Staff',
            role: m['role'] ?? 'Counter Cashier',
            phone: m['phone'] ?? '',
            isActive: m['active'] ?? m['isActive'] ?? true,
          ),
        );
      }
    });
  }

  void _deleteMember(ShopMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          ctx.tr('remove_staff_member'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        content: Text(
          '${ctx.tr('confirm_remove_staff')} (${member.name})',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel'), style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(ctx.tr('remove').toUpperCase()),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    final auth = context.read<AuthProvider>();
    final targetBase = auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl;
    final apiService = ApiService(baseUrl: targetBase, apiKey: auth.apiKey);

    final success = await apiService.deleteStaffMember(member.id);
    if (success) {
      setState(() {
        _members.removeWhere((m) => m.id == member.id);
      });
      if (mounted) {
        AppNotifier.success(context, '${member.name} removed from staff roster', title: 'MEMBER REMOVED');
      }
    } else {
      if (mounted) {
        AppNotifier.error(context, 'Failed to remove staff member', title: 'ACTION FAILED');
      }
    }
  }

  void _showAddMemberModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '1234');
    String selectedRole = 'Counter Cashier';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ctx.tr('add_staff_member').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
                enabled: !isSaving,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: '${ctx.tr('staff_name')} *',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person_rounded, color: AppColors.terracotta, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: phoneCtrl,
                enabled: !isSaving,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: '${ctx.tr('mobile_number')} *',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.forestMint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.phone_rounded, color: AppColors.forestMint, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  labelText: ctx.tr('role_permission'),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.warmNavy.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.badge_rounded, color: AppColors.warmNavy, size: 20),
                    ),
                  ),
                ),
                items: ['Counter Cashier', 'Shop Manager', 'Inventory Helper']
                    .map((r) => DropdownMenuItem(value: r, child: Text(ctx.trRole(r), style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600))))
                    .toList(),
                onChanged: isSaving ? null : (v) => selectedRole = v!,
              ),
              const SizedBox(height: 14),

              TextField(
                controller: pinCtrl,
                enabled: !isSaving,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: '${ctx.tr('security_pin')} *',
                  counterText: '',
                  helperText: ctx.tr('staff_pin_hint'),
                  helperStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.chaiGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.lock_rounded, color: AppColors.chaiGold, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracotta.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final pin = pinCtrl.text.trim();

                          if (name.isEmpty) {
                            AppNotifier.warning(ctx, 'Staff name is required', title: 'FIELD REQUIRED');
                            return;
                          }
                          if (phone.length < 10) {
                            AppNotifier.warning(ctx, 'Enter valid 10-digit mobile number', title: 'INVALID NUMBER');
                            return;
                          }
                          if (pin.length != 4) {
                            AppNotifier.warning(ctx, 'Enter a 4-digit security PIN', title: 'INVALID PIN');
                            return;
                          }

                          setModalState(() => isSaving = true);

                          final auth = context.read<AuthProvider>();
                          final targetBase = auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl;
                          final apiService = ApiService(baseUrl: targetBase, apiKey: auth.apiKey);
                          final memberId = 'm_${DateTime.now().millisecondsSinceEpoch}';

                          final added = await apiService.addStaffMember(
                            memberId: memberId,
                            name: name,
                            phone: phone,
                            role: selectedRole,
                            pin: pin,
                          );

                          if (added) {
                            _loadMembers();
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              AppNotifier.success(
                                context,
                                '$name added to store staff. They can now log in using PIN $pin.',
                                title: 'STAFF ADDED',
                              );
                            }
                          } else {
                            setModalState(() => isSaving = false);
                            if (mounted) {
                              AppNotifier.error(context, 'Failed to save staff member', title: 'SAVE ERROR');
                            }
                          }
                        },
                  icon: isSaving ? const SizedBox.shrink() : const Icon(Icons.person_add_rounded, size: 18),
                  label: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          ctx.tr('save_staff_member').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('staff_members'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberModal,
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text(context.tr('add_staff'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadMembers(),
        color: AppColors.terracotta,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.terracotta.withValues(alpha: 0.15),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.25), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.terracotta.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('multi_device_cashier_title'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.tr('multi_device_cashier_sub'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('store_staff_roster').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_members.length} ${context.tr('members_unit')}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                Center(child: Padding(padding: const EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.terracotta)))
              else if (_members.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 10),
                        Text(
                          context.tr('no_staff_title'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('no_staff_sub'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.terracotta.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.warmNavy.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        context.trRole(member.role),
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warmNavy),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(member.phone, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            onPressed: () => _deleteMember(member),
                            tooltip: 'Remove staff',
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
