  import 'dart:math';

import 'package:doan/screens/order_screen.dart';
import 'package:flutter/material.dart';
  import 'package:doan/model/oder.dart';
  import 'package:intl/intl.dart';
  import 'package:doan/order_provider.dart';
  import 'order_detail_screen.dart';

  class OrderListScreen extends StatefulWidget {
    @override
    _OrderListScreenState createState() => _OrderListScreenState();
  }

  class _OrderListScreenState extends State<OrderListScreen> {
    String _searchType = 'Mã hóa đơn'; // Mặc định
    String _searchKeyword='';


    final OrderService _orderService = OrderService();
    late Future<List<Order>> _ordersFuture;

    @override
    void initState() {
      super.initState();
      _loadOrders();
    }

    Future<void> _loadOrders() async {
      _ordersFuture = _orderService.fetchOrders();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Đơn hàng'),
        ),
        body: Column(
          children: [
            Padding(                    
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PopupMenuButton<String>(
                      onSelected: (String value) {
                        setState(() {
                          _searchType = value;
                        });
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Mã hóa đơn',
                          child: Text('Mã hóa đơn', style: TextStyle(fontSize: 12)),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Số điện thoại',
                          child: Text('Số điện thoại', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.brown,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, color: Colors.white,),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _searchType,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(color: Colors.white),
                              ),
                            ), 
                            Icon(Icons.arrow_drop_down, color: Colors.white,),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8.0),
                  Expanded(
                    flex: 5,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Nhập từ khóa tìm kiếm',
                      border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    ),
                    onChanged: (value) {
                      _searchKeyword = value; // Cập nhật từ khóa khi người dùng nhập
                    },
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _loadOrdersWithSearch, // Gọi hàm  tìm kiếm khi bấm
                    child:Icon(Icons.search),
                  ),
                ),

                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Order>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Không có đơn hàng nào.'));
                  } else {
                    final orders = snapshot.data!;
                    return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.brown[100],
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text('Mã hóa đơn', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Ngày lập', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.bold))),
                            //Expanded(flex: 2, child: Text('Nhân viên', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Bàn', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailScreen(orderId: order.mahd!),
                                  ),
                                );
                              },
                              child: Container(
                                //color: order.hinhthucmua == 'Hủy đơn hàng' ? Colors.red[100] : null,
                                decoration: BoxDecoration(
                                  border:Border.all(
                                     
                                     color: Colors.black,
                                     width: 1.0,
                                     style: BorderStyle.solid,
                                     
                                  )
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(flex: 1, child: Text('${order.mahd ?? ''}')),
                                    Expanded(flex: 2, child: Text(DateFormat('dd/MM/yyyy').format(order.ngaytao))),
                                    Expanded(flex: 2, child: Text('${NumberFormat('#,##0').format(order.tongtien)}đ')),
                                    //Expanded(flex: 2, child: Text(order.hoTenNhanVien ?? '---')),
                                    Expanded(flex: 1, child: Text(order.soBan?.toString() ?? 'Mang đi')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );

                  }
                },
              ),                                          
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
      );
    }
                                     
 void _loadOrdersWithSearch() {
  setState(() {
    _ordersFuture = _orderService.fetchOrders(
      searchType: _searchType,
      keyword: _searchKeyword,
    );
  });
}
  }
