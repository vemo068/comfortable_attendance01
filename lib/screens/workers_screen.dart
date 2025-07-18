import 'package:flutter/material.dart';
import 'package:comfortable_attendance/services/storage_service.dart';
import 'package:comfortable_attendance/models/worker.dart';
import 'package:comfortable_attendance/widgets/worker_card.dart';
import 'package:comfortable_attendance/screens/add_edit_worker_screen.dart';

class WorkersScreen extends StatefulWidget {
  final StorageService storageService;

  const WorkersScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  List<Worker> workers = [];
  List<Worker> filteredWorkers = [];
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() => isLoading = true);
    workers = await widget.storageService.getWorkers();
    _filterWorkers();
    setState(() => isLoading = false);
  }

  void _filterWorkers() {
    if (searchQuery.isEmpty) {
      filteredWorkers = List.from(workers);
    } else {
      filteredWorkers = workers
          .where((worker) =>
              worker.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              worker.employeeId.toLowerCase().contains(searchQuery.toLowerCase()) ||
              worker.department.toLowerCase().contains(searchQuery.toLowerCase()) ||
              worker.position.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
  }

  void _showDeleteDialog(Worker worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العامل'),
        content: Text('هل أنت متأكد من حذف ${worker.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await widget.storageService.deleteWorker(worker.id);
              Navigator.pop(context);
              _loadWorkers();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم حذف ${worker.name} بنجاح')),
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العمال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditWorkerScreen(
                  storageService: widget.storageService,
                ),
              ),
            ).then((_) => _loadWorkers()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'البحث عن عامل...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _filterWorkers();
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredWorkers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              workers.isEmpty ? Icons.person_add : Icons.search_off,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              workers.isEmpty ? 'لا يوجد عمال بعد' : 'لا توجد نتائج للبحث',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              workers.isEmpty ? 'اضغط على زر + لإضافة عامل جديد' : 'جرب البحث بكلمات أخرى',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filteredWorkers.length,
                        itemBuilder: (context, index) {
                          final worker = filteredWorkers[index];
                          return WorkerCard(
                            worker: worker,
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditWorkerScreen(
                                  storageService: widget.storageService,
                                  worker: worker,
                                ),
                              ),
                            ).then((_) => _loadWorkers()),
                            onDelete: () => _showDeleteDialog(worker),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}