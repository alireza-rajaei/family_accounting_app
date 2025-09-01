import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../di/locator.dart';
import '../../data/local/db/app_database.dart';
import '../cubits/users_cubit.dart';

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
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: tr('users.search_hint'),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            cubit.watch('');
                            setState(() {});
                          },
                        ),
                ),
                onChanged: (v) {
                  cubit.watch(v);
                  setState(() {});
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<UsersCubit, UsersState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.users.isEmpty) {
                    return Center(child: Text(tr('users.not_found')));
                  }
                  return ListView.separated(
                    itemCount: state.users.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final u = state.users[index];
                      return ListTile(
                        title: Text('${u.firstName} ${u.lastName}'),
                        subtitle: Text([u.fatherName, u.mobileNumber].where((e) => (e ?? '').isNotEmpty).join(' · ')),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              _openUserSheet(context, user: u);
                            } else if (v == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(tr('users.delete')),
                                  content: Text(tr('users.confirm_delete', args: ['${u.firstName} ${u.lastName}'])),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
                                    FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('users.delete'))),
                                  ],
                                ),
                              );
                              if (ok == true && context.mounted) {
                                await context.read<UsersCubit>().deleteUser(u.id);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text(tr('users.edit'))),
                            PopupMenuItem(value: 'delete', child: Text(tr('users.delete'))),
                          ],
                        ),
                        onTap: () => _openUserSheet(context, user: u),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUserSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openUserSheet(BuildContext context, {User? user}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UserSheet(user: user),
    );
  }
}

class _UserSheet extends StatefulWidget {
  final User? user;
  const _UserSheet({this.user});
  @override
  State<_UserSheet> createState() => _UserSheetState();
}

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
    final padding = MediaQuery.of(context).viewInsets + const EdgeInsets.all(16);
    return Padding(
      padding: padding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? tr('users.edit') : tr('users.add'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: firstName,
                  decoration: InputDecoration(labelText: tr('users.first_name')),
                  validator: (v) => (v == null || v.isEmpty) ? 'الزامی' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: lastName,
                  decoration: InputDecoration(labelText: tr('users.last_name')),
                  validator: (v) => (v == null || v.isEmpty) ? 'الزامی' : null,
                ),
              ),
            ]),
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
                        fatherName: fatherName.text.trim().isEmpty ? null : fatherName.text.trim(),
                        mobile: mobile.text.trim().isEmpty ? null : mobile.text.trim(),
                      );
                    } else {
                      await cubit.addUser(
                        firstName: firstName.text.trim(),
                        lastName: lastName.text.trim(),
                        fatherName: fatherName.text.trim().isEmpty ? null : fatherName.text.trim(),
                        mobile: mobile.text.trim().isEmpty ? null : mobile.text.trim(),
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


