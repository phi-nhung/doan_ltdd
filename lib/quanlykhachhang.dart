import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class QL_KhachHang extends StatefulWidget {
  @override
  State<QL_KhachHang> createState() => _QL_KhachHangState();
}

class _QL_KhachHangState extends State<QL_KhachHang> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  String _selectedFilter = 'Tất cả';
  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  Future<void> _loadCustomers() async {
    final data = await DatabaseHelper.rawQuery('''
      SELECT KH.MAKH, KH.HOTEN, KH.SDT, KH.DIEMTL, MAX(HD.NGAYTAO) AS NGAYTAO
      FROM KHACHHANG KH
      LEFT JOIN HOADON HD ON KH.MAKH = HD.MAKH
      GROUP BY KH.MAKH
    ''');

    setState(() {
      _customers = data;
      _applyFilters();
    });
  }

void _applyFilters() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

  List<Map<String, dynamic>> filtered = List.from(_customers);

  // Áp dụng bộ lọc thời gian
  switch (_selectedFilter) {
    case 'Hôm nay':
      filtered = filtered.where((item) {
        if (item['NGAYTAO'] == null) return false;
        final date = DateTime.tryParse(item['NGAYTAO'])?.toLocal();
        if (date == null) return false;
        final itemDate = DateTime(date.year, date.month, date.day);
        return itemDate == today;
      }).toList();
      break;
    case 'Tuần này':
      filtered = filtered.where((item) {
        if (item['NGAYTAO'] == null) return false;
        final date = DateTime.tryParse(item['NGAYTAO'])?.toLocal();
        if (date == null) return false;
        final itemDate = DateTime(date.year, date.month, date.day);
        return itemDate.isAfter(startOfWeekDate) || itemDate == startOfWeekDate;
      }).toList();
      break;
    default:
      // Không lọc
      break;
  }

       
    // Áp dụng tìm kiếm
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        final name = customer['HOTEN']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredCustomers = filtered;
    });
  }
    void _showAddDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Thêm khách hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Họ tên")),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "SĐT")),
            TextField(controller: addressController, decoration: InputDecoration(labelText: "Địa chỉ")),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper.insert('KHACHHANG', {
                  'HOTEN': nameController.text,
                  'SDT': phoneController.text,
                  'DIACHI': addressController.text,
                  'EMAIL': emailController.text,
                });
                Navigator.pop(context);
                _loadCustomers();
              }
            },
            child: Text("Thêm"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> customer) {
    TextEditingController nameController = TextEditingController(text: customer['HOTEN']);
    TextEditingController phoneController = TextEditingController(text: customer['SDT']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sửa khách hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Họ tên")),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "SĐT")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.update(
                'KHACHHANG',
                customer['MAKH'],
                {
                  'HOTEN': nameController.text,
                  'SDT': phoneController.text,
                },
                idColumn: 'MAKH',
              );
              Navigator.pop(context);
              _loadCustomers();
            },
            child: Text("Cập nhật"),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer(int makh) async {
    await DatabaseHelper.delete('KHACHHANG', makh, idColumn: 'MAKH');
    _loadCustomers();
  }

  void _confirmDeleteCustomer(int makh) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xác nhận xoá'),
        content: Text('Bạn có chắc chắn muốn xoá khách hàng này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Huỷ')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomer(makh);
            },
            child: Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách khách hàng"),
        actions: [
          // Nút lọc thời gian
          DropdownButton<String>(
            value: _selectedFilter,
            items: ['Tất cả', 'Hôm nay', 'Tuần này']
                .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
                _applyFilters();
              });
            },
            underline: SizedBox(),
            icon: Icon(Icons.filter_list, color: Colors.white),
            dropdownColor: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm khách hàng',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                // Màu nền xen kẽ
                final backgroundColor = index % 2 == 0 
                    ? Colors.brown[50] 
                    : Colors.brown[100];
                
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  color: backgroundColor,
                  child: InkWell(
                    onTap: () {
                      // Có thể thêm hành động khi nhấn vào khách hàng
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer['HOTEN'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text("SĐT: ${customer['SDT'] ?? ''}"),
                                Text("Điểm tích lũy: ${customer['DIEMTL'] ?? '0'}"),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.brown[800]),
                                onPressed: () => _showEditDialog(customer),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.brown[800]),
                                onPressed: () => _confirmDeleteCustomer(customer['MAKH']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
      ),
    );
  }
}