import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/real_time_data_provider.dart';
import 'appliance_widget.dart';

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<RealTimeDataProvider>(context, listen: false).connectToServer());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    // Simulate refresh delay
    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      Provider.of<RealTimeDataProvider>(context, listen: false).connectToServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealTimeDataProvider>(
      builder: (context, provider, child) {
        if (!provider.isConnected) {
          return _buildConnectionError();
        }

        final filteredAppliances = provider.appliances
            .where((appliance) =>
            appliance.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        final onAppliances = filteredAppliances.where((a) => a.isOn).toList();
        final offAppliances = filteredAppliances.where((a) => !a.isOn).toList();

        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshData,
          displacement: 20,
          color: Colors.blue,
          backgroundColor: Colors.white,
          strokeWidth: 3,
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSearchBar(),
              _buildSummarySection(onAppliances.length, offAppliances.length),
              if (onAppliances.isNotEmpty) ...[
                _buildSectionHeader('Active Appliances', Icons.power, Colors.green),
                _buildApplianceGrid(onAppliances),
              ],
              if (offAppliances.isNotEmpty) ...[
                _buildSectionHeader('Inactive Appliances', Icons.power_off, Colors.red),
                _buildApplianceGrid(offAppliances),
              ],
              SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Connecting to server...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search appliances...',
              prefixIcon: Icon(Icons.search, color: Colors.blue),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(int onCount, int offCount) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  icon: Icons.power,
                  color: Colors.green,
                  count: onCount,
                  label: 'Active',
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[300],
                ),
                _buildSummaryItem(
                  icon: Icons.power_off,
                  color: Colors.red,
                  count: offCount,
                  label: 'Inactive',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required int count,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplianceGrid(List<dynamic> appliances) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) => ApplianceWidget(appliance: appliances[index]),
          childCount: appliances.length,
        ),
      ),
    );
  }
}