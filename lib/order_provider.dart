import 'package:doan/database_helper.dart';
import 'package:doan/model/oder.dart';
import 'package:doan/model/orderItem.dart';
class OrderService {
  final String _tableName = 'HOADON';
  final String _idColumn = 'MAHD';

  Future<List<Order>> fetchOrders({String? searchType, String? keyword}) async {
    final db = await DatabaseHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (keyword != null && keyword.isNotEmpty) {
      if (searchType == 'Mã hóa đơn') {
        whereClause = 'WHERE d.MAHD = ?';
        whereArgs.add(int.tryParse(keyword) ?? -1);
      } else if (searchType == 'Số điện thoại') {
        whereClause = 'WHERE k.SDT = ?';
        whereArgs.add(keyword);
      }
    }

    final result = await db.rawQuery('''
      SELECT d.*,
             k.HOTEN AS TENKHACHHANG,
             k.SDT AS SDTKH,
             nv.HOTEN AS HOTENNHANVIEN,
             b.SOBAN
      FROM HOADON d
      LEFT JOIN KHACHHANG k ON d.MAKH = k.MAKH
      LEFT JOIN NHANVIEN nv ON d.MANV = nv.MANHANVIEN
      LEFT JOIN BAN b ON d.MABAN = b.MABAN
      $whereClause
      ORDER BY MAHD ASC
    ''', whereArgs);

    return result.map((row) => Order.fromMap(row)).toList();
  }

  Future<Order?> fetchOrderById(int id) async {
    final db = await DatabaseHelper.database;
    try {
      final result = await db.rawQuery('''
        SELECT d.*,
               k.HOTEN ,
               k.SDT ,
               nv.HOTEN AS HOTENNHANVIEN,
               b.SOBAN
        FROM HOADON d
        LEFT JOIN KHACHHANG k ON d.MAKH = k.MAKH
        LEFT JOIN NHANVIEN nv ON d.MANV = nv.MANHANVIEN
        LEFT JOIN BAN b ON d.MABAN = b.MABAN
        WHERE d.MAHD = ?
      ''', [id]);

      if (result.isNotEmpty) {
        print('DEBUG: fetchOrderById - Order data: ${result.first}');
        return Order.fromMap(result.first);
      }
      print('DEBUG: fetchOrderById - No order found for ID: $id');
      return null;
    } catch (e) {
      print('Lỗi khi lấy chi tiết đơn hàng: $e');
      return null;
    }
  }

  Future<List<OrderItem>> fetchOrderItems(int orderId) async {
    final db = await DatabaseHelper.database;
    try {
      final result = await db.rawQuery('''
        SELECT ci.*,
               mh.TENSANPHAM,
               mh.GIABAN AS DONGIA,
               mh.HINHANH
        FROM CHITIETHOADON ci
        JOIN SANPHAM mh ON ci.MASP = mh.MASANPHAM
        WHERE ci.MAHD = ?
      ''', [orderId]);

      print('DEBUG: fetchOrderItems - Order ID: $orderId, Items found: ${result.length}');
      if (result.isNotEmpty) {
        print('DEBUG: fetchOrderItems - First item data: ${result.first}');
      }
      return result.map((row) => OrderItem.fromMap(row)).toList();
    } catch (e) {
      print('Lỗi khi lấy danh sách sản phẩm của đơn hàng: $e');
      print('SQL Error: $e'); // Thêm dòng này để thấy lỗi SQL cụ thể
      return [];
    }
  }

  Future<int> addOrder(Order order) async {
    try {
      final int result = await DatabaseHelper.insert(_tableName, order.toMap());
      return result;
    } catch (e) {
      print('Lỗi khi thêm đơn hàng: $e');
      return -1;
    }
  }

  Future<int> updateOrder(Order order) async {
    try {
      final int result = await DatabaseHelper.update(_tableName, order.mahd!, order.toMap(), idColumn: _idColumn);
      return result;
    } catch (e) {
      print('Lỗi khi cập nhật đơn hàng: $e');
      return -1;
    }
  }

  Future<int> deleteOrder(int id) async {
    try {
      final int result = await DatabaseHelper.delete(_tableName, id, idColumn: _idColumn);
      return result;
    } catch (e) {
      print('Lỗi khi xóa đơn hàng: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql) async {
    try {
      final List<Map<String, dynamic>> result = await DatabaseHelper.rawQuery(sql);
      return result;
    } catch (e) {
      print('Lỗi rawQuery: $e');
      return [];
    }
  }
}
