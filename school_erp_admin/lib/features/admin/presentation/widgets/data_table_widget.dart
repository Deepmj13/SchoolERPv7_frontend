import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';

class ColumnDefinition<T> {
  final String header;
  final String? tooltip;
  final double? width;
  final String Function(T item) displayValue;
  final Widget Function(T item)? displayWidget;
  final bool sortable;
  final int Function(T a, T b)? sortComparator;

  ColumnDefinition({
    required this.header,
    this.tooltip,
    this.width,
    required this.displayValue,
    this.displayWidget,
    this.sortable = false,
    this.sortComparator,
  });
}

class DataTableWidget<T> extends StatefulWidget {
  final List<T> items;
  final List<ColumnDefinition<T>> columns;
  final Widget Function(T item)? actionsBuilder;
  final String? searchHint;
  final bool loading;
  final String emptyMessage;
  final int? rowsPerPage;

  const DataTableWidget({
    super.key,
    required this.items,
    required this.columns,
    this.actionsBuilder,
    this.searchHint,
    this.loading = false,
    this.emptyMessage = 'No data found',
    this.rowsPerPage,
  });

  @override
  State<DataTableWidget<T>> createState() => _DataTableWidgetState<T>();
}

class _DataTableWidgetState<T> extends State<DataTableWidget<T>> {
  String _searchQuery = '';
  int _sortColumnIndex = -1;
  bool _sortAscending = true;
  int _currentPage = 0;

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items.where((item) {
      return widget.columns.any((col) {
        return col
            .displayValue(item)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      });
    }).toList();
  }

  List<T> get _sortedItems {
    if (_sortColumnIndex < 0 || _sortColumnIndex >= widget.columns.length) {
      return _filteredItems;
    }
    final col = widget.columns[_sortColumnIndex];
    final sorted = List<T>.from(_filteredItems)
      ..sort((a, b) {
        final result = col.sortComparator != null
            ? col.sortComparator!(a, b)
            : col.displayValue(a).compareTo(col.displayValue(b));
        return _sortAscending ? result : -result;
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final items = _sortedItems;
    final rpp = widget.rowsPerPage ?? 10;

    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (widget.searchHint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _currentPage = 0;
              }),
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    widget.emptyMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      sortColumnIndex:
                          _sortColumnIndex >= 0 ? _sortColumnIndex : null,
                      sortAscending: _sortAscending,
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.primary.withValues(alpha: 0.05),
                      ),
                      headingRowHeight: 48,
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 56,
                      columnSpacing: 24,
                      horizontalMargin: 16,
                      columns: [
                        ...widget.columns.asMap().entries.map((entry) {
                          return DataColumn(
                            label: Text(
                              entry.value.header,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            tooltip: entry.value.tooltip,
                            onSort: entry.value.sortable
                                ? (colIndex, ascending) {
                                    setState(() {
                                      _sortColumnIndex = colIndex;
                                      _sortAscending = ascending;
                                    });
                                  }
                                : null,
                          );
                        }),
                        if (widget.actionsBuilder != null)
                          const DataColumn(label: Text('')),
                      ],
                      rows: items
                          .skip(_currentPage * rpp)
                          .take(rpp)
                          .map((item) => DataRow(
                                cells: [
                                  ...widget.columns.map((col) {
                                    if (col.displayWidget != null) {
                                      return DataCell(col.displayWidget!(item));
                                    }
                                    return DataCell(
                                      Text(
                                        col.displayValue(item),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }),
                                  if (widget.actionsBuilder != null)
                                    DataCell(widget.actionsBuilder!(item)),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                ),
        ),
        if (items.length > rpp)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text(
                  '${_currentPage + 1} of ${(items.length / rpp).ceil()}',
                  style: const TextStyle(fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: (_currentPage + 1) * rpp < items.length
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
