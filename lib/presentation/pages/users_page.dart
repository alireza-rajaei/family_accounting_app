import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../di/locator.dart';
import '../../data/local/db/app_database.dart';
import '../cubits/users_cubit.dart';
import '../../app/utils/format.dart';
// removed: not needed here after using openTransactionSheet
import 'transactions_page.dart' show showTransactionSheet;

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit(locator())..watch(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();
  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<UsersCubit, UsersState>(
          builder: (context, state) {
            final users = state.users;
            return Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SearchHeaderDelegate(
                        searchController: _search,
                        hintText: tr('users.search_hint'),
                        onChanged: (v) {
                          cubit.watch(v);
                          setState(() {});
                        },
                        onClear: () {
                          _search.clear();
                          cubit.watch('');
                          setState(() {});
                        },
                      ),
                    ),
                    if (state.loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (users.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text(tr('users.not_found'))),
                      ),
                    if (!state.loading && users.isNotEmpty)
                      ..._buildGroupedUserSlivers(users),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUserSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildGroupedUserSlivers(List<User> users) {
    final List<Widget> slivers = [];
    String? currentHeader;
    final List<User> buffer = [];

    void flushBuffer() {
      if (currentHeader == null || buffer.isEmpty) return;
      final String safeHeader = currentHeader;
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            height: 36,
            child: Text(
              safeHeader,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
      final List<User> sectionItems = List<User>.from(buffer);
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final u = sectionItems[index];
            return _UserTile(
              user: u,
              onTap: () => _openUserSheet(context, user: u),
              onSelectedAction: (v) async {
                if (v == 'add_tx') {
                  await _openTransactionSheetForUser(context, userId: u.id);
                } else if (v == 'edit') {
                  _openUserSheet(context, user: u);
                } else if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(tr('users.delete')),
                      content: Text(
                        '${tr('users.confirm_delete', namedArgs: {'name': '${u.firstName} ${u.lastName}'})}\n${tr('users.delete_cascade_note')}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(tr('common.cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(tr('users.delete')),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<UsersCubit>().deleteUser(u.id);
                  }
                }
              },
            );
          }, childCount: sectionItems.length),
        ),
      );
      buffer.clear();
    }

    for (final u in users) {
      final hdr = _initialOf(u);
      if (currentHeader == null) {
        currentHeader = hdr;
      }
      if (hdr != currentHeader) {
        flushBuffer();
        currentHeader = hdr;
      }
      buffer.add(u);
    }
    flushBuffer();

    return slivers;
  }

  Future<void> _openTransactionSheetForUser(
    BuildContext context, {
    int? userId,
  }) async {
    await showTransactionSheet(context, initialUserId: userId);
  }

  String _initialOf(User u) {
    final source = (u.firstName.isNotEmpty ? u.firstName : u.lastName).trim();
    if (source.isEmpty) return '#';
    return source.substring(0, 1).toUpperCase();
  }

  Future<void> _openUserSheet(BuildContext context, {User? user}) async {
    final usersCubit = context.read<UsersCubit>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BlocProvider.value(
        value: usersCubit,
        child: _UserSheet(user: user),
      ),
    );
  }
}

class _UserBalanceText extends StatelessWidget {
  final int userId;
  const _UserBalanceText({required this.userId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: context.read<UsersCubit>().getUserBalance(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text('${tr('users.balance')}: ...');
        }
        final balance = snapshot.data ?? 0;
        return Text('${tr('users.balance')}: ${formatThousands(balance)}');
      },
    );
  }
}

class _UserSheet extends StatefulWidget {
  final User? user;
  const _UserSheet({this.user});
  @override
  State<_UserSheet> createState() => _UserSheetState();
}

// Transaction sheet wrapper customized for Users page to preselect user
// wrapper حذف شد

class _UserSheetState extends State<_UserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController firstName;
  late final TextEditingController lastName;
  late final TextEditingController fatherName;
  late final TextEditingController mobile;

  @override
  void initState() {
    super.initState();
    firstName = TextEditingController(text: widget.user?.firstName ?? '');
    lastName = TextEditingController(text: widget.user?.lastName ?? '');
    fatherName = TextEditingController(text: widget.user?.fatherName ?? '');
    mobile = TextEditingController(text: widget.user?.mobileNumber ?? '');
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    fatherName.dispose();
    mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final padding =
        MediaQuery.of(context).viewInsets + const EdgeInsets.all(16);
    return Padding(
      padding: padding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? tr('users.edit') : tr('users.add'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: firstName,
                    decoration: InputDecoration(
                      labelText: tr('users.first_name'),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'الزامی' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: lastName,
                    decoration: InputDecoration(
                      labelText: tr('users.last_name'),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'الزامی' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fatherName,
              decoration: InputDecoration(labelText: tr('users.father_name')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: tr('users.mobile')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final cubit = context.read<UsersCubit>();
                    if (isEdit) {
                      await cubit.updateUser(
                        id: widget.user!.id,
                        firstName: firstName.text.trim(),
                        lastName: lastName.text.trim(),
                        fatherName: fatherName.text.trim().isEmpty
                            ? null
                            : fatherName.text.trim(),
                        mobile: mobile.text.trim().isEmpty
                            ? null
                            : mobile.text.trim(),
                      );
                    } else {
                      await cubit.addUser(
                        firstName: firstName.text.trim(),
                        lastName: lastName.text.trim(),
                        fatherName: fatherName.text.trim().isEmpty
                            ? null
                            : fatherName.text.trim(),
                        mobile: mobile.text.trim().isEmpty
                            ? null
                            : mobile.text.trim(),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text(isEdit ? tr('users.save') : tr('users.create')),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  _SearchHeaderDelegate({
    required this.searchController,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 1 : 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: hintText,
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    ),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.searchController != searchController ||
        oldDelegate.hintText != hintText;
  }
}

class _UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final ValueChanged<String> onSelectedAction;

  const _UserTile({
    required this.user,
    required this.onTap,
    required this.onSelectedAction,
  });

  String _initials() {
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    if (first.isEmpty && last.isEmpty) return '#';
    final i1 = first.isNotEmpty ? first[0] : '';
    final i2 = last.isNotEmpty ? last[0] : '';
    final initials = (i1 + i2).toUpperCase();
    return initials.isEmpty ? '#' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(_initials())),
            title: Text('${user.firstName} ${user.lastName}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    user.fatherName,
                    user.mobileNumber,
                  ].where((e) => (e ?? '').isNotEmpty).join(' · '),
                ),
                const SizedBox(height: 2),
                _UserBalanceText(userId: user.id),
              ],
            ),
            trailing: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: onSelectedAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'add_tx',
                  child: Text(tr('users.add_transaction')),
                ),
                PopupMenuItem(value: 'edit', child: Text(tr('users.edit'))),
                PopupMenuItem(value: 'delete', child: Text(tr('users.delete'))),
              ],
            ),
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
