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
                TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên sản phẩm")),
                TextField(controller: priceController, decoration: InputDecoration(labelText: "Giá bán"), keyboardType: TextInputType.number),
                TextField(controller: unitController, decoration: InputDecoration(labelText: "Đơn vị tính")),
                TextField(controller: quantityController, decoration: InputDecoration(labelText: "Số lượng tồn"), keyboardType: TextInputType.number),
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
                if (nameController.text.isNotEmpty && selectedMaDanhMuc != null) {
                  await DatabaseHelper.insert('SANPHAM', {
                    'TENSANPHAM': nameController.text,
                    'DONVITINH': unitController.text,
                    'GIABAN': double.tryParse(priceController.text) ?? 0,
                    'SOLUONGTON': int.tryParse(quantityController.text) ?? 0,
                    'TRANGTHAI': trangthai,
                    'MADANHMUC': selectedMaDanhMuc,
                    'HINHANH': pickedImage,
                  });
                  Navigator.pop(context);
                  _loadMatHang();
                }
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
                TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên sản phẩm")),
                TextField(controller: priceController, decoration: InputDecoration(labelText: "Giá bán"), keyboardType: TextInputType.number),
                TextField(controller: unitController, decoration: InputDecoration(labelText: "Đơn vị tính")),
                TextField(controller: quantityController, decoration: InputDecoration(labelText: "Số lượng tồn"), keyboardType: TextInputType.number),
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
                await DatabaseHelper.update(
                  'SANPHAM',
                  item['MASANPHAM'],
                  {
                    'TENSANPHAM': nameController.text,
                    'DONVITINH': unitController.text,
                    'GIABAN': double.tryParse(priceController.text) ?? 0,
                    'SOLUONGTON': int.tryParse(quantityController.text) ?? 0,
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
                DropdownButton<String>(
                  value: selectedCategory,
                  underline: SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 18, 18, 18)),
                  style: TextStyle(color: Color.fromARGB(255, 18, 18, 18), fontSize: 16),
                  items: categoryList.map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  )).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      _loadMatHang(category: newValue);
                    }
                  },
                ),
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
                      _searchMatHang(value.trim());
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search, color: Color.fromARGB(255, 18, 18, 18)),
                  onPressed: () {
                    _searchMatHang(searchController.text.trim());
                  },
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
                                Text("SL tồn: ${sp['SOLUONGTON']} | Trạng thái: ${sp['TRANGTHAI']}"),
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