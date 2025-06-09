import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class QL_MatHang extends StatefulWidget {
  const QL_MatHang({super.key});

  @override
  State<QL_MatHang> createState() => _QL_MatHangState();
}

class _QL_MatHangState extends State<QL_MatHang> {
  List<Map<String, dynamic>> mathang = [];
  List<Map<String, dynamic>> danhmuc = [];
  TextEditingController searchController = TextEditingController();
  String selectedCategory = "Tất cả";
  Uint8List? pickedImage; // Biến dùng cho dialog thêm/sửa

  @override
  void initState() {
    super.initState();
    _loadDanhMuc();
    _loadMatHang();
  }

  Future<void> _loadDanhMuc() async {
    final data = await DatabaseHelper.rawQuery('SELECT * FROM DANHMUC');
    setState(() {
      danhmuc = data;
    });
  }

  Future<void> _loadMatHang({String category = "Tất cả"}) async {
    String sql = '''
      SELECT sp.MASANPHAM, sp.TENSANPHAM, sp.DONVITINH, sp.GIABAN, sp.SOLUONGTON, sp.TRANGTHAI, sp.HINHANH, dm.TENDANHMUC
      FROM SANPHAM sp
      LEFT JOIN DANHMUC dm ON sp.MADANHMUC = dm.MADANHMUC
    ''';
    List<Object?> args = [];
    if (category != "Tất cả") {
      sql += " WHERE dm.TENDANHMUC = ?";
      args.add(category);
    }
    final data = await DatabaseHelper.rawQuery(sql, args);
    setState(() {
      mathang = data;
      selectedCategory = category;
    });
  }

  Future<void> _searchMatHang(String keyword) async {
    final data = await DatabaseHelper.rawQuery('''
      SELECT sp.MASANPHAM, sp.TENSANPHAM, sp.DONVITINH, sp.GIABAN, sp.SOLUONGTON, sp.TRANGTHAI, sp.HINHANH, dm.TENDANHMUC
      FROM SANPHAM sp
      LEFT JOIN DANHMUC dm ON sp.MADANHMUC = dm.MADANHMUC
      WHERE sp.TENSANPHAM LIKE ?
    ''', ['%$keyword%']);
    setState(() {
      mathang = data;
    });
  }

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.photos.request().isGranted) return true;
      if (await Permission.storage.request().isGranted) return true;
      if (await Permission.mediaLibrary.request().isGranted) return true;
      return false;
    }
    if (Platform.isIOS) {
      if (await Permission.photos.request().isGranted) return true;
      return false;
    }
    return false;
  }

  void _showAddDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController unitController = TextEditingController();
    TextEditingController quantityController = TextEditingController();
    String trangthai = "còn hàng";
    int? selectedMaDanhMuc = danhmuc.isNotEmpty ? danhmuc[0]['MADANHMUC'] : null;
    pickedImage = null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Thêm sản phẩm"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Tên sản phẩm",
                    errorText: nameController.text.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                  ),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: "Giá bán",
                    errorText: priceController.text.isEmpty ? 'Vui lòng nhập giá bán' : null,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    if (value.startsWith('-')) {
                      priceController.text = value.replaceFirst('-', '');
                      priceController.selection = TextSelection.fromPosition(
                        TextPosition(offset: priceController.text.length),
                      );
                    }
                    // Chỉ cho phép nhập số và dấu chấm
                    if (value.isNotEmpty) {
                      final regex = RegExp(r'^\d*\.?\d*$');
                      if (!regex.hasMatch(value)) {
                        priceController.text = value.replaceAll(RegExp(r'[^\d.]'), '');
                        priceController.selection = TextSelection.fromPosition(
                          TextPosition(offset: priceController.text.length),
                        );
                      }
                    }
                  },
                ),
                TextField(
                  controller: unitController,
                  decoration: InputDecoration(
                    labelText: "Đơn vị tính",
                    errorText: unitController.text.isEmpty ? 'Vui lòng nhập đơn vị tính' : null,
                  ),
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: "Số lượng tồn",
                    //errorText: quantityController.text.isEmpty ? 'Vui lòng nhập số lượng' : null,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.startsWith('-')) {
                      quantityController.text = value.replaceFirst('-', '');
                      quantityController.selection = TextSelection.fromPosition(
                        TextPosition(offset: quantityController.text.length),
                      );
                    }
                    // Chỉ cho phép nhập số nguyên
                    if (value.isNotEmpty) {
                      final regex = RegExp(r'^\d*$');
                      if (!regex.hasMatch(value)) {
                        quantityController.text = value.replaceAll(RegExp(r'[^\d]'), '');
                        quantityController.selection = TextSelection.fromPosition(
                          TextPosition(offset: quantityController.text.length),
                        );
                      }
                    }
                  },
                ),
                DropdownButtonFormField<int>(
                  value: selectedMaDanhMuc,
                  items: danhmuc.map((dm) => DropdownMenuItem<int>(
                    value: dm['MADANHMUC'],
                    child: Text(dm['TENDANHMUC']),
                  )).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedMaDanhMuc = value;
                    });
                  },
                  decoration: InputDecoration(labelText: "Danh mục"),
                ),
                DropdownButtonFormField<String>(
                  value: trangthai,
                  items: ["còn hàng", "hết hàng"].map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  )).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      trangthai = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: "Trạng thái"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (await _requestGalleryPermission()) {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        final bytes = await pickedFile.readAsBytes();
                        setStateDialog(() {
                          pickedImage = bytes;
                        });
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bạn cần cấp quyền truy cập ảnh!')),
                      );
                    }
                  },
                  child: Text("Chọn hình ảnh"),
                ),
                if (pickedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.memory(pickedImage!, width: 80, height: 80),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập tên sản phẩm')),
                  );
                  return;
                }
                if (priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập giá bán')),
                  );
                  return;
                }
                if (unitController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập đơn vị tính')),
                  );
                  return;
                }
                // if (quantityController.text.isEmpty) {
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(content: Text('Vui lòng nhập số lượng')),
                //   );
                //   return;
                // }
                if (selectedMaDanhMuc == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng chọn danh mục')),
                  );
                  return;
                }

                final price = double.tryParse(priceController.text) ?? 0;
                final quantity = int.tryParse(quantityController.text) ?? 0;
                
                if (price <= 0 || quantity < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Giá bán phải lớn hơn 0 và số lượng không được âm!')),
                  );
                  return;
                }

                await DatabaseHelper.insert('SANPHAM', {
                  'TENSANPHAM': nameController.text,
                  'DONVITINH': unitController.text,
                  'GIABAN': price,
                  'SOLUONGTON': quantity,
                  'TRANGTHAI': trangthai,
                  'MADANHMUC': selectedMaDanhMuc,
                  'HINHANH': pickedImage,
                });
                Navigator.pop(context);
                _loadMatHang();
              },
              child: Text("Thêm"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    TextEditingController nameController = TextEditingController(text: item['TENSANPHAM']);
    TextEditingController priceController = TextEditingController(text: item['GIABAN'].toString());
    TextEditingController unitController = TextEditingController(text: item['DONVITINH']);
    TextEditingController quantityController = TextEditingController(text: item['SOLUONGTON'].toString());
    String trangthai = item['TRANGTHAI'] ?? "còn hàng";
    int? selectedMaDanhMuc = danhmuc.firstWhere((dm) => dm['TENDANHMUC'] == item['TENDANHMUC'], orElse: () => danhmuc[0])['MADANHMUC'];
    pickedImage = item['HINHANH'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Sửa sản phẩm"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Tên sản phẩm",
                    errorText: nameController.text.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                  ),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: "Giá bán",
                    errorText: priceController.text.isEmpty ? 'Vui lòng nhập giá bán' : null,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    if (value.startsWith('-')) {
                      priceController.text = value.replaceFirst('-', '');
                      priceController.selection = TextSelection.fromPosition(
                        TextPosition(offset: priceController.text.length),
                      );
                    }
                    // Chỉ cho phép nhập số và dấu chấm
                    if (value.isNotEmpty) {
                      final regex = RegExp(r'^\d*\.?\d*$');
                      if (!regex.hasMatch(value)) {
                        priceController.text = value.replaceAll(RegExp(r'[^\d.]'), '');
                        priceController.selection = TextSelection.fromPosition(
                          TextPosition(offset: priceController.text.length),
                        );
                      }
                    }
                  },
                ),
                TextField(
                  controller: unitController,
                  decoration: InputDecoration(
                    labelText: "Đơn vị tính",
                    errorText: unitController.text.isEmpty ? 'Vui lòng nhập đơn vị tính' : null,
                  ),
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: "Số lượng tồn",
                    //errorText: quantityController.text.isEmpty ? 'Vui lòng nhập số lượng' : null,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.startsWith('-')) {
                      quantityController.text = value.replaceFirst('-', '');
                      quantityController.selection = TextSelection.fromPosition(
                        TextPosition(offset: quantityController.text.length),
                      );
                    }
                    // Chỉ cho phép nhập số nguyên
                    if (value.isNotEmpty) {
                      final regex = RegExp(r'^\d*$');
                      if (!regex.hasMatch(value)) {
                        quantityController.text = value.replaceAll(RegExp(r'[^\d]'), '');
                        quantityController.selection = TextSelection.fromPosition(
                          TextPosition(offset: quantityController.text.length),
                        );
                      }
                    }
                  },
                ),
                DropdownButtonFormField<int>(
                  value: selectedMaDanhMuc,
                  items: danhmuc.map((dm) => DropdownMenuItem<int>(
                    value: dm['MADANHMUC'],
                    child: Text(dm['TENDANHMUC']),
                  )).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedMaDanhMuc = value;
                    });
                  },
                  decoration: InputDecoration(labelText: "Danh mục"),
                ),
                DropdownButtonFormField<String>(
                  value: trangthai,
                  items: ["còn hàng", "hết hàng"].map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  )).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      trangthai = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: "Trạng thái"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (await _requestGalleryPermission()) {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        final bytes = await pickedFile.readAsBytes();
                        setStateDialog(() {
                          pickedImage = bytes;
                        });
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bạn cần cấp quyền truy cập ảnh!')),
                      );
                    }
                  },
                  child: Text("Chọn hình ảnh"),
                ),
                if (pickedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.memory(pickedImage!, width: 80, height: 80),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập tên sản phẩm')),
                  );
                  return;
                }
                if (priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập giá bán')),
                  );
                  return;
                }
                if (unitController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập đơn vị tính')),
                  );
                  return;
                }
                // if (quantityController.text.isEmpty) {
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(content: Text('Vui lòng nhập số lượng')),
                //   );
                //   return;
                // }

                final price = double.tryParse(priceController.text) ?? 0;
                final quantity = int.tryParse(quantityController.text) ?? null;
                
                if (price <= 0 ) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Giá bán phải lớn hơn 0 và số lượng không được âm!')),
                  );
                  return;
                }

                await DatabaseHelper.update(
                  'SANPHAM',
                  item['MASANPHAM'],
                  {
                    'TENSANPHAM': nameController.text,
                    'DONVITINH': unitController.text,
                    'GIABAN': price,
                    'SOLUONGTON': quantity,
                    'TRANGTHAI': trangthai,
                    'MADANHMUC': selectedMaDanhMuc,
                    'HINHANH': pickedImage,
                  },
                  idColumn: 'MASANPHAM',
                );
                Navigator.pop(context);
                _loadMatHang();
              },
              child: Text("Cập nhật"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMatHang(int masp) async {
    await DatabaseHelper.delete('SANPHAM', masp, idColumn: 'MASANPHAM');
    _loadMatHang();
  }

  void _confirmDeleteMatHang(int masp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xác nhận xoá'),
        content: Text('Bạn có chắc chắn muốn xoá sản phẩm này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Huỷ')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMatHang(masp);
            },
            child: Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    TextEditingController categoryController = TextEditingController();
    TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Thêm danh mục mới"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: "Tên danh mục"),
            ),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: "Mô tả"),
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
              if (categoryController.text.isNotEmpty) {
                await DatabaseHelper.insert('DANHMUC', {
                  'TENDANHMUC': categoryController.text,
                  'MOTA': descController.text,
                });
                Navigator.pop(context);
                _loadDanhMuc(); // Tải lại danh sách danh mục
              }
            },
            child: Text("Thêm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> categoryList = ["Tất cả", ...danhmuc.map((dm) => dm['TENDANHMUC'] as String)];
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý mặt hàng"),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Color.fromARGB(255, 244, 238, 238),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Phần dropdown và nút thêm danh mục
                Flexible(
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          underline: SizedBox(),
                          icon: Icon(Icons.arrow_drop_down, 
                            color: Color.fromARGB(255, 18, 18, 18)),
                          style: TextStyle(
                            color: Color.fromARGB(255, 18, 18, 18), 
                            fontSize: 16
                          ),
                          items: categoryList.map((String value) => 
                            DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              _loadMatHang(category: newValue);
                            }
                          },
                        ),
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
                ),

                // Phần tìm kiếm
                Flexible(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
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
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (value) => _searchMatHang(value.trim()),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search, 
                          color: Color.fromARGB(255, 18, 18, 18)),
                        onPressed: () => _searchMatHang(searchController.text.trim()),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: mathang.length,
              itemBuilder: (context, index) {
                final sp = mathang[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  color: const Color.fromARGB(255, 229, 228, 228),
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Hiển thị hình ảnh sản phẩm
                          (sp['HINHANH'] != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    sp['HINHANH'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.image, size: 32, color: Colors.grey[600]),
                                ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sp['TENSANPHAM'] ?? '',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text("Giá: ${sp['GIABAN']} | ĐVT: ${sp['DONVITINH']}"),
                                Text(
                                    "SL tồn: ${sp['SOLUONGTON'] == null ? '' : sp['SOLUONGTON']} | Trạng thái: ${sp['TRANGTHAI']}"
                                  ),
                                Text("Danh mục: ${sp['TENDANHMUC'] ?? ''}"),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: const Color.fromARGB(255, 81, 81, 81)),
                                onPressed: () => _showEditDialog(sp),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: const Color.fromARGB(255, 81, 81, 81)),
                                onPressed: () => _confirmDeleteMatHang(sp['MASANPHAM']),
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