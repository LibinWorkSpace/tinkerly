import 'package:flutter/material.dart';
import 'package:tinkerly/models/user_model.dart';
import 'package:tinkerly/widgets/custom_button.dart';

class AnalyticsScreen extends StatefulWidget {
  final AppUser user;

  const AnalyticsScreen({super.key, required this.user});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'This Year', 'All Time'];

  // Mock analytics data
  final Map<String, AnalyticsData> _analyticsData = {
    'This Week': AnalyticsData(
      totalViews: 1250,
      totalLikes: 89,
      totalShares: 23,
      totalEarnings: 45.50,
      topCategory: 'Digital Art',
      growthRate: 12.5,
      postsCount: 3,
    ),
    'This Month': AnalyticsData(
      totalViews: 5800,
      totalLikes: 456,
      totalShares: 134,
      totalEarnings: 234.75,
      topCategory: 'UI/UX',
      growthRate: 8.3,
      postsCount: 12,
    ),
    'This Year': AnalyticsData(
      totalViews: 45600,
      totalLikes: 3200,
      totalShares: 890,
      totalEarnings: 1890.50,
      topCategory: 'Photography',
      growthRate: 15.7,
      postsCount: 89,
    ),
    'All Time': AnalyticsData(
      totalViews: 125000,
      totalLikes: 8900,
      totalShares: 2300,
      totalEarnings: 5678.90,
      topCategory: 'Digital Art',
      growthRate: 22.1,
      postsCount: 234,
    ),
  };

  AnalyticsData get _currentData => _analyticsData[_selectedPeriod]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share analytics
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Period Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Performance Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: _periods.map((period) {
                      bool isSelected = _selectedPeriod == period;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPeriod = period;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              period,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Key Metrics Cards
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Top Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Views',
                          '${_currentData.totalViews}',
                          Icons.visibility,
                          const Color(0xFF2196F3),
                          _currentData.growthRate > 0 ? '+' : '',
                          _currentData.growthRate,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Total Likes',
                          '${_currentData.totalLikes}',
                          Icons.favorite,
                          const Color(0xFFE91E63),
                          _currentData.growthRate > 0 ? '+' : '',
                          _currentData.growthRate,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bottom Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Shares',
                          '${_currentData.totalShares}',
                          Icons.share,
                          const Color(0xFF4CAF50),
                          _currentData.growthRate > 0 ? '+' : '',
                          _currentData.growthRate,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Total Earnings',
                          '\$${_currentData.totalEarnings.toStringAsFixed(2)}',
                          Icons.account_balance_wallet,
                          const Color(0xFFFF9800),
                          _currentData.growthRate > 0 ? '+' : '',
                          _currentData.growthRate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Performance Chart
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 48,
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chart will be implemented',
                            style: TextStyle(
                              color: const Color(0xFF6C7B7F),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Insights Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInsightTile(
                    Icons.star,
                    'Top Performing Category',
                    _currentData.topCategory,
                    'Your ${_currentData.topCategory} content is generating the most engagement',
                  ),
                  _buildInsightTile(
                    Icons.trending_up,
                    'Growth Rate',
                    '${_currentData.growthRate}%',
                    'Your performance has improved by ${_currentData.growthRate}% this period',
                  ),
                  _buildInsightTile(
                    Icons.article,
                    'Content Published',
                    '${_currentData.postsCount} posts',
                    'You\'ve published ${_currentData.postsCount} posts this period',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Category Performance
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.user.categories.map((category) => _buildCategoryPerformanceTile(category)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child:                   Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Export Report',
                          onPressed: () {
                            // Export analytics report
                          },
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Share Insights',
                          onPressed: () {
                            // Share insights
                          },
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String prefix,
    double growthRate,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6C7B7F),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                growthRate > 0 ? Icons.trending_up : Icons.trending_down,
                size: 12,
                color: growthRate > 0 ? const Color(0xFF4CAF50) : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                '$prefix${growthRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: growthRate > 0 ? const Color(0xFF4CAF50) : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTile(IconData icon, String title, String value, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C7B7F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceTile(String category) {
    // Mock performance data for each category
    final performanceData = {
      'Digital Art': {'views': 2500, 'likes': 180, 'earnings': 89.50},
      'UI/UX': {'views': 1800, 'likes': 120, 'earnings': 67.25},
      'Photography': {'views': 1200, 'likes': 95, 'earnings': 45.80},
      'Animation': {'views': 800, 'likes': 65, 'earnings': 32.20},
      'Music': {'views': 600, 'likes': 45, 'earnings': 28.90},
      'Programming': {'views': 400, 'likes': 30, 'earnings': 22.15},
      'Writing': {'views': 300, 'likes': 25, 'earnings': 18.75},
      '3D Design': {'views': 200, 'likes': 15, 'earnings': 12.50},
    };

    final data = performanceData[category] ?? {'views': 0, 'likes': 0, 'earnings': 0.0};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Views',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6C7B7F),
                  ),
                ),
                Text(
                  '${data['views']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Likes',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6C7B7F),
                  ),
                ),
                Text(
                  '${data['likes']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Earnings',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6C7B7F),
                  ),
                ),
                Text(
                  '\$${data['earnings']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsData {
  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final double totalEarnings;
  final String topCategory;
  final double growthRate;
  final int postsCount;

  AnalyticsData({
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.totalEarnings,
    required this.topCategory,
    required this.growthRate,
    required this.postsCount,
  });
} 