import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/api_service.dart';
import '../providers/auth_provider.dart';

class ShopMember {
  final String id;
  final String name;
  final String role; // Owner, Manager, Cashier, Helper
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

    final staffList = await apiService.getStaffMembers();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _members.clear();

        // Always include owner
        if (auth.ownerName.isNotEmpty) {
          _members.add(
            ShopMember(
              id: 'owner_1',
              name: auth.ownerName,
              role: 'Owner (Admin)',
              phone: auth.mobileNumber.isNotEmpty ? auth.mobileNumber : '',
            ),
          );
        }

        for (var s in staffList) {
          _members.add(
            ShopMember(
              id: s['member_id'] ?? s['_id'] ?? '',
              name: s['name'] ?? 'Staff',
              role: s['role'] ?? 'Staff',
              phone: s['phone'] ?? '',
            ),
          );
        }
      });
    }
  }

  void _showAddMemberModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '0000');
    String selectedRole = 'Counter Cashier';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Staff Member',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.warmPeach),
            ),
            const SizedBox(height: 6),
            Text(
              'Staff records are saved directly to MongoDB Atlas.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Member Name *', prefixIcon: Icon(Icons.person_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Member Role', prefixIcon: Icon(Icons.badge_rounded, color: AppColors.warmCoral)),
              items: ['Counter Cashier', 'Shop Manager', 'Inventory Helper']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => selectedRole = v!,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Set 4-digit Member PIN', prefixIcon: Icon(Icons.lock_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 20),

            GradientButton(
              text: 'Save Staff Member',
              icon: Icons.person_add_rounded,
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                  final auth = context.read<AuthProvider>();
                  final targetBase = auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl;
                  final apiService = ApiService(baseUrl: targetBase, apiKey: auth.apiKey);
                  final memberId = 'm_${DateTime.now().millisecondsSinceEpoch}';

                  final newMember = ShopMember(
                    id: memberId,
                    name: nameCtrl.text.trim(),
                    role: selectedRole,
                    phone: phoneCtrl.text.trim(),
                  );

                  setState(() {
                    _members.add(newMember);
                  });

                  await apiService.addStaffMember(
                    memberId: memberId,
                    name: newMember.name,
                    phone: newMember.phone,
                    role: newMember.role,
                    pin: pinCtrl.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${newMember.name} saved as staff member!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.badge_rounded, color: AppColors.warmCoral, size: 24),
            const SizedBox(width: 10),
            Text(
              'Shop Staff & Members',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadMembers,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.warmCoral))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    color: AppColors.darkCard.withValues(alpha: 0.9),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warmCoral.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_rounded, color: AppColors.warmCoral, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Role & Access Control',
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Manage cashier and helper access to keep cash counters secure.',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Members (${_members.length})',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddMemberModal,
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Add Member'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmCoral,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  ..._members.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: m.role.contains('Owner')
                                    ? AppColors.warmPeach.withValues(alpha: 0.2)
                                    : AppColors.accentTeal.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  m.role.contains('Owner') ? Icons.stars_rounded : Icons.person_rounded,
                                  color: m.role.contains('Owner') ? AppColors.warmPeach : AppColors.accentTeal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  Text(m.phone.isNotEmpty ? m.phone : 'Store Admin', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: m.role.contains('Owner') ? AppColors.warmPeach.withValues(alpha: 0.15) : AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                m.role,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: m.role.contains('Owner') ? AppColors.warmPeach : AppColors.accentTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
