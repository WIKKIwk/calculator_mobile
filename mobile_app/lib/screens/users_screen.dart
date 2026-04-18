import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../graphql/queries.dart';
import '../models/user.dart';
import '../services/app_local_store.dart';
import '../widgets/offline_hint_banner.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  int _refreshKey = 0;

  void _refresh() {
    setState(() => _refreshKey++);
  }

  void _openAddOrEditUserSheet(BuildContext context, {User? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditUserSheet(
        user: user,
        onSaved: _refresh,
      ),
    );
  }

  Future<void> _deleteUser(BuildContext context, String id) async {
    final client = GraphQLProvider.of(context).value;
    final result = await client.mutate(
      MutationOptions(
        document: gql(deleteUserMutation),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ishchini o\'chirib bo\'lmadi: ${result.exception.toString()}')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ishchi muvaffaqiyatli o\'chirildi')),
        );
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Ishchilar'),
        backgroundColor: colorScheme.surfaceContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddOrEditUserSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Qo\'shish'),
      ),
      body: Query(
        key: ValueKey(_refreshKey),
        options: QueryOptions(
          document: gql(getUsersQuery),
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
        builder: (result, {fetchMore, refetch}) {
          final cached = result.data != null;
          if (result.isLoading && !cached) {
            return const Center(child: CircularProgressIndicator());
          }

          if (result.hasException && !cached) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Xatolik yuz berdi'),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Qayta urinish'),
                  )
                ],
              ),
            );
          }

          final rawList = result.data?['users'] as List? ?? [];
          final users = rawList.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();

          if (users.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              children: [
                if (result.hasException && cached) const OfflineHintBanner(),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.35,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off_outlined, size: 80, color: colorScheme.primary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('Hali ishchilar qo\'shilmagan', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (refetch != null) {
                await refetch();
              } else {
                _refresh();
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: users.length + (result.hasException && cached ? 1 : 0),
              itemBuilder: (context, index) {
                if (result.hasException && cached && index == 0) {
                  return const OfflineHintBanner();
                }
                final ui = (result.hasException && cached) ? index - 1 : index;
                final user = users[ui];
                return Dismissible(
                  key: Key(user.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    color: colorScheme.error,
                    child: Icon(Icons.delete, color: colorScheme.onError),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('O\'chirishni tasdiqlang'),
                        content: Text('${user.displayName} ni rostdan ham o\'chirmoqchimisiz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Bekor qilish'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                            child: const Text('O\'chirish'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    _deleteUser(context, user.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        child: Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      subtitle: Text(
                        'Qo\'shilgan: ${user.createdAt.substring(0, 10)}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openAddOrEditUserSheet(context, user: user),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AddEditUserSheet extends StatefulWidget {
  final User? user;
  final VoidCallback onSaved;

  const _AddEditUserSheet({this.user, required this.onSaved});

  @override
  State<_AddEditUserSheet> createState() => _AddEditUserSheetState();
}

class _AddEditUserSheetState extends State<_AddEditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstController;
  late final TextEditingController _lastController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstController = TextEditingController(text: widget.user?.firstName ?? '');
    _lastController = TextEditingController(text: widget.user?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final client = GraphQLProvider.of(context).value;

    final isEdit = widget.user != null;
    final mutation = isEdit ? updateUserMutation : createUserMutation;
    final variables = {
      'firstName': _firstController.text.trim(),
      'lastName': _lastController.text.trim(),
    };
    if (isEdit) {
      variables['id'] = widget.user!.id;
    }

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: variables,
      ),
    );

    setState(() => _isLoading = false);

    if (result.hasException) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: ${result.exception.toString()}')),
        );
      }
    } else {
      widget.onSaved();
      if (context.mounted) {
        final f = _firstController.text.trim();
        final l = _lastController.text.trim();
        final label = l.isEmpty ? f : '$f $l';
        await AppLocalStore.logEvent(
          isEdit ? 'ishchi_yangilandi' : 'ishchi_qoshildi',
          label,
        );
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Ishchi yangilandi' : 'Yangi ishchi qo\'shildi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              widget.user != null ? 'Ishchini tahrirlash' : 'Yangi ishchi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstController,
              decoration: const InputDecoration(
                labelText: 'Ism',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Ism kiriting' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastController,
              decoration: const InputDecoration(
                labelText: 'Sharif (ixtiyoriy)',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : () => _submit(context),
              icon: _isLoading 
                ? Container(width: 20, height: 20, padding: const EdgeInsets.all(2), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
              label: Text(widget.user != null ? 'Saqlash' : 'Qo\'shish'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
