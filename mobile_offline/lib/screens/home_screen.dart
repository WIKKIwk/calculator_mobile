import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/app_local_store.dart';
import '../services/offline_entity_store.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  /// Keng ekranda (PC) chapda NavigationRail; mobil — pastdagi NavigationBar.
  static const double _kSideNavBreakpoint = 720;

  int _refreshKey = 0;
  int _currentIndex = 0;

  void _refresh() {
    setState(() => _refreshKey++);
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

  void _onDestinationSelected(int idx) {
    const tabs = ['kalkulyatsiya', 'mahsulotlar', 'ishchilar', 'data'];
    AppLocalStore.logEvent('tab', tabs[idx]);
    setState(() => _currentIndex = idx);
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
                'Hisoblagich (offline)',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
      floatingActionButton: useSideNav ? null : fab,
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
                  trailing: fab != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: fab,
                        )
                      : null,
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
      return FutureBuilder<List<User>>(
        key: ValueKey('users_$_refreshKey'),
        future: OfflineEntityStore.users(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Xato: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return ListView(
              padding: EdgeInsets.only(top: 8, bottom: listBottomPad),
              children: const [
                Center(child: Text('Hali ishchilar qo\'shilmagan')),
              ],
            );
          }
          return ListView.builder(
            padding: EdgeInsets.only(top: 8, bottom: listBottomPad),
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final user = users[i];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserCalculationScreen(user: user),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(
                    user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'I',
                  ),
                ),
                title: Text(
                  user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              );
            },
          );
        },
      );
    }

    return FutureBuilder<List<Product>>(
      key: ValueKey('products_$_refreshKey'),
      future: OfflineEntityStore.products(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Xato: ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];

        Future<void> handleRefresh() async {
          _refresh();
        }

        if (products.isEmpty) {
          return RefreshIndicator(
            onRefresh: handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 100),
                Icon(
                  Icons.shopping_basket_outlined,
                  size: 80,
                  color: colorScheme.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hali mahsulot yo\'q',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
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
            itemCount: products.length,
            itemBuilder: (_, i) {
              return ProductCard(
                product: products[i],
                index: i,
                onProductUpdated: _refresh,
              );
            },
          ),
        );
      },
    );
  }
}
