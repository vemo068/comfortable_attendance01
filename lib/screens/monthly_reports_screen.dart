import 'package:flutter/material.dart';
import 'package:comfortable_attendance/services/attendance_service.dart';
import 'package:comfortable_attendance/models/monthly_report.dart';
import 'package:comfortable_attendance/widgets/monthly_summary_card.dart';

class MonthlyReportsScreen extends StatefulWidget {
  final AttendanceService attendanceService;

  const MonthlyReportsScreen({
    super.key,
    required this.attendanceService,
  });

  @override
  State<MonthlyReportsScreen> createState() => _MonthlyReportsScreenState();
}

class _MonthlyReportsScreenState extends State<MonthlyReportsScreen> {
  List<MonthlyReport> reports = [];
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => isLoading = true);
    reports = await widget.attendanceService.generateMonthlyReports(selectedMonth, selectedYear);
    setState(() => isLoading = false);
  }

  Future<void> _selectMonth() async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      builder: (context) => _MonthYearPicker(
        selectedMonth: selectedMonth,
        selectedYear: selectedYear,
      ),
    );
    
    if (result != null) {
      setState(() {
        selectedMonth = result['month']!;
        selectedYear = result['year']!;
      });
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير الشهرية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Month/Year Selection Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: _selectMonth,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${months[selectedMonth - 1]} $selectedYear',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اضغط لتغيير الشهر',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Summary Statistics
          if (reports.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'المتوسط العام',
                    '${(reports.fold(0.0, (sum, report) => sum + report.attendancePercentage) / reports.length).toStringAsFixed(1)}%',
                  ),
                  _buildSummaryItem(
                    'أعلى نسبة',
                    '${reports.map((r) => r.attendancePercentage).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}%',
                  ),
                  _buildSummaryItem(
                    'أقل نسبة',
                    '${reports.map((r) => r.attendancePercentage).reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reports List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assessment,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد تقارير للشهر المحدد',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'تأكد من وجود عمال وحضور مسجل',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return MonthlySummaryCard(
                            report: report,
                            onTap: () => _showReportDetails(report),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  void _showReportDetails(MonthlyReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تفاصيل التقرير',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailRow('الموظف', report.workerName),
                    _buildDetailRow('الشهر', '${report.monthName} ${report.year}'),
                    _buildDetailRow('إجمالي أيام العمل', '${report.totalDays} يوم'),
                    _buildDetailRow('أيام الحضور', '${report.presentDays} يوم'),
                    _buildDetailRow('أيام الغياب', '${report.absentDays} يوم'),
                    _buildDetailRow('أيام التأخير', '${report.lateDays} يوم'),
                    _buildDetailRow('أيام الإعذار', '${report.excusedDays} يوم'),
                    _buildDetailRow('نسبة الحضور', '${report.attendancePercentage.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthYearPicker extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;

  const _MonthYearPicker({
    required this.selectedMonth,
    required this.selectedYear,
  });

  @override
  State<_MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<_MonthYearPicker> {
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.selectedMonth;
    selectedYear = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'اختر الشهر والسنة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'الشهر',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: months.asMap().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key + 1,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedMonth = value!);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: InputDecoration(
                    labelText: 'السنة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - 2 + index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    setState(() => selectedYear = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'month': selectedMonth,
                  'year': selectedYear,
                });
              },
              child: const Text('تطبيق'),
            ),
          ),
        ],
      ),
    );
  }
}