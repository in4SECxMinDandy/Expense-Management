import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ios_card.dart';
import '../../models/ai_insight.dart';
import '../../providers/ai_insight_provider.dart';
import 'package:intl/intl.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIInsightProvider>().runAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('AI Phân tích'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AIInsightProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<AIInsightProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang phân tích dữ liệu...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () => provider.refresh(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  if (provider.analysis != null)
                    _buildSummaryCard(provider.analysis!, isDark),
                  const SizedBox(height: AppTheme.spaceL),

                  // Insights Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phân tích & Lời khuyên',
                        style: AppTheme.headingS.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (provider.unreadCount > 0)
                        TextButton(
                          onPressed: () => provider.markAllAsRead(),
                          child: Text(
                            'Đọc tất cả (${provider.unreadCount})',
                            style: TextStyle(color: AppTheme.primaryPurple),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),

                  // Insights List
                  if (provider.insights.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ...provider.insights.asMap().entries.map((entry) {
                      return _buildInsightCard(
                        entry.value,
                        entry.key,
                        provider,
                        isDark,
                      );
                    }),

                  // Last analyzed
                  if (provider.lastAnalyzed != null) ...[
                    const SizedBox(height: AppTheme.spaceL),
                    Center(
                      child: Text(
                        'Cập nhật lúc: ${DateFormat('HH:mm dd/MM/yyyy').format(provider.lastAnalyzed!)}',
                        style: AppTheme.bodyS.copyWith(color: Colors.grey),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceXL),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(SpendingAnalysis analysis, bool isDark) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Determine status color
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (analysis.savingsRate < 0) {
      statusColor = Colors.red;
      statusText = 'Cần cải thiện';
      statusIcon = Icons.warning_rounded;
    } else if (analysis.savingsRate < 10) {
      statusColor = Colors.orange;
      statusText = 'Chú ý';
      statusIcon = Icons.info_rounded;
    } else if (analysis.savingsRate >= 30) {
      statusColor = Colors.green;
      statusText = 'Tuyệt vời';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = Colors.blue;
      statusText = 'Ổn định';
      statusIcon = Icons.trending_flat_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple,
            AppTheme.primaryPurple.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),

          // Main Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Thu nhập',
                  currencyFormat.format(analysis.totalIncome),
                  Colors.white,
                  Icons.arrow_upward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  'Chi tiêu',
                  currencyFormat.format(analysis.totalExpense),
                  Colors.white,
                  Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),

          // Savings Rate Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tỷ lệ tiết kiệm',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '${analysis.savingsRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (analysis.savingsRate.clamp(0, 100) / 100),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),

          // Additional Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                'Chi TB/ngày',
                currencyFormat.format(analysis.avgDailySpending),
              ),
              _buildMiniStat(
                'Số dư',
                currencyFormat.format(analysis.balance),
              ),
              _buildMiniStat(
                'So với kỳ trước',
                '${analysis.spendingChange >= 0 ? '+' : ''}${analysis.spendingChange.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    AIInsight insight,
    int index,
    AIInsightProvider provider,
    bool isDark,
  ) {
    final priorityColor = Color(
      int.parse(insight.priorityColor.replaceFirst('#', '0xFF')),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: Dismissible(
        key: Key('insight_$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => provider.dismissInsight(index),
        child: IOSCard(
          onTap: () {
            provider.markAsRead(index);
            _showInsightDetail(insight, isDark);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    insight.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            insight.title,
                            style: AppTheme.bodyL.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        if (!insight.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.message,
                      style: AppTheme.bodyS.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (insight.actionText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        insight.actionText!,
                        style: TextStyle(
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            'Chưa có phân tích',
            style: AppTheme.bodyL.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Thêm giao dịch để AI có thể phân tích',
            style: AppTheme.bodyS.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showInsightDetail(AIInsight insight, bool isDark) {
    final priorityColor = Color(
      int.parse(insight.priorityColor.replaceFirst('#', '0xFF')),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXL),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),

            // Icon and Title
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      insight.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: AppTheme.headingS.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getPriorityText(insight.priority),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceL),

            // Message
            Text(
              insight.message,
              style: AppTheme.bodyM.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),

            // Action Button
            if (insight.actionText != null)
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate if route is specified
                    if (insight.actionRoute != null) {
                      Navigator.pushNamed(context, insight.actionRoute!);
                    }
                  },
                  child: Text(insight.actionText!),
                ),
              ),
            const SizedBox(height: AppTheme.spaceM),
          ],
        ),
      ),
    );
  }

  String _getPriorityText(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.low:
        return 'Thông tin';
      case InsightPriority.medium:
        return 'Lưu ý';
      case InsightPriority.high:
        return 'Quan trọng';
      case InsightPriority.critical:
        return 'Khẩn cấp';
    }
  }
}
