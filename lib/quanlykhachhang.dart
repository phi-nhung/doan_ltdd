import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class QL_KhachHang extends StatefulWidget {
  @override
  State<QL_KhachHang> createState() => _QL_KhachHangState();
}

class _QL_KhachHangState extends State<QL_KhachHang> {
  List<Map<String, dynamic>> _customers = [];
  String _selectedFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final data = await DatabaseHelper.rawQuery('''
      SELECT KH.MAKH, KH.HOTEN, KH.SDT, KH.DIEMTL, MAX(HD.NGAYTAO) AS NGAYTAO
      FROM KHACHHANG KH
      LEFT JOIN HOADON HD ON KH.MAKH = HD.MAKH
      GROUP BY KH.MAKH
    ''');


    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    List<Map<String, dynamic>> filtered;

    switch (_selectedFilter) {
      case 'Hôm nay':
        filtered = data.where((item) => item['NGAYTAO'] == todayStr).toList();
        break;
      case 'Tuần này':
        filtered = data.where((item) {
          final date = DateTime.tryParse(item['NGAYTAO'] ?? '');
          return date != null && !date.isBefore(startOfWeek);
        }).toList();
        break;
      default:
        filtered = data;
    }

    setState(() {
      _customers = filtered;
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
          DropdownButton<String>(
            value: _selectedFilter,
            items: ['Tất cả', 'Hôm nay', 'Tuần này']
                .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
              _loadCustomers();
            },
            underline: SizedBox(),
            icon: Icon(Icons.filter_list, color: Colors.white),
            dropdownColor: Colors.white,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _customers.length,
        itemBuilder: (context, index) {
          final customer = _customers[index];
          // Màu nền xen kẽ
          final backgroundColor = index % 2 == 0 
              ? Colors.brown[50] // Màu nâu nhạt cho hàng chẵn
              : Colors.brown[100]; // Màu nâu sáng hơn cho hàng lẻ
          
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
      ),
    );
  }
}