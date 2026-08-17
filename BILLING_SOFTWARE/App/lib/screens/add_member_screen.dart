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
          'Remove Staff Member',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${member.name} (${member.phone}) from staff roster? They will no longer be able to log in.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('REMOVE'),
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
                    'ADD STAFF MEMBER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: nameCtrl,
                enabled: !isSaving,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(labelText: 'Staff Name *', prefixIcon: Icon(Icons.person_rounded, color: AppColors.terracotta)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                enabled: !isSaving,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                decoration: InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone_rounded, color: AppColors.terracotta)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(labelText: 'Role Permission', prefixIcon: Icon(Icons.badge_rounded, color: AppColors.warmNavy)),
                items: ['Counter Cashier', 'Shop Manager', 'Inventory Helper']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary))))
                    .toList(),
                onChanged: isSaving ? null : (v) => selectedRole = v!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                enabled: !isSaving,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: '4-digit Staff Security PIN *',
                  counterText: '',
                  helperText: 'Cashier will use this PIN to log in on their mobile device',
                  prefixIcon: Icon(Icons.lock_rounded, color: AppColors.chaiGold),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
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
                            if (ctx.mounted) {
                              AppNotifier.error(ctx, 'Failed to add staff member', title: 'SERVER ERROR');
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.person_add_rounded, size: 18),
                  label: Text(isSaving ? 'SAVING...' : 'SAVE STAFF MEMBER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          context.tr('staff_members').toUpperCase(),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.admin_panel_settings_rounded, color: AppColors.terracotta, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Multi-Device Cashier Access',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Added staff can log in on their phones to bill items, manage khata, and view inventory for your store.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STORE STAFF ROSTER',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${_members.length} members',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                Center(child: Padding(padding: const EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.terracotta)))
              else if (_members.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 10),
                        Text(
                          'No Staff Members Added Yet',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "+ Add Staff" below to add cashiers or managers with 4-digit PINs.',
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
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${member.role} • ${member.phone}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
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
