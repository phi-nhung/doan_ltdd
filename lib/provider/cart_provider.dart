import 'package:doan/model/table.dart';
import 'package:flutter/material.dart';
import '../model/item.dart';
import '../model/cart_item.dart';
import '../database_helper.dart';
import '../model/table.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> items = [];
  Map<int, List<CartItem>> tableItems = {};

  Future<bool> checkStock(Item item, int quantity) async {
    try {
      final result = await DatabaseHelper.rawQuery(
        'SELECT SOLUONGTON FROM SANPHAM WHERE MASANPHAM = ?',
        [item.id]
      );
      
      if (result.isNotEmpty) {
        final currentStock = result.first['SOLUONGTON'] as int?;
        if (currentStock == null) return false;
        return currentStock >= quantity;
      }
      return false;
    } catch (e) {
      print('Lỗi kiểm tra tồn kho: $e');
      return false;
    }
  }

  Future<void> addToCart(Item item, {int? tableNumber}) async {
    try {
      // Lấy số lượng tồn kho (có thể null)
      final result = await DatabaseHelper.rawQuery(
        'SELECT SOLUONGTON FROM SANPHAM WHERE MASANPHAM = ?',
        [item.id]
      );
      int? currentStock;
      if (result.isNotEmpty) {
        currentStock = result.first['SOLUONGTON'] as int?;
      }

      // Nếu tồn kho khác null thì phải kiểm tra tồn kho
      if (currentStock != null) {
        final hasStock = currentStock >= 1;
        if (!hasStock) {
          throw Exception('Sản phẩm không đủ số lượng trong kho!');
        }
      }

      if (tableNumber != null) {
        tableItems.putIfAbsent(tableNumber, () => []);
        final wasEmpty = tableItems[tableNumber]!.isEmpty;
        final existing = tableItems[tableNumber]!.indexWhere((e) => e.item.id == item.id);
        if (existing != -1) {
          final newQuantity = tableItems[tableNumber]![existing].quantity + 1;
          // Nếu tồn kho khác null thì phải kiểm tra tồn kho cho số lượng mới
          if (currentStock != null && currentStock < newQuantity) {
            throw Exception('Sản phẩm không đủ số lượng trong kho!');
          }
          tableItems[tableNumber]![existing].quantity = newQuantity;
        } else {
          tableItems[tableNumber]!.add(CartItem(item: item, quantity: 1, tableNumber: tableNumber));
        }
        if (wasEmpty) {
          await updateTableStatus(tableNumber, 'Đang phục vụ');
        }
      } else {
        final existing = items.indexWhere((e) => e.item.id == item.id);
        if (existing != -1) {
          final newQuantity = items[existing].quantity + 1;
          // Nếu tồn kho khác null thì phải kiểm tra tồn kho cho số lượng mới
          if (currentStock != null && currentStock < newQuantity) {
            throw Exception('Sản phẩm không đủ số lượng trong kho!');
          }
          items[existing].quantity = newQuantity;
        } else {
          items.add(CartItem(item: item, quantity: 1));
        }
      }
      notifyListeners();
    } catch (e) {
      print('Lỗi khi thêm vào giỏ hàng: $e');
      rethrow;
    }
  }

  void clearCart() {
    items.clear();
    notifyListeners();
  }

  void clearTableCart(int tableNumber) {
    tableItems.remove(tableNumber);
    updateTableStatus(tableNumber, 'Trống');
    notifyListeners();
  }

  double getTableTotalAmount(int tableNumber) {
    final tableCart = tableItems[tableNumber] ?? [];
    return tableCart.fold(0, (sum, item) => sum + (item.item.price * item.quantity));
  }

  double get totalAmount {
    double total = 0;
    for (var item in items) {
      total += item.item.price * item.quantity;
    }
    return total;
  }
  
  double totalAmountByTable(int tableNumber) {
    double total = 0;
    if (tableItems.containsKey(tableNumber)) {
      for (var item in tableItems[tableNumber]!) {
        total += item.item.price * item.quantity;
      }
    }
    return total;
  }
  
  void removeFromCart(CartItem item) {
    if (item.tableNumber != null) {
      final tableCart = tableItems[item.tableNumber!];
      if (tableCart != null) {
        tableCart.remove(item);
        if (tableCart.isEmpty) {
          updateTableStatus(item.tableNumber!, 'Trống');
        }
      }
    } else {
      items.remove(item);
    }
    notifyListeners();
  }
  
  double calculatePoints(double totalAmount) {
    // Tính điểm cộng dựa trên tổng tiền (mỗi 10,000đ = 1 điểm)
    return (totalAmount / 10000).floor().toDouble();
  }

  Future<int?> saveOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String paymentMethod,
    required int? tableNumber,
    required int manv,
    required String tennv,
    Map<String, dynamic>? customer,
    double discount = 0,
    double additionalFee = 0,
  }) async {
    try {
      final now = DateTime.now();
      final points = (discount > 0) ? 0 : (totalAmount / 10000).floor();
      final pointsToDeduct = (discount > 0) ? (totalAmount / 10000).floor() : 0;
      final finalAmount = totalAmount * (1 - discount / 100) + additionalFee;
      
      // Đặt HINHTHUCMUA đúng theo constraint CHK_HTM
      final String hinhThucMua = tableNumber != null ? 'Uống tại bàn' : 'Mang đi';

      // Lấy MAHD vừa tạo
      final mahdResult = await DatabaseHelper.rawInsert(
        '''
        INSERT INTO HOADON 
        (NGAYTAO, TONGTIEN, DIEMCONG, HINHTHUCMUA, MAKH, MANV, MABAN, GIO)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          now.toIso8601String(),  // NGAYTAO
          finalAmount,            // TONGTIEN
          points,                 // DIEMCONG
          hinhThucMua,            // HINHTHUCMUA - Sửa lại giá trị theo constraint
          customer?['MAKH'],      // MAKH
          manv,                   // MANV
          tableNumber,            // MABAN
          '${now.hour}:${now.minute}', // GIO
        ]
      );

      // Lấy MAHD vừa tạo
      final mahdQuery = await DatabaseHelper.rawQuery('SELECT MAX(MAHD) as maxId FROM HOADON');
      final newMaHD = mahdQuery.first['maxId'];

      // Thêm chi tiết hóa đơn (KHÔNG truyền MACHITIET)
      for (var item in items) {
        await DatabaseHelper.rawInsert(
          'INSERT INTO CHITIETHOADON (SOLUONG, DONGIA, THANHTIEN, MAHD, MASP) VALUES (?, ?, ?, ?, ?)',
          [
            item.quantity,               // SOLUONG
            item.item.price,             // DONGIA
            item.item.price * item.quantity, // THANHTIEN
            newMaHD,                     // MAHD (liên kết hóa đơn)
            item.item.id,                // MASP
          ]
        );
        final slt= (await DatabaseHelper.rawQuery(
          'SELECT SOLUONGTON FROM SANPHAM WHERE MASANPHAM = ?',
          [item.item.id]
        ));
        if (slt.first['SOLUONGTON'] !='NULL')
        {
          await DatabaseHelper.rawUpdate(
          'UPDATE SANPHAM SET SOLUONGTON = SOLUONGTON - ? WHERE MASANPHAM = ?',
          [item.quantity, item.item.id]
        );
        }
      }

      // Cập nhật điểm tích lũy cho khách hàng
      if (customer != null) {
        if (discount > 0) {
          // Nếu có chiết khấu, trừ điểm
          final currentPoint = customer['DIEMTL'] ?? 0;
          final newPoint = (currentPoint - pointsToDeduct) < 0 ? 0 : (currentPoint - pointsToDeduct);
          
          // Xác định loại khách hàng mới
          int newLoaiKH = 1; // mặc định vãng lai
          if (newPoint >= 100) {
            // Tìm loại thân thiết
            final loai = await DatabaseHelper.rawQuery(
              'SELECT MALOAIKH FROM LOAIKHACHHANG WHERE DIEMTITOITHIEU <= ? ORDER BY DIEMTITOITHIEU DESC LIMIT 1', 
              [newPoint]
            );
            if (loai.isNotEmpty) newLoaiKH = loai.first['MALOAIKH'];
          }
          
          await DatabaseHelper.rawUpdate(
            'UPDATE KHACHHANG SET DIEMTL = ?, MALOAIKH = ? WHERE MAKH = ?',
            [newPoint, newLoaiKH, customer['MAKH']]
          );
        } else {
          // Nếu không có chiết khấu, cộng điểm
          final currentPoint = customer['DIEMTL'] ?? 0;
          final newPoint = currentPoint + points;
          
          // Xác định loại khách hàng mới
          int newLoaiKH = 1; // mặc định vãng lai
          if (newPoint >= 100) {
            // Tìm loại thân thiết
            final loai = await DatabaseHelper.rawQuery(
              'SELECT MALOAIKH FROM LOAIKHACHHANG WHERE DIEMTITOITHIEU <= ? ORDER BY DIEMTITOITHIEU DESC LIMIT 1', 
              [newPoint]
            );
            if (loai.isNotEmpty) newLoaiKH = loai.first['MALOAIKH'];
          }
          
          await DatabaseHelper.rawUpdate(
            'UPDATE KHACHHANG SET DIEMTL = ?, MALOAIKH = ? WHERE MAKH = ?',
            [newPoint, newLoaiKH, customer['MAKH']]
          );
        }
      }

      if (tableNumber != null) {
        await DatabaseHelper.rawUpdate(
          'UPDATE BAN SET TRANGTHAI = ? WHERE SOBAN = ?',
          ['Trống', tableNumber]
        );
      }

      notifyListeners();
      return newMaHD;
    } catch (e) {
      print('Lỗi chi tiết: $e');
      throw Exception('Lỗi khi lưu hóa đơn: $e'); 
    }
  }

  Future<void> updateCartItem(
    CartItem oldItem,
    int newQuantity,
  ) async {
    try {
      if (newQuantity <= 0) {
        throw Exception('Số lượng phải lớn hơn 0!');
      }

      // Kiểm tra tồn kho trước khi cập nhật
      final hasStock = await checkStock(oldItem.item, newQuantity);
      if (!hasStock) {
        throw Exception('Số lượng vượt quá tồn kho!');
      }

      if (oldItem.tableNumber != null) {
        // Cập nhật giỏ hàng theo bàn
        final tableCart = tableItems[oldItem.tableNumber!];
        if (tableCart != null) {
          final index = tableCart.indexOf(oldItem);
          if (index != -1) {
            tableCart[index] = CartItem(
              item: oldItem.item,
              quantity: newQuantity,
              tableNumber: oldItem.tableNumber,
            );
          }
        }
      } else {
        // Cập nhật giỏ hàng mang về
        final index = items.indexOf(oldItem);
        if (index != -1) {
          items[index] = CartItem(
            item: oldItem.item,
            quantity: newQuantity,
          );
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Lỗi khi cập nhật giỏ hàng: $e');
      rethrow;
    }
  }

  Future<void> updateTableStatus(int soban, String status) async {
    try {
      await DatabaseHelper.rawUpdate(
        'UPDATE BAN SET TRANGTHAI = ? WHERE SOBAN = ?',
        [status, soban],
      );
      notifyListeners();
    } catch (e) {
      print('Lỗi cập nhật trạng thái bàn: $e');
    }
  }

  Future<List<TableModel>> fetchTablesFromDB() async {
    final data = await DatabaseHelper.rawQuery('SELECT * FROM BAN ORDER BY SOBAN');
    return data.map((e) => TableModel.fromMap(e)).toList();
  }
}
