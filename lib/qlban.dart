import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:doan/screens/order_screen.dart';
import 'package:doan/screens/checkout_screen.dart';
import 'package:provider/provider.dart';
import 'provider/cart_provider.dart';

class QL_Ban extends StatefulWidget {
  const QL_Ban({super.key});
  @override
  State<QL_Ban> createState() => _QL_BanState();
}

class _QL_BanState extends State<QL_Ban> {
  List<Map<String, dynamic>> dsBan = [];
  String selectedTrangThai = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadBan();
  }

  Future<void> _loadBan() async {
    String where = "";
    if (selectedTrangThai != 'Tất cả') {
      where = "WHERE BAN.TRANGTHAI = '$selectedTrangThai'";
    }

    // Lấy ngày hôm nay theo định dạng yyyy-MM-dd
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Lấy tổng tiền từ hóa đơn, thời gian từ trường THOIGIAN của BAN
    final data = await DatabaseHelper.rawQuery("""
       SELECT BAN.*, 
            IFNULL(SUM(CASE WHEN HOADON.NGAYTAO = ? THEN HOADON.TONGTIEN ELSE 0 END), 0) AS TONGTIEN
      FROM BAN
      LEFT JOIN HOADON ON BAN.MABAN = HOADON.MABAN AND HOADON.NGAYTAO = ?
      $where
      GROUP BY BAN.MABAN
      ORDER BY BAN.SOBAN
    """, [today, today]);

    setState(() => dsBan = data);
  }

  void _showAddDialog() {
    TextEditingController soBanCtrl = TextEditingController();
    String trangThai = 'Trống';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Thêm bàn"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: soBanCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Số bàn"),
            ),
            DropdownButton<String>(
              value: trangThai,
              onChanged: (val) => setState(() => trangThai = val!),
              items: ['Trống', 'Đã đặt', 'Có khách']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseHelper.insert('BAN', {
                  'SOBAN': int.parse(soBanCtrl.text),
                  'TRANGTHAI': trangThai,
                  'THOIGIAN': '', // Chưa có thời gian khi thêm mới
                });
                Navigator.pop(context);
                _loadBan();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Số bàn đã tồn tại")));
              }
            },
            child: Text("Thêm"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> ban) {
    TextEditingController soBanCtrl = TextEditingController(text: ban['SOBAN'].toString());
    String trangThai = ban['TRANGTHAI'] ?? 'Trống';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sửa bàn"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: soBanCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Số bàn"),
            ),
            DropdownButton<String>(
              value: trangThai,
              onChanged: (val) => setState(() => trangThai = val!),
              items: ['Trống', 'Đã đặt', 'Có khách']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.update(
                'BAN',
                ban['MABAN'],
                {
                  'SOBAN': int.parse(soBanCtrl.text),
                  'TRANGTHAI': trangThai,
                },
                idColumn: 'MABAN',
              );
              Navigator.pop(context);
              _loadBan();
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _deleteBan(int id) async {
    await DatabaseHelper.delete('BAN', id, idColumn: 'MABAN');
    _loadBan();
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Xác nhận xoá"),
        content: Text("Bạn có chắc muốn xoá bàn này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBan(id);
            },
            child: Text("Xoá"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Trống':
        return Colors.green;
      case 'Đã đặt':
        return Colors.orange;
      case 'Có khách':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 đ';
    return '${amount.toString()} đ';
  }

  // Định dạng thời gian dạng 1h30p, 30p, 2h... từ ISO string
  String formatDurationFromIso(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final start = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(start);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (diff.inMinutes < 1) return '0p';
      if (hours == 0) return '${minutes}p';
      if (minutes == 0) return '${hours}h';
      return '${hours}h${minutes}p';
    } catch (e) {
      return '';
    }
  }

  // Widget đếm thời gian động
  Widget buildTimer(String? thoigian) {
    if (thoigian == null || thoigian.isEmpty) return SizedBox();
    return StreamBuilder<int>(
      stream: Stream.periodic(Duration(seconds: 30), (i) => i),
      builder: (context, snapshot) {
        return Text(
          "Thời gian: ${formatDurationFromIso(thoigian)}",
          style: TextStyle(fontSize: 12, color: Colors.black54),
        );
      },
    );
  }

  bool _isCountingTime(dynamic thoigian) {
    return thoigian != null && thoigian != '';
  }

  // Khi nhấn "Đặt bàn", cập nhật thời gian bắt đầu cho bàn
  Future<void> _onDatBan(Map<String, dynamic> ban) async {
    if (ban['THOIGIAN'] == null || ban['THOIGIAN'] == '') {
      await DatabaseHelper.update(
        'BAN',
        ban['MABAN'],
        {'THOIGIAN': DateTime.now().toIso8601String()},
        idColumn: 'MABAN',
      );
      await _loadBan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý bàn")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedTrangThai,
              onChanged: (value) {
                selectedTrangThai = value!;
                _loadBan();
              },
              items: ['Tất cả', 'Trống', 'Đã đặt', 'Có khách']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
          ),
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  padding: const EdgeInsets.all(8),
                  children: dsBan.map((ban) {
                    final soban = ban['SOBAN'];
                    final isServing = cartProvider.tableItems[soban]?.isNotEmpty == true;
                    final tongTienBan = isServing
                        ? cartProvider.getTableTotalAmount(soban)
                        : ban['TONGTIEN'];
                    final trangThaiBan = isServing ? 'Đang phục vụ' : (ban['TRANGTHAI'] ?? '');
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Bàn $soban", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 10, color: _getStatusColor(trangThaiBan)),
                              SizedBox(width: 4),
                              Text(trangThaiBan, style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              buildTimer(ban['THOIGIAN']),
                              if (_isCountingTime(ban['THOIGIAN']))
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(Icons.timer, color: Colors.green, size: 16),
                                ),
                            ],
                          ),
                          Text(
                            "Tổng tiền: ${_formatCurrency(tongTienBan)}",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () => _showEditDialog(ban),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () => _confirmDelete(ban['MABAN']),
                              ),
                              Flexible(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    textStyle: TextStyle(fontSize: 13),
                                    backgroundColor: const Color.fromARGB(255, 237, 235, 235),
                                    minimumSize: Size(0, 32),
                                  ),
                                  onPressed: () async {
                                    if (trangThaiBan == 'Có khách' || trangThaiBan == 'Đang phục vụ') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CheckoutScreen(
                                            tableNumber: ban['SOBAN'],
                                            onCheckout: () async {
                                              // Reset thời gian về rỗng sau khi thanh toán
                                              await DatabaseHelper.update(
                                                'BAN',
                                                ban['MABAN'],
                                                {'THOIGIAN': ''},
                                                idColumn: 'MABAN',
                                              );
                                              _loadBan();
                                            },
                                          ),
                                        ),
                                      ).then((_) => _loadBan());
                                    } else {
                                      await _onDatBan(ban);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OrderScreen(datban: ban['SOBAN']),
                                        ),
                                      ).then((_) => _loadBan());
                                    }
                                  },
                                  child: Text(
                                    (trangThaiBan == 'Có khách' || trangThaiBan == 'Đang phục vụ')
                                        ? "Thanh toán"
                                        : "Đặt bàn",
                                    style: TextStyle(color: Color.fromARGB(255, 18, 18, 18)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isCountingTime(ban['THOIGIAN']))
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "Đang tính giờ",
                                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
