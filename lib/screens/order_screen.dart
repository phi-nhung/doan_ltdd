import 'dart:typed_data';
  import 'package:doan/model/cart_item.dart';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:badges/badges.dart' as badges;
  import '../database_helper.dart';
  import '../provider/cart_provider.dart';
  import '../provider/account_provider.dart';
  import '../model/table.dart';
  import '../model/item.dart';
  import '../provider/cart_provider.dart';
  import 'cart_screen.dart';
  import 'checkout_screen.dart';
  import 'package:intl/intl.dart';
  import '../invoice_exporter.dart';

  class OrderScreen extends StatefulWidget {
    final int? datban;
    const OrderScreen({super.key, this.datban});
    @override
    _OrderScreenState createState() => _OrderScreenState();
  }

  class _OrderScreenState extends State<OrderScreen> {
    String _orderType = 'Mang đi';
    int? _selectedTable;
    String _selectedCategory = 'Tất cả';
    String _searchQuery = '';
    final Map<int, String> _tableStatus = {
      for (int i = 1; i <= 10; i++) i: 'Trống',
    };
    bool _isLoading = false;
    String? _error;
    Future<List<TableModel>>? _tablesFuture;

    Future<void> updateTableStatus(int soban, String status) async {
      try {
        /* await DatabaseHelper.rawUpdate(
          'UPDATE BAN SET TRANGTHAI = ? WHERE SOBAN = ?',
          [status, soban],
        ); */
        setState(() {
          _tablesFuture = fetchTablesFromDB();
        });
      } catch (e) {
        _showSnackBar(context, 'Lỗi cập nhật trạng thái bàn: $e');
      }
    }

    @override
    void initState() {
      super.initState();
      if (widget.datban != null) {
        _selectedTable = widget.datban;
        _orderType = 'Tại bàn';
      }
      _loadInitialData();
      _tablesFuture = fetchTablesFromDB();
    }

    Future<void> _loadInitialData() async {
      setState(() => _isLoading = true);
      try {
        await Future.wait([
          fetchCategories(),
          fetchItemsFromDB(category: _selectedCategory, search: _searchQuery),
        ]);
        setState(() => _error = null);
      } catch (e) {
        setState(() => _error = 'Lỗi tải dữ liệu: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }

    Future<List<TableModel>> fetchTablesFromDB() async {
      try {
        final data = await DatabaseHelper.rawQuery('''
          SELECT BAN.*, 
            IFNULL(MAX(HOADON.GIO), '') AS GIO
          FROM BAN
          LEFT JOIN HOADON ON BAN.MABAN = HOADON.MABAN 
          AND DATE(HOADON.NGAYTAO) = DATE('now')
          GROUP BY BAN.MABAN
          ORDER BY BAN.SOBAN
        ''');
        return data.map((e) => TableModel.fromMap(e)).toList();
      } catch (e) {
        throw Exception('Lỗi khi tải danh sách bàn: $e');
      }
    }

    Future<List<Item>> fetchItemsFromDB({
      String? category,
      String? search,
    }) async {
      try {
        String sql = '''
          SELECT sp.*, dm.TENDANHMUC
          FROM SANPHAM sp
          LEFT JOIN DANHMUC dm ON sp.MADANHMUC = dm.MADANHMUC
          WHERE sp.TRANGTHAI = 'còn hàng'
        ''';
        List<Object?> args = [];

        if (category != null && category != 'Tất cả') {
          sql += ' AND dm.TENDANHMUC = ?';
          args.add(category);
        }
        if (search != null && search.isNotEmpty) {
          sql += ' AND sp.TENSANPHAM LIKE ?';
          args.add('%$search%');
        }

        final data = await DatabaseHelper.rawQuery(sql, args);
        return data.map((e) => Item.fromMap(e)).toList();
      } catch (e) {
        throw Exception('Lỗi khi tải sản phẩm: $e');
      }
    }

    Future<List<String>> fetchCategories() async {
      try {
        final data = await DatabaseHelper.rawQuery(
          'SELECT DISTINCT TENDANHMUC FROM DANHMUC ORDER BY TENDANHMUC',
        );
        return ['Tất cả', ...data.map((e) => e['TENDANHMUC'] as String)];
      } catch (e) {
        throw Exception('Lỗi khi tải danh mục: $e');
      }
    }

    void _showOptionsDialog(BuildContext context, Item item, CartProvider cart) async {
      try {
        if (_selectedTable != null) {
          // Khi thêm món đầu tiên cho bàn
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final existingBill = await DatabaseHelper.rawQuery(
            "SELECT * FROM HOADON WHERE MABAN = ? AND NGAYTAO = ? AND TRANGTHAI = 'Chưa thanh toán'",
            [_selectedTable, today],
          );
          if (existingBill.isEmpty) {
            await DatabaseHelper.insert('HOADON', {
              'MABAN': widget.datban,
              'GIO': DateTime.now().toIso8601String().substring(11, 16),
              'NGAYTAO': DateTime.now().toIso8601String().substring(0, 10),
              'TRANGTHAI': 'Chưa thanh toán',
              'TONGTIEN': 0,
            });
          }
        }
        cart.addToCart(
          item,
          tableNumber: _selectedTable,
        );
        if (_selectedTable != null) {
          await updateTableStatus(
            _selectedTable!,
            'Đang phục vụ',
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thêm ${item.name} vào giỏ hàng',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      final cart = Provider.of<CartProvider>(context);

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            "Bán Hàng",
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          backgroundColor: Color.fromARGB(255, 224, 224, 224),
          centerTitle: true,
          actions: [
            if (_orderType == 'Mang đi')
              badges.Badge(
                badgeContent: Text(
                  cart.items.length.toString(),
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
                position: badges.BadgePosition.topEnd(top: 0, end: 3),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartScreen()),
                    );
                  },
                  icon: Icon(Icons.shopping_cart, color: Colors.black),
                ),
              ),
          ],
        ),
        body:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                )
                : Container(
                  color: Color(0xFFF7F7F7),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _orderType = 'Mang đi';
                                    _selectedTable = null;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _orderType == 'Mang đi'
                                          ? Color(0xFF121212)
                                          : Color(
                                            0xFFE0E0E0,
                                          ), // Đen than hoặc Xám nhẹ
                                  foregroundColor:
                                      _orderType == 'Mang đi'
                                          ? Colors.white
                                          : Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 12,
                                  ),
                                  textStyle: TextStyle(fontSize: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text("Mang đi"),
                              ),
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _orderType = 'Tại bàn';
                                    _selectedTable = null;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _orderType == 'Tại bàn'
                                          ? Color(0xFF121212)
                                          : Color(
                                            0xFFE0E0E0,
                                          ), // Đen than hoặc Xám nhẹ
                                  foregroundColor:
                                      _orderType == 'Tại bàn'
                                          ? Colors.white
                                          : Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 12,
                                  ),
                                  textStyle: TextStyle(fontSize: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text("Tại bàn"),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Tìm kiếm sản phẩm',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      // if (_orderType == 'Tại bàn' && _selectedTable == null)
                      if (_orderType == 'Tại bàn' && _selectedTable == null)
                        Expanded(
                          child: FutureBuilder<List<TableModel>>(
                            future: _tablesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(child: Text("Không có bàn"));
                              }

                            final tables = snapshot.data!;
                            return GridView.builder(
                              padding: EdgeInsets.all(10),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        MediaQuery.of(context).size.width > 600
                                            ? 4
                                            : 3,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: tables.length,
                              itemBuilder: (context, index) {
                                final table = tables[index];
                                final isServing = cart.tableItems[table.soban]?.isNotEmpty == true;
                                return GestureDetector(
                                  onTap: () async {
                                    if (!isServing && table.trangthai == 'Trống') {
                                      await Provider.of<CartProvider>(context, listen: false).updateTableStatus(table.soban, 'Đang phục vụ');
                                      setState(() {
                                        _tablesFuture = fetchTablesFromDB();
                                        _selectedTable = table.soban;
                                      });
                                    } else if (isServing || table.trangthai == 'Đang phục vụ') {
                                      setState(() {
                                        _selectedTable = table.soban;
                                      });
                                    }
                                  },
                                  child: Card(
                                    color: isServing || table.trangthai == 'Đang phục vụ'
                                        ? Colors.red.shade100
                                        : Colors.white,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.table_chart,
                                          size: 40,
                                          color: _selectedTable == table.soban
                                              ? Color(0xFF121212)
                                              : (isServing || table.trangthai == 'Đang phục vụ')
                                                  ? Colors.red
                                                  : Color(0xFF2A2D32),
                                        ),
                                        Text(
                                          "Bàn ${table.soban}",
                                          style: TextStyle(
                                            color: Color(0xFF4A4A4A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          isServing ? 'Đang phục vụ' : table.trangthai,
                                          style: TextStyle(
                                            color: isServing ? Colors.red : Color(0xFF4A4A4A),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (cart.tableItems.containsKey(table.soban))
                                          Text(
                                            '${cart.tableItems[table.soban]!.fold<int>(0, (sum, item) => sum + item.quantity)} món',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    if (_orderType == 'Mang đi' || _selectedTable != null)
                      Expanded(
                        child: Column(
                          children: [
                            if (_selectedTable != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.table_chart,
                                      size: 40,
                                      color: Color(0xFF121212), // Đen than
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Bàn $_selectedTable",
                                      style: TextStyle(
                                        color: Color(0xFF1E1E1E),
                                        fontSize: 14,
                                      ), // Đen tinh tế
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FutureBuilder<List<String>>(
                                future: fetchCategories(),
                                builder: (context, snapshot) {
                                  final categories =
                                      snapshot.data ?? ['Tất cả'];
                                  return DropdownButton<String>(
                                    value: _selectedCategory,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCategory = newValue!;
                                      });
                                    },
                                    items:
                                        categories.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          );
                                        }).toList(),
                                    style: TextStyle(color: Colors.black),
                                    dropdownColor: Colors.white,
                                    iconEnabledColor: Colors.black,
                                    underline: Container(
                                      height: 2,
                                      color: Colors.black,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: FutureBuilder<List<Item>>(
                                future: fetchItemsFromDB(
                                  category: _selectedCategory,
                                  search: _searchQuery,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                      child: Text("Không có sản phẩm"),
                                    );
                                  }
                                  final items = snapshot.data!;
                                  return GridView.builder(
                                    padding: EdgeInsets.all(10),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width >
                                                      600
                                                  ? 4
                                                  : 2,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 0.7,
                                        ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        elevation: 5,
                                        shadowColor: Colors.black.withOpacity(
                                          0.5,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child:
                                                    item.image != null
                                                        ? Image.memory(
                                                          item.image!,
                                                          fit: BoxFit.cover,
                                                        )
                                                        : Icon(
                                                          Icons.image,
                                                          size: 60,
                                                          color: Colors.grey,
                                                        ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8.0,
                                                    ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF1E1E1E,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      "${item.price}đ",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF6B4226,
                                                        ),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    SizedBox(height: 5),
                                                    Text(
                                                      item.unit,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Color(
                                                          0xFF4A4A4A,
                                                        ),
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  _showOptionsDialog(
                                                    context,
                                                    item,
                                                    cart,
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(
                                                    0xFF121212,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 16,
                                                  ),
                                                  textStyle: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                child: Text("Thêm"),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_selectedTable != null &&
                        _tableStatus[_selectedTable!] == 'Chờ thanh toán')
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Show invoice dialog for the selected table
                            final tableItems =
                                cart.tableItems[_selectedTable!] ?? [];
                            final tableTotalAmount = cart.getTableTotalAmount(
                              _selectedTable!,
                            );
                            _showInvoiceDialog(
                              context,
                              tableItems,
                              tableTotalAmount,
                              cart,
                              _selectedTable,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF121212), // Đen than
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            textStyle: TextStyle(fontSize: 14),
                          ),
                          child: Text("Thanh Toán"),
                        ),
                      ),
                    if (_selectedTable != null &&
                        cart.tableItems.containsKey(_selectedTable))
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _showTableCartDialog(context, _selectedTable!, cart);
                          },
                          child: Text('Thanh toán'),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

    void _showInvoiceDialog(
      BuildContext context,
      List<CartItem> items,
      double totalAmount,
      CartProvider cart,
      int? tableNumber,
    ) {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final nhanVien = accountProvider.nhanVien!;
      double discount = 0;
      double additionalFee = 0;
      String paymentMethod = 'Tiền mặt';
      final points = cart.calculatePoints(totalAmount);

      showDialog(
        context: context,
        builder:
            (ctx) => StatefulBuilder(
              builder:
                  (context, setState) => AlertDialog(
                    title: Text(
                      "Hóa Đơn - ${tableNumber != null ? 'Bàn $tableNumber' : 'Mang đi'}",
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Cập nhật hiển thị thông tin nhân viên theo model
                          ListTile(
                            title: Text("Nhân viên: ${nhanVien.hoTen}"),
                            subtitle: Text("Mã NV: ${nhanVien.maNhanVien}"),
                          ),
                          Divider(),
                          // Danh sách sản phẩm
                          ...items.map(
                            (item) => ListTile(
                              leading:
                                  item.item.image != null
                                      ? Image.memory(
                                        item.item.image!,
                                        width: 50,
                                        height: 50,
                                      )
                                      : Icon(Icons.image, size: 50),
                              title: Text(item.item.name),
                              subtitle: Text(
                                "${item.item.price}đ x ${item.quantity}",
                              ),
                            ),
                          ),
                          Divider(),
                          // Thông tin thanh toán
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Giảm giá (%)',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      discount = double.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Phụ thu',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      additionalFee = double.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                                DropdownButton<String>(
                                  value: paymentMethod,
                                  items:
                                      ['Tiền mặt', 'Thẻ'].map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      paymentMethod = value!;
                                    });
                                  },
                                ),
                                Text(
                                  'Tổng tiền: ${NumberFormat('#,##0').format(totalAmount)}đ',
                                ),
                                if (discount > 0)
                                  Text(
                                    'Giảm giá (${discount.toStringAsFixed(0)}%): -${NumberFormat('#,##0').format(totalAmount * discount / 100)}đ',
                                  ),
                                if (additionalFee > 0)
                                  Text(
                                    'Phụ thu: +${NumberFormat('#,##0').format(additionalFee)}đ',
                                  ),
                                Text(
                                  'Thành tiền: ${NumberFormat('#,##0').format(totalAmount * (1 - discount / 100) + additionalFee)}đ',
                                ),
                                Text(
                                  'Điểm tích lũy: +$points điểm',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text("Hủy"),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      ElevatedButton(
                        child: Text("Xác nhận"),
                        onPressed: () async {
                          try {
                            await _saveOrder(
                              context,
                              items,
                              totalAmount,
                              paymentMethod,
                              tableNumber,
                              discount,
                              additionalFee,
                            );

                            // Xóa giỏ hàng sau khi lưu thành công
                            if (tableNumber != null) {
                              cart.clearTableCart(tableNumber);
                              setState(() {
                                _selectedTable = null;
                              });
                            } else {
                              cart.clearCart();
                            }

                            Navigator.pop(context);
                            _showSnackBar(context, "Thanh toán thành công");
                          } catch (e) {
                            _showSnackBar(context, "Lỗi: ${e.toString()}");
                          }
                        },
                      ),
                    ],
                  ),
            ),
      );
    }

    Future<void> _saveOrder(
      BuildContext context,
      List<CartItem> items,
      double totalAmount,
      String paymentMethod,
      int? tableNumber,
      double discount,
      double additionalFee,
    ) async {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final nhanVien = accountProvider.nhanVien!;

      try {
        final now = DateTime.now();
        final points =
            (totalAmount / 10000).floor(); // Tính điểm (1 điểm/10,000đ)

        // Thêm hóa đơn
        final orderSql = '''
          INSERT INTO HOADON 
          (NGAYTAO, TONGTIEN, HINHTHUCMUA, MABAN, MANV, TENNV, GIO, DIEMCONG, GIAMGIA, PHUTHU)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''';

        final orderId = await DatabaseHelper.rawInsert(orderSql, [
          now.toIso8601String(),
          totalAmount * (1 - discount / 100) + additionalFee,
          paymentMethod,
          tableNumber,
          nhanVien.maNhanVien,
          nhanVien.hoTen,
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          points,
          discount,
          additionalFee,
        ]);

        // Thêm chi tiết hóa đơn
        for (var item in items) {
          await DatabaseHelper.rawInsert(
            '''
            INSERT INTO CHITIETHOADON 
            (MAHD, MASANPHAM, TENSANPHAM, SOLUONG, DONGIA, THANHTIEN, GHICHU)
            VALUES (?, ?, ?, ?, ?, ?, ?)
          ''',
            [
              orderId,
              item.item.id,
              item.item.name,
              item.quantity,
              item.item.price,
              item.item.price * item.quantity,
            ],
          );

          // Cập nhật tồn kho
          await DatabaseHelper.rawUpdate(
            '''
            UPDATE SANPHAM 
            SET SOLUONGTON = SOLUONGTON - ?,
                TRANGTHAI = CASE 
                  WHEN (SOLUONGTON - ?) <= 0 THEN 'hết hàng'
                  ELSE TRANGTHAI 
                END
            WHERE MASANPHAM = ?
          ''',
            [item.quantity, item.quantity, item.item.id],
          );
        }

        // Cập nhật điểm tích lũy khách hàng nếu có
        // TODO: Implement customer points update

        // Cập nhật trạng thái bàn nếu có
        if (tableNumber != null) {
          await updateTableStatus(tableNumber, 'Trống');
        }
      } catch (e) {
        throw Exception('Lỗi khi lưu hóa đơn: $e');
      }
    }

  void _showTableCartDialog(BuildContext context, int tableNumber, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final tableItems = cart.tableItems[tableNumber] ?? [];
          return AlertDialog(
            title: Text('Xác nhận thanh toán - Bàn $tableNumber'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...tableItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          item.item.image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(item.item.image!, width: 36, height: 36, fit: BoxFit.cover),
                              )
                            : Icon(Icons.image, size: 36),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.item.name, style: TextStyle(fontWeight: FontWeight.w500)),
                                Row(
                                  children: [
                                    Text('SL:'),
                                    IconButton(
                                      icon: Icon(Icons.remove, size: 18),
                                      constraints: BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      onPressed: item.quantity > 1
                                        ? () async {
                                            await cart.updateCartItem(item, item.quantity - 1);
                                            setStateDialog(() {});
                                          }
                                        : null,
                                    ),
                                    Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: Icon(Icons.add, size: 18),
                                      constraints: BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        await cart.updateCartItem(item, item.quantity + 1);
                                        setStateDialog(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${item.item.price * item.quantity}đ', style: TextStyle(fontWeight: FontWeight.w500)),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                constraints: BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  cart.removeFromCart(item);
                                  setStateDialog(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${cart.getTableTotalAmount(tableNumber).toStringAsFixed(0)}đ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text('Hủy'),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton(
                child: Text('Xác nhận thanh toán'),
                onPressed: tableItems.isEmpty
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            tableNumber: tableNumber,
                            onCheckout: () {
                              cart.clearTableCart(tableNumber);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
              ),
            ],
          );
        },
      ),
    );
  }

    void _showCustomerSearchDialog(BuildContext context) {
      final TextEditingController phoneController = TextEditingController();

      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('Tìm khách hàng'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  child: Text('Tìm'),
                  onPressed: () async {
                    final phone = phoneController.text.trim();
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vui lòng nhập số điện thoại')),
                      );
                      return;
                    }

                    try {
                      final customer = await DatabaseHelper.rawQuery(
                        'SELECT * FROM KHACHHANG WHERE SDT = ?',
                        [phone],
                      );

                      if (customer.isEmpty) {
                        // Hiện form thêm khách hàng mới
                        _showNewCustomerForm(context, phone);
                      } else {
                        // Trả về thông tin khách hàng
                        Navigator.pop(ctx, customer.first);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  },
                ),
              ],
            ),
      );
    }

    void _showNewCustomerForm(BuildContext context, String phone) {
      final nameController = TextEditingController();
      final addressController = TextEditingController();
      final emailController = TextEditingController();

      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('Thêm khách hàng mới'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Họ tên'),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Địa chỉ'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  child: Text('Thêm'),
                  onPressed: () async {
                    try {
                      final id = await DatabaseHelper.rawInsert(
                        '''INSERT INTO KHACHHANG (HOTEN, SDT, DIACHI, EMAIL, DIEMTL)
                    VALUES (?, ?, ?, ?, 0)''',
                        [
                          nameController.text,
                          phone,
                          addressController.text,
                          emailController.text,
                        ],
                      );

                      Navigator.pop(ctx);
                      Navigator.pop(context, {
                        'MAKH': id,
                        'HOTEN': nameController.text,
                        'SDT': phone,
                        'DIEMTL': 0,
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  },
                ),
              ],
            ),
      );
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }





