import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart'; // Đảm bảo đường dẫn này đúng

class QL_NhanVien extends StatefulWidget {
  const QL_NhanVien({super.key});

  @override
  State<QL_NhanVien> createState() => _QL_NhanVienState();
}

class _QL_NhanVienState extends State<QL_NhanVien> {
  List<Map<String, dynamic>> nhanvien = [];
  TextEditingController searchController = TextEditingController();
  String selectedPosition = "Tất cả";


  @override
  void initState() {
    super.initState();
    _loadNhanVien();
  }

  Future<void> _loadNhanVien({String position = "Tất cả"}) async {
    String sql = '''
      SELECT MANHANVIEN, HOTEN, CHUCVU, SDT
      FROM NHANVIEN
    ''';

    List<Object?> args = [];

    if (position != "Tất cả") {
      sql += " WHERE CHUCVU = ?";
      args.add(position);
    }

    final data = await DatabaseHelper.rawQuery(sql, args);
    setState(() {
      nhanvien = data;
      selectedPosition = position;
    });
  }


  Future<void> _searchNhanVien(String keyword) async {
    final data = await DatabaseHelper.rawQuery('''
      SELECT MANHANVIEN, HOTEN, CHUCVU, SDT
      FROM NHANVIEN
      WHERE HOTEN LIKE ?
    ''', ['%$keyword%']);

    setState(() {
      nhanvien = data;
    });
  }


  void _showAddDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController positionController = TextEditingController();


    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Thêm nhân viên"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Họ tên")),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "SĐT")),
            TextField(controller: positionController, decoration: InputDecoration(labelText: "Chức vụ")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper.insert('NHANVIEN', {
                  'HOTEN': nameController.text,
                  'SDT': phoneController.text,
                  'CHUCVU': positionController.text,
                });
                Navigator.pop(context);
                _loadNhanVien();
              }
            },
            child: Text("Thêm"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> employee) {
    TextEditingController nameController = TextEditingController(text: employee['HOTEN']);
    TextEditingController phoneController = TextEditingController(text: employee['SDT']);
    TextEditingController positionController = TextEditingController(text: employee['CHUCVU']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sửa nhân viên"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Họ tên")),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "SĐT")),
            TextField(controller: positionController, decoration: InputDecoration(labelText: "Chức vụ")),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.update(
                'NHANVIEN',
                employee['MANHANVIEN'],
                {
                  'HOTEN': nameController.text,
                  'SDT': phoneController.text,
                  'CHUCVU': positionController.text,
                },
                idColumn: 'MANHANVIEN',
              );
              Navigator.pop(context);
              _loadNhanVien();
            },
            child: Text("Cập nhật"),
          ),
        ],
      ),
    );
  }

  // Sửa đổi hàm _deleteEmployee để xóa cả trong bảng USER
  void _deleteEmployee(int manv) async {
    try {
      // Bước 1: Xóa tài khoản USER liên quan
      // Tìm USER có MANV tương ứng với MANHANVIEN của nhân viên
      final userResult = await DatabaseHelper.rawQuery(
        'SELECT ID FROM USER WHERE MANV = ?',
        [manv],
      );

      if (userResult.isNotEmpty) {
        int userIdToDelete = userResult.first['ID'];
        await DatabaseHelper.delete('USER', userIdToDelete, idColumn: 'ID');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tài khoản người dùng liên quan.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy tài khoản người dùng liên quan.')),
        );
      }

      // Bước 2: Xóa nhân viên khỏi bảng NHANVIEN
      await DatabaseHelper.delete('NHANVIEN', manv, idColumn: 'MANHANVIEN');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa nhân viên thành công.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa nhân viên: ${e.toString()}')),
      );
    } finally {
      _loadNhanVien(); // Tải lại danh sách nhân viên sau khi xóa
    }
  }

  void _confirmDeleteEmployee(int manv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xác nhận xoá'),
        content: Text('Bạn có chắc chắn muốn xoá nhân viên này không? Thao tác này cũng sẽ xoá tài khoản đăng nhập liên quan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Huỷ')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEmployee(manv);
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
        title: Text("Danh sách nhân viên"),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Color.fromARGB(255, 244, 238, 238),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedPosition,
                      underline: SizedBox(),
                      icon: Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 18, 18, 18)),
                      style: TextStyle(color: Color.fromARGB(255, 18, 18, 18), fontSize: 16),
                      items: ["Tất cả", "Quản lý", "Nhân viên"].map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      )).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          _loadNhanVien(position: newValue);
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 150,
                      height: 40,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          _searchNhanVien(value.trim());
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: Color.fromARGB(255, 18, 18, 18)),
                      onPressed: () {
                        _searchNhanVien(searchController.text.trim());
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: nhanvien.length,
              itemBuilder: (context, index) {
                final emp = nhanvien[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  color: const Color.fromARGB(255, 229, 228, 228) ,
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp['HOTEN'],
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text("Chức vụ: ${emp['CHUCVU'] ?? ''}"),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: const Color.fromARGB(255, 81, 81, 81)),
                                onPressed: () => _showEditDialog(emp),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: const Color.fromARGB(255, 81, 81, 81)),
                                onPressed: () => _confirmDeleteEmployee(emp['MANHANVIEN']),
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
        backgroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }
}
