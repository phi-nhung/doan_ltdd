import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class DoanhThu extends StatefulWidget {
  @override
  State<DoanhThu> createState() => _DoanhThuState();
}

class _DoanhThuState extends State<DoanhThu> {
  String _selectedFilter = 'Hôm nay';
  List<BarChartGroupData> _barGroups = [];
  double _totalRevenue = 0;
  int _totalCustomers = 0;
  List<Map<String, dynamic>> _customerList = []; // Danh sách khách hàng

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    final now = DateTime.now();
    List<Map<String, dynamic>> rawData = [];
    _barGroups = [];
    _totalRevenue = 0;
    _totalCustomers = 0;
    _customerList = []; // Reset danh sách khách hàng

    if (_selectedFilter == 'Hôm nay') {
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      rawData = await DatabaseHelper.rawQuery(
        "SELECT hd.TONGTIEN, hd.MAKH, kh.HOTEN FROM HOADON hd "
        "LEFT JOIN KHACHHANG kh ON hd.MAKH = kh.MAKH "
        "WHERE hd.NGAYTAO LIKE '$todayStr%'"
      );

      _totalRevenue = rawData.fold(
          0.0, (sum, item) => sum + (item['TONGTIEN'] ?? 0).toDouble(),);

      // Lấy danh sách khách hàng và tổng tiền
      final customerMap = <String, Map<String, dynamic>>{};
      for (var item in rawData) {
        final maKH = item['MAKH'].toString();
        if (customerMap.containsKey(maKH)) {
          customerMap[maKH]!['TONGTIEN'] += (item['TONGTIEN'] ?? 0).toDouble();
        } else {
          customerMap[maKH] = {
            'HOTEN': item['HOTEN'] ?? 'Khách vãng lai',
            'TONGTIEN': (item['TONGTIEN'] ?? 0).toDouble(),
          };
        }
      }
      
      _customerList = customerMap.values.toList();
      _totalCustomers = _customerList.length;

      _barGroups = [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(toY: _totalRevenue, color: Colors.brown),
          ],
        ),
      ];
    } else if (_selectedFilter == 'Tuần') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final customerMap = <String, Map<String, dynamic>>{};

      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        final dailyData = await DatabaseHelper.rawQuery(
          "SELECT hd.TONGTIEN, hd.MAKH, kh.HOTEN FROM HOADON hd "
          "LEFT JOIN KHACHHANG kh ON hd.MAKH = kh.MAKH "
          "WHERE hd.NGAYTAO LIKE '$dateStr%'"
        );
        
        double dailyTotal = dailyData.fold(
            0.0, (sum, item) => sum + (item['TONGTIEN'] ?? 0).toDouble(),);
        _totalRevenue += dailyTotal;

        // Tổng hợp thông tin khách hàng
        for (var item in dailyData) {
          final maKH = item['MAKH'].toString();
          if (customerMap.containsKey(maKH)) {
            customerMap[maKH]!['TONGTIEN'] += (item['TONGTIEN'] ?? 0).toDouble();
          } else {
            customerMap[maKH] = {
              'HOTEN': item['HOTEN'] ?? 'Khách vãng lai',
              'TONGTIEN': (item['TONGTIEN'] ?? 0).toDouble(),
            };
          }
        }

        _barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: dailyTotal, color: Colors.brown),
            ],
          ),
        );
      }
      
      _customerList = customerMap.values.toList();
      _totalCustomers = _customerList.length;
    } else if (_selectedFilter == 'Tháng') {
      final currentYear = now.year;
      final customerMap = <String, Map<String, dynamic>>{};

      for (int month = 1; month <= 12; month++) {
        final startDate = DateTime(currentYear, month, 1);
        final endDate = DateTime(currentYear, month + 1, 0);
        
        final monthData = await DatabaseHelper.rawQuery(
          "SELECT hd.TONGTIEN, hd.MAKH, kh.HOTEN FROM HOADON hd "
          "LEFT JOIN KHACHHANG kh ON hd.MAKH = kh.MAKH "
          "WHERE hd.NGAYTAO >= '${DateFormat('yyyy-MM-dd').format(startDate)}' "
          "AND hd.NGAYTAO <= '${DateFormat('yyyy-MM-dd').format(endDate)}'"
        );

        double monthTotal = monthData.fold(
            0.0, (sum, item) => sum + (item['TONGTIEN'] ?? 0).toDouble(),);
        _totalRevenue += monthTotal;

        // Tổng hợp thông tin khách hàng
        for (var item in monthData) {
          final maKH = item['MAKH'].toString();
          if (customerMap.containsKey(maKH)) {
            customerMap[maKH]!['TONGTIEN'] += (item['TONGTIEN'] ?? 0).toDouble();
          } else {
            customerMap[maKH] = {
              'HOTEN': item['HOTEN'] ?? 'Khách vãng lai',
              'TONGTIEN': (item['TONGTIEN'] ?? 0).toDouble(),
            };
          }
        }

        _barGroups.add(
          BarChartGroupData(
            x: month - 1, // Bắt đầu từ 0 (Tháng 1)
            barRods: [
              BarChartRodData(toY: monthTotal, color: Colors.brown),
            ],
          ),
        );
      }
      
      _customerList = customerMap.values.toList();
      _totalCustomers = _customerList.length;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doanh thu'),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: _selectedFilter,
              items: ['Hôm nay', 'Tuần', 'Tháng']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                _loadRevenueData();
              },
            ),
            SizedBox(height: 20),
            Text(
              'Tổng doanh thu: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(_totalRevenue)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              child: _barGroups.isEmpty
                  ? Center(child: Text('Chưa có dữ liệu'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: _barGroups,
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (_selectedFilter == 'Tuần') {
                                  final startOfWeek = DateTime.now()
                                      .subtract(Duration(days: DateTime.now().weekday - 1));
                                  final day = startOfWeek.add(Duration(days: value.toInt()));
                                  final dayOfWeek = DateFormat('E').format(day);
                                  return Text(dayOfWeek);
                                } else if (_selectedFilter == 'Tháng') {
                                  return Text('T${value.toInt() + 1}'); // Hiển thị Tháng 1, Tháng 2,...
                                }
                                return Text('');
                              },
                              reservedSize: 22, 
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 20),
            Text(
              'Số lượng khách hàng: $_totalCustomers người',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _customerList.isEmpty
                  ? Center(child: Text('Không có khách hàng'))
                  : ListView.builder(
                      itemCount: _customerList.length,
                      itemBuilder: (context, index) {
                        final customer = _customerList[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(customer['HOTEN']),
                            trailing: Text(
                              NumberFormat.currency(locale: 'vi', symbol: 'đ').format(customer['TONGTIEN']),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}