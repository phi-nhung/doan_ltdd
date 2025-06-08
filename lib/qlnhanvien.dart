  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:flutter/services.dart'; 
  import 'database_helper.dart'; 

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
      _loadChucVu();
    }

    Future<void> _loadNhanVien({int? position}) async {
      String sql = '''
        SELECT NV.MANHANVIEN, NV.HOTEN, NV.MACV, NV.SDT, CV.TENCV
        FROM NHANVIEN NV
        LEFT JOIN CHUCVU CV ON NV.MACV = CV.MACV
      ''';

      List<Object?> args = [];

      if (position != null && position != -1) {
        sql += " WHERE NV.MACV = ?";
        args.add(position);
      }

      final data = await DatabaseHelper.rawQuery(sql, args);
      setState(() {
        nhanvien = data;
        selectedPosition = position?.toString() ?? "Tất cả";
      });
    }

    List<Map<String, dynamic>> chucvuList = [];

    Future<void> _loadChucVu() async {
      final data = await DatabaseHelper.rawQuery('SELECT MACV, TENCV FROM CHUCVU');
      setState(() {
        chucvuList = data;
      });
    }

    Future<void> _searchNhanVien(String keyword) async {
      final data = await DatabaseHelper.rawQuery('''
        SELECT NV.MANHANVIEN, NV.HOTEN, NV.MACV, NV.SDT, CV.TENCV
        FROM NHANVIEN NV
        LEFT JOIN CHUCVU CV ON NV.MACV = CV.MACV
        WHERE NV.HOTEN LIKE ?
      ''', ['%$keyword%']);

      setState(() {
        nhanvien = data;
      });
    }

    Future<void> updateChucVu(int id, int newMaCV) async {
      final db = await DatabaseHelper.database;
      await db.update(
        'NHANVIEN',
        {'MACV': newMaCV},
        where: 'MANHANVIEN = ?',
        whereArgs: [id],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật chức vụ thành công')),
      );
    }

    void _showAddDialog() {
      TextEditingController nameController = TextEditingController();
      TextEditingController phoneController = TextEditingController();
      int? selectedMaCV;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Thêm nhân viên"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Họ tên")),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: "SĐT"),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              DropdownButtonFormField<int>(
                value: selectedMaCV,
                items: chucvuList.map((cv) => DropdownMenuItem<int>(
                  value: cv['MACV'],
                  child: Text(cv['TENCV']),
                )).toList(),
                onChanged: (value) {
                  selectedMaCV = value;
                },
                decoration: InputDecoration(labelText: "Chức vụ"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập họ tên')),
                  );
                  return;
                }
                if (phoneController.text.length != 10 || !phoneController.text.startsWith('0')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Số điện thoại không hợp lệ')),
                  );
                  return;
                }
                if (selectedMaCV == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng chọn chức vụ')),
                  );
                  return;
                }
                await DatabaseHelper.insert('NHANVIEN', {
                  'HOTEN': nameController.text,
                  'SDT': phoneController.text,
                  'MACV': selectedMaCV,
                });
                Navigator.pop(context);
                _loadNhanVien();
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
      int? selectedMaCV = employee['MACV'];

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Sửa thông tin nhân viên"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Họ tên")),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: "SĐT"),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              DropdownButtonFormField<int>(
                value: selectedMaCV,
                items: chucvuList.map((cv) => DropdownMenuItem<int>(
                  value: cv['MACV'],
                  child: Text(cv['TENCV']),
                )).toList(),
                onChanged: (value) {
                  selectedMaCV = value;
                },
                decoration: InputDecoration(labelText: "Chức vụ"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.update(
                  'NHANVIEN',
                  employee['MANHANVIEN'],
                  {
                    'HOTEN': nameController.text,
                    'SDT': phoneController.text,
                    'MACV': selectedMaCV,
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
        // Tìm USER có MANV tương ứng với MANHANVIEN của nhân viên
        final userResult = await DatabaseHelper.rawQuery(
          'SELECT USERNAME FROM USER WHERE MANV = ?',
          [manv],
        );

        if (userResult.isNotEmpty) {
          String usernameToDelete = userResult.first['USERNAME'];
          await DatabaseHelper.delete('USER', usernameToDelete, idColumn: 'USERNAME');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tài khoản người dùng liên quan.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy tài khoản người dùng liên quan.')),
          );
        }

        // Xóa nhân viên khỏi bảng NHANVIEN
        await DatabaseHelper.delete('NHANVIEN', manv, idColumn: 'MANHANVIEN');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa nhân viên thành công.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa nhân viên: ${e.toString()}')),
        );
      } finally {
        _loadNhanVien();
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

    void _showAddCategoryDialog() {
      TextEditingController tenchucvuController = TextEditingController();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Thêm chức vụ"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tenchucvuController,
                decoration: InputDecoration(labelText: "Tên chức vụ"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Huỷ"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tenchucvuController.text.isNotEmpty) {
                  await DatabaseHelper.insert('CHUCVU', {
                    'TENCV': tenchucvuController.text,
                  });
                  Navigator.pop(context);
                  await _loadChucVu(); // Tải lại danh sách chức vụ
                  _loadNhanVien(); // Tải lại danh sách nhân viên
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thêm chức vụ thành công')),
                  );
                }
              },
              child: Text("Thêm"),
            ),
          ],
        ),
      );
    }

    void _showEditChucVuDialog(Map<String, dynamic> chucvu) {
      TextEditingController tenCVController = TextEditingController(text: chucvu['TENCV']);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Sửa tên chức vụ"),
          content: TextField(
            controller: tenCVController,
            decoration: InputDecoration(labelText: "Tên chức vụ"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Huỷ"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tenCVController.text.isNotEmpty) {
                  await DatabaseHelper.update(
                    'CHUCVU',
                    chucvu['MACV'],
                    {'TENCV': tenCVController.text},
                    idColumn: 'MACV',
                  );
                  Navigator.pop(context);
                  _loadChucVu();
                  _loadNhanVien();
                }
              },
              child: Text("Lưu"),
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
                      PopupMenuButton<int>(
                        child: Row(
                          children: [
                            Text(
                              selectedPosition == "Tất cả"
                                  ? "Tất cả"
                                  : (chucvuList.firstWhere(
                                          (cv) => cv['MACV'].toString() == selectedPosition,
                                          orElse: () => {'TENCV': 'Không rõ'})['TENCV']),
                              style: TextStyle(
                                  color: Color.fromARGB(255, 18, 18, 18), fontSize: 16),
                            ),
                            Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 18, 18, 18)),
                          ],
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem<int>(
                            value: -1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Tất cả"),
                              ],
                            ),
                          ),
                          ...chucvuList.map((cv) => PopupMenuItem<int>(
                                value: cv['MACV'],
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(cv['TENCV']),
                                    IconButton(
                                      icon: Icon(Icons.edit, size: 18),
                                      onPressed: () {
                                        Navigator.pop(context); // Đóng menu trước
                                        _showEditChucVuDialog(cv);
                                      },
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        onSelected: (newValue) {
                          _loadNhanVien(position: newValue == -1 ? null : newValue);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline,
                            color: Color.fromARGB(255, 18, 18, 18)),
                        onPressed: () => _showAddCategoryDialog(),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
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
                                  Text("Chức vụ: ${emp['TENCV'] ?? ''}"),
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
