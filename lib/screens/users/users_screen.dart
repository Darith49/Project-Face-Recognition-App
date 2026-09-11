import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/empty_state.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<UserProvider>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList('student'),
                    _buildUserList('teacher'),
                    _buildUserList(null), // All users
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.hasPermission('manage_users')) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showCreateUserDialog();
            },
            backgroundColor: AppTheme.primaryColor,
            elevation: 2,
            child: const Icon(Icons.person_add_rounded, size: 22),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.people_rounded,
              color: AppTheme.accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Users',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${provider.users.length} registered users',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.textTertiary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textTertiary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textTertiary,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'Students'),
          Tab(text: 'Teachers'),
          Tab(text: 'All'),
        ],
      ),
    );
  }

  Widget _buildUserList(String? roleFilter) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        var users = _searchController.text.isNotEmpty
            ? provider.searchUsers(_searchController.text)
            : provider.users;

        if (roleFilter != null) {
          users = users.where((u) => u.role == roleFilter).toList();
        }

        if (users.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No users found',
            subtitle: 'Try adjusting your search or filters',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryColor,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserCard(users[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    final roleColors = {
      'admin': AppTheme.errorColor,
      'teacher': AppTheme.warningColor,
      'student': AppTheme.primaryColor,
      'employee': AppTheme.accentColor,
    };
    final color = roleColors[user.role] ?? AppTheme.primaryColor;

    return GlassCard(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailScreen(user: user),
          ),
        ).then((_) => _loadData());
      },
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.hasFaceData) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.face_rounded,
                          color: AppTheme.successColor, size: 15),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.userId} • ${user.className ?? user.department ?? user.role}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              color: AppTheme.textTertiary, size: 18),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final userIdController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'student';
    String selectedGender = 'Male';
    String? selectedClass;
    String? selectedDepartment;
    String? selectedGroup;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          AppTheme.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add New User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: userIdController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'User ID (e.g., STD009)',
                              prefixIcon: Icon(Icons.badge_outlined,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: emailController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passwordController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  Icon(Icons.lock_outline, size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: phoneController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Phone (Optional)',
                              prefixIcon: Icon(Icons.phone_outlined,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Role dropdown
                          DropdownButtonFormField<String>(
                            initialValue: selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              prefixIcon:
                                  Icon(Icons.work_outline, size: 20),
                            ),
                            dropdownColor: AppTheme.inputDark,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            items: const [
                              DropdownMenuItem(
                                  value: 'student',
                                  child: Text('Student')),
                              DropdownMenuItem(
                                  value: 'teacher',
                                  child: Text('Teacher')),
                              DropdownMenuItem(
                                  value: 'employee',
                                  child: Text('Employee')),
                              DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('Admin')),
                            ],
                            onChanged: (v) => setModalState(
                                () => selectedRole = v!),
                          ),
                          const SizedBox(height: 12),
                          // Gender dropdown
                          DropdownButtonFormField<String>(
                            initialValue: selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon:
                                  Icon(Icons.wc_outlined, size: 20),
                            ),
                            dropdownColor: AppTheme.inputDark,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male')),
                              DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female')),
                              DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other')),
                            ],
                            onChanged: (v) => setModalState(
                                () => selectedGender = v!),
                          ),
                          const SizedBox(height: 12),
                          // Class & Department
                          TextField(
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Class (e.g., CS-Y3)',
                              prefixIcon: Icon(Icons.class_outlined,
                                  size: 20),
                            ),
                            onChanged: (v) =>
                                selectedClass = v.isEmpty ? null : v,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              prefixIcon: Icon(
                                  Icons.business_outlined,
                                  size: 20),
                            ),
                            onChanged: (v) => selectedDepartment =
                                v.isEmpty ? null : v,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Group (Optional)',
                              prefixIcon: Icon(Icons.group_outlined,
                                  size: 20),
                            ),
                            onChanged: (v) =>
                                selectedGroup = v.isEmpty ? null : v,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.isEmpty ||
                                    userIdController.text.isEmpty ||
                                    emailController.text.isEmpty ||
                                    passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please fill in all required fields'),
                                      backgroundColor:
                                          AppTheme.errorColor,
                                    ),
                                  );
                                  return;
                                }

                                final now = DateTime.now();
                                final user = UserModel(
                                  id: const Uuid().v4(),
                                  userId: userIdController.text,
                                  name: nameController.text,
                                  email: emailController.text,
                                  password: passwordController.text,
                                  gender: selectedGender,
                                  role: selectedRole,
                                  group: selectedGroup,
                                  className: selectedClass,
                                  department: selectedDepartment,
                                  phone: phoneController.text.isEmpty
                                      ? null
                                      : phoneController.text,
                                  createdAt: now,
                                  updatedAt: now,
                                );

                                final auth =
                                    context.read<AuthProvider>();
                                final success = await context
                                    .read<UserProvider>()
                                    .createUser(
                                      user,
                                      createdBy:
                                          auth.currentUser?.id,
                                    );

                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${user.name} has been added'),
                                      backgroundColor:
                                          AppTheme.successColor,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Create User',
                                  style: TextStyle(fontSize: 14)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
