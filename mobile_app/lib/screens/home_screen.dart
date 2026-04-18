import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../graphql/client.dart';
import '../graphql/queries.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/app_local_store.dart';
import '../services/offline_sync.dart';
import '../widgets/offline_hint_banner.dart';
import '../widgets/product_card.dart';
import '../widgets/add_product_sheet.dart';
import 'activity_log_screen.dart';
import 'backup_security_screen.dart';
import 'users_screen.dart';
import 'user_calculation_screen.dart';
import 'records_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const double _kSideNavBreakpoint = 720;

  int _refreshKey = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OfflineSyncService.flushPendingRecords(GraphQLConfig.client.value);
      if (mounted) setState(() => _refreshKey++);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      OfflineSyncService.flushPendingRecords(GraphQLConfig.client.value).then((_) {
        if (mounted) setState(() => _refreshKey++);
      });
    }
  }

  void _refresh() {
    setState(() => _refreshKey++);
  }

  void _onDestinationSelected(int idx) {
    const tabs = ['kalkulyatsiya', 'mahsulotlar', 'ishchilar', 'data'];
    AppLocalStore.logEvent('tab', tabs[idx]);
    setState(() => _currentIndex = idx);
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductSheet(onProductAdded: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final useSideNav =
        MediaQuery.sizeOf(context).width >= _kSideNavBreakpoint;
    final listBottomPad = useSideNav ? 24.0 : 100.0;

    Widget? fab;
    if (_currentIndex == 1) {
      fab = FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Qo\'shish'),
        elevation: 4,
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _currentIndex == 2
          ? null
          : AppBar(
        toolbarHeight: 48,
        backgroundColor: colorScheme.surfaceContainer,
        actions: _currentIndex == 3
            ? [
                IconButton(
                  tooltip: 'Zaxira va xavfsizlik',
                  icon: const Icon(Icons.enhanced_encryption_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BackupSecurityScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Faoliyat jurnali',
                  icon: const Icon(Icons.analytics_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ActivityLogScreen(),
                      ),
                    );
                  },
                ),
              ]
            : null,
        title: Text(
          'Hisoblagich (online)',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: useSideNav
          ? null
          : NavigationBar(
              height: 64,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calculate_outlined),
                  selectedIcon: Icon(Icons.calculate),
                  label: 'Kalkulyatsiya',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag),
                  label: 'Mahsulotlar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Ishchilar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.data_usage_outlined),
                  selectedIcon: Icon(Icons.data_usage),
                  label: 'Data',
                ),
              ],
            ),
      body: useSideNav
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: colorScheme.surfaceContainer,
                  indicatorColor: colorScheme.secondaryContainer,
                  leading: const SizedBox(height: 8),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.calculate_outlined),
                      selectedIcon: Icon(Icons.calculate),
                      label: Text('Kalkulyatsiya'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.shopping_bag_outlined),
                      selectedIcon: Icon(Icons.shopping_bag),
                      label: Text('Mahsulotlar'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Ishchilar'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.data_usage_outlined),
                      selectedIcon: Icon(Icons.data_usage),
                      label: Text('Data'),
                    ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _buildBody(
                    context,
                    colorScheme,
                    listBottomPad: listBottomPad,
                  ),
                ),
              ],
            )
          : _buildBody(
              context,
              colorScheme,
              listBottomPad: listBottomPad,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colorScheme, {
    required double listBottomPad,
  }) {
    if (_currentIndex == 2) return const UsersScreen();
    if (_currentIndex == 3) return const RecordsScreen();

    if (_currentIndex == 0) {
      // Kalkulyatsiya - Ishchilarni ko'rsatish
      return Query(
        key: ValueKey('users_$_refreshKey'),
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
            return const Center(child: Text('Server xatosi'));
          }

          final items = result.data?['users'] as List? ?? [];
          final users = items.map((e) => User.fromJson(e)).toList();

          if (users.isEmpty) {
            return ListView(
              padding: EdgeInsets.only(top: 8, bottom: listBottomPad),
              children: [
                if (result.hasException && cached) const OfflineHintBanner(),
                const Center(child: Text('Hali ishchilar qo\'shilmagan')),
              ],
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(top: 8, bottom: listBottomPad),
            itemCount: users.length + (result.hasException && cached ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (result.hasException && cached && i == 0) {
                return const OfflineHintBanner();
              }
              final userIndex = (result.hasException && cached) ? i - 1 : i;
              final user = users[userIndex];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserCalculationScreen(user: user)),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'I'),
                ),
                title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              );
            },
          );
        },
      );
    }

    // Mahsulotlar
    return Query(
      key: ValueKey('products_$_refreshKey'),
        options: QueryOptions(
          document: gql(getProductsQuery),
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
        builder: (result, {fetchMore, refetch}) {
        final cached = result.data != null;
        if (result.isLoading && !cached) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = result.data?['products'] as List? ?? [];
        final products = items.map((e) => Product.fromJson(e)).toList();

        Future<void> handleRefresh() async {
          if (refetch != null) {
            await refetch();
          } else {
            _refresh();
          }
        }

        if (products.isEmpty) {
          return RefreshIndicator(
            onRefresh: handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (result.hasException && cached) const OfflineHintBanner(),
                const SizedBox(height: 100),
                Icon(Icons.shopping_basket_outlined, size: 80, color: colorScheme.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 20),
                Text('Hali mahsulot yo\'q', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                const SizedBox(height: 32),
                UnconstrainedBox(
                  child: FilledButton.icon(
                    onPressed: () => _openAddSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Mahsulot qo\'shish'),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: handleRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: 8, bottom: listBottomPad),
            itemCount: products.length + (result.hasException && cached ? 1 : 0),
            itemBuilder: (_, i) {
              if (result.hasException && cached && i == 0) {
                return const OfflineHintBanner();
              }
              final pi = (result.hasException && cached) ? i - 1 : i;
              return ProductCard(
                product: products[pi],
                index: pi,
                onProductUpdated: () {
                  if (refetch != null) {
                    refetch();
                  } else {
                    _refresh();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
