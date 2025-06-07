import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class DoanhThu extends StatefulWidget {
  @override
  State<DoanhThu> createState() => _DoanhThuState();
}

class _DoanhThuState extends State<DoanhThu> {
  String _selectedFilter = 'Giờ';
  List<BarChartGroupData> _barGroups = [];
  double _totalRevenue = 0;
  int _totalCustomers = 0;
  List<Map<String, dynamic>> _customerList = []; // Danh sách khách hàng
  int _selectedMonth = DateTime.now().month;
  int _selectedWeekday = DateTime.now().weekday - 1; 

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    final now = DateTime.now();
    _barGroups = [];
    _totalRevenue = 0;
    _totalCustomers = 0;
    _customerList = [];

    if (_selectedFilter == 'Giờ') {
      final timeSlots = [0, 5, 10, 15, 20];
      List<Future<List<Map<String, dynamic>>>> futures = [];
      for (int i = 0; i < timeSlots.length; i++) {
        final hour = timeSlots[i];
        final nextHour = i < timeSlots.length - 1 ? timeSlots[i + 1] : 24;
        final dateStr = DateFormat('yyyy-MM-dd').format(now);
        futures.add(DatabaseHelper.rawQuery(
          "SELECT hd.TONGTIEN, hd.MAKH, kh.HOTEN FROM HOADON hd "
          "LEFT JOIN KHACHHANG kh ON hd.MAKH = kh.MAKH "
          "WHERE DATE(hd.NGAYTAO) = '$dateStr' "
          "AND CAST(strftime('%H', hd.NGAYTAO) AS INTEGER) >= $hour "
          "AND CAST(strftime('%H', hd.NGAYTAO) AS INTEGER) < $nextHour"
        ));
      }
      final results = await Future.wait(futures);
      final customerMap = <String, Map<String, dynamic>>{};
      for (int i = 0; i < results.length; i++) {
        final dailyData = results[i];
        double hourlyTotal = 0;
        for (var item in dailyData) {
          final maKH = item['MAKH']?.toString() ?? 'null';
          final hoten = item['HOTEN'] ?? 'Khách vãng lai';
          final tongTien = (item['TONGTIEN'] ?? 0).toDouble();
          hourlyTotal += tongTien;
          if (customerMap.containsKey(maKH)) {
            customerMap[maKH]!['TONGTIEN'] += tongTien;
          } else {
            customerMap[maKH] = {'HOTEN': hoten, 'TONGTIEN': tongTien};
          }
        }
        _barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [BarChartRodData(toY: hourlyTotal, color: Colors.brown)],
          ),
        );
        _totalRevenue += hourlyTotal;
      }
      _customerList = customerMap.values.toList();
      _totalCustomers = _customerList.length;
    } else if (_selectedFilter == 'Tuần') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      List<Future<List<Map<String, dynamic>>>> futures = [];
      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        futures.add(DatabaseHelper.rawQuery(
          "SELECT hd.TONGTIEN, hd.MAKH, kh.HOTEN, hd.NGAYTAO FROM HOADON hd "
          "LEFT JOIN KHACHHANG kh ON hd.MAKH = kh.MAKH "
          "WHERE DATE(hd.NGAYTAO) = '$dateStr'"
        ));
      }
      final results = await Future.wait(futures);
      double totalRevenueSelectedDay = 0;
      final customerMap = <String, Map<String, dynamic>>{};
      // Lọc đúng hóa đơn của ngày đang chọn
      final selectedDayData = results[_selectedWeekday];
      for (var item in selectedDayData) {
        final tongTien = (item['TONGTIEN'] ?? 0).toDouble();
        final maKH = item['MAKH']?.toString() ?? 'null';
        final hoten = item['HOTEN'] ?? 'Khách vãng lai';
        final ngayTao = item['NGAYTAO']?.toString() ?? '';
        // Debug log để kiểm tra dữ liệu từng hóa đơn
        print('[DEBUG] Thứ ${_selectedWeekday + 2} - MAKH: $maKH, HOTEN: $hoten, TONGTIEN: $tongTien, NGAYTAO: $ngayTao');
        if (customerMap.containsKey(maKH)) {
          customerMap[maKH]!['TONGTIEN'] += tongTien;
        } else {
          customerMap[maKH] = {'HOTEN': hoten, 'TONGTIEN': tongTien};
        }
        totalRevenueSelectedDay += tongTien;
      }
      // Biểu đồ vẫn hiển thị đủ 7 ngày
      for (int i = 0; i < results.length; i++) {
        final dailyData = results[i];
        double dailyTotal = 0;
        for (var item in dailyData) {
          dailyTotal += (item['TONGTIEN'] ?? 0).toDouble();
        }
        _barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [BarChartRodData(toY: dailyTotal, color: Colors.brown)],
          ),
        );
      }
      _totalRevenue = totalRevenueSelectedDay;
      _customerList = customerMap.values.toList();
      _totalCustomers = _customerList.length;
    } else if (_selectedFilter == 'Tháng') {
      final year = now.year;
      List<Future<List<Map<String, dynamic>>>> futures = [];
      for (int m = 1; m <= 12; m++) {
        futures.add(DatabaseHelper.rawQuery(
          "SELECT hd.TONGTIEN, hd.MAKH, kh.HOTEN, hd.NGAYTAO FROM HOADON hd "
          "LEFT JOIN KHACHHANG kh ON hd.MAKH = kh.MAKH "
          "WHERE strftime('%Y', hd.NGAYTAO) = '$year' "
          "AND strftime('%m', hd.NGAYTAO) = '${m.toString().padLeft(2, '0')}'"
        ));
      }
      final results = await Future.wait(futures);
      double totalRevenueSelectedMonth = 0;
      final customerMap = <String, Map<String, dynamic>>{};
      // Lọc đúng hóa đơn của tháng đang chọn
      final selectedMonthData = results[_selectedMonth - 1];
      for (var item in selectedMonthData) {
        final tongTien = (item['TONGTIEN'] ?? 0).toDouble();
        final maKH = item['MAKH']?.toString() ?? 'null';
        final hoten = item['HOTEN'] ?? 'Khách vãng lai';
        if (customerMap.containsKey(maKH)) {
          customerMap[maKH]!['TONGTIEN'] += tongTien;
        } else {
          customerMap[maKH] = {'HOTEN': hoten, 'TONGTIEN': tongTien};
        }
        totalRevenueSelectedMonth += tongTien;
      }
      // Biểu đồ vẫn hiển thị đủ 12 tháng
      for (int i = 0; i < results.length; i++) {
        final monthlyData = results[i];
        double monthlyTotal = 0;
        for (var item in monthlyData) {
          monthlyTotal += (item['TONGTIEN'] ?? 0).toDouble();
        }
        _barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [BarChartRodData(toY: monthlyTotal, color: Colors.brown)],
          ),
        );
      }
      _totalRevenue = totalRevenueSelectedMonth;
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter buttons
            Row(
              children: [
                _buildFilterButton('Giờ'),
                SizedBox(width: 10),
                _buildFilterButton('Tuần'),
                SizedBox(width: 10),
                _buildFilterButton('Tháng'),
              ],
            ),
            SizedBox(height: 20),
            
            // Total Revenue
            Text(
              'Tổng doanh thu: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(_totalRevenue)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
            SizedBox(height: 20),
            
            // Chart
            Container(
              height: 250,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _barGroups.isEmpty
                  ? Center(child: Text('Chưa có dữ liệu'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: _barGroups,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: _getHorizontalInterval(),
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                          drawVerticalLine: false,
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) => null),
                          touchCallback: (event, response) {
                            if (_selectedFilter == 'Tháng' && event is FlTapUpEvent && response != null && response.spot != null) {
                              final tappedMonth = response.spot!.touchedBarGroupIndex + 1;
                              if (_selectedMonth != tappedMonth) {
                                setState(() {
                                  _selectedMonth = tappedMonth;
                                });
                                _loadRevenueData();
                              }
                            } else if (_selectedFilter == 'Tuần' && event is FlTapUpEvent && response != null && response.spot != null) {
                              final tappedDay = response.spot!.touchedBarGroupIndex;
                              if (_selectedWeekday != tappedDay) {
                                setState(() {
                                  _selectedWeekday = tappedDay;
                                });
                                _loadRevenueData();
                              }
                            }
                          },
                        ),
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value >= 1000000) {
                                  double tr = value / 1000000;
                                  return Text(tr == tr.toInt() ? '${tr.toInt()} Tr' : '${tr.toStringAsFixed(1)} Tr');
                                } else if (value >= 1000) {
                                  double n = value / 1000;
                                  return Text(n == n.toInt() ? '${n.toInt()} N' : '${n.toStringAsFixed(1)} N');
                                }
                                return Text('${value.toInt()}');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return _getBottomTitle(value.toInt());
                              },
                              reservedSize: 30,
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Chưa có dữ liệu',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            'Số lượng khách hàng sẽ hiển thị tại đây',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
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

  Widget _buildFilterButton(String filter) {
    bool isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          if (filter == 'Tháng') {
            _selectedMonth = DateTime.now().month;
          } else if (filter == 'Tuần') {
            _selectedWeekday = DateTime.now().weekday - 1; // Mặc định chọn thứ hiện tại
          }
        });
        _loadRevenueData();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown : Colors.brown[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.brown,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _getBottomTitle(int value) {
    if (_selectedFilter == 'Giờ') {
      final timeSlots = ['0:00', '5:00', '10:00', '15:00', '20:00'];
      return value < timeSlots.length 
          ? Text(timeSlots[value], style: TextStyle(fontSize: 12))
          : Text('');
    }  else if (_selectedFilter == 'Tuần') {
      final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      return value < days.length 
          ? Text(days[value], style: TextStyle(fontSize: 12))
          : Text('');
    } else if (_selectedFilter == 'Tháng') {
      return Text('T${value + 1}', style: TextStyle(fontSize: 12));
    }
    return Text('');
  }

  double _getMaxY() {
    if (_barGroups.isEmpty) return 100;
    double max = 0;
    for (var group in _barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > max) max = rod.toY;
      }
    }
    if (max <= 1000000) {
      return ((max / 250000).ceil()) * 250000;
    } else if (max <= 5000000) {
      return ((max / 500000).ceil()) * 500000;
    } else if (max <= 10000000) {
      return ((max / 1000000).ceil()) * 1000000;
    } else if (max <= 20000000) {
      return ((max / 2000000).ceil()) * 2000000;
    } else {
      return ((max / 5000000).ceil()) * 5000000;
    }
  }

  double _getHorizontalInterval() {
    double maxY = _getMaxY();
    if (maxY <= 0) return 1;
    return maxY / 5;
  }
}