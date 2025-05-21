import 'package:flutter/material.dart';
import 'dart:async';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage("https://img.lovepik.com/free-png/20211225/lovepik-simple-man-icon-png-image_400345200_wh860.png"),
          ),
        ),
        
        actions: [
          IconButton(
            icon: Icon(Icons.coffee, color: Color.fromARGB(255, 107, 66, 38)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.search, color: Color.fromARGB(255, 74, 74, 74)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfo(),
              SizedBox(height: 20),
              _buildCategoryMenu(),
              SizedBox(height: 20),
              _buildPromoBanner(),
              SizedBox(height: 20),
              SizedBox(height: 20),
              _buildPromoHeader(),
              _buildPromoList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color.fromARGB(255, 107, 66, 38),
        unselectedItemColor: Color.fromARGB(255, 18, 18, 18),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Đặt hàng"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Cửa hàng"),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: "Ưu đãi"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "Khác"),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Color.fromARGB(255, 18, 18, 18), // Màu nền
      borderRadius: BorderRadius.circular(12), // Bo góc
      border: Border.all(color: Color.fromARGB(255, 224, 224, 224)), // Viền nhẹ
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage("https://img.lovepik.com/free-png/20211225/lovepik-simple-man-icon-png-image_400345200_wh860.png"),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quan Nguyen",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 247, 247, 247),
                ),
              ),
              Text(
                "Phin Thành Viên",
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 247, 247, 247),
                ),
              ),
              SizedBox(height: 5),
              // Thanh tiến trình
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double progress = 450000 / 1000000; // Tính phần trăm tiến trình
                      return Container(
                        height: 8,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 107, 66, 38),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 3),
              Text(
                "450,000₫ / 1,000,000₫",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}




  Widget _buildCategoryMenu() {
    final categories = [
      "Cà phê truyền thống",
      "Cà phê pha máy",
      "Trà",
      "Phindi",
      "Đá xay",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (category) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Chip(
                  label: Text(category, style: TextStyle(color: Colors.white)),
                  backgroundColor: Color.fromARGB(255, 107, 66, 38),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return _PromoBanner();
  }

  Widget _buildPromoList() {
    final promotions = [
      "https://scontent.fsgn5-9.fna.fbcdn.net/v/t1.6435-9/88941921_649338945868960_1681291370658004992_n.jpg?_nc_cat=102&ccb=1-7&_nc_sid=127cfc&_nc_ohc=HFwelQGgNVEQ7kNvgHGDoCQ&_nc_oc=AdkVyZ8LVaFrYqjKSoOdrrdIAzhaWSw2V8N8kuJCswCw1aEqEuceELrP8M4WnuG9tYk&_nc_zt=23&_nc_ht=scontent.fsgn5-9.fna&_nc_gid=2l2bmyMX62IUs0149MihAw&oh=00_AYGglqUcKFvQ2NQFJiW5fPAgMVBD8Klv1eP63sNLVfeL5Q&oe=68071E68",
      "https://scontent.fsgn5-5.fna.fbcdn.net/v/t39.30808-6/484031486_954876103462763_2598047001092327474_n.jpg?stp=dst-jpg_s600x600_tt6&_nc_cat=108&ccb=1-7&_nc_sid=833d8c&_nc_ohc=ZI9CBVHun7YQ7kNvgGJrBQQ&_nc_oc=AdmqFWYF74XOdVUSyzXdWs03ix7Ek-O4Qbut4MsazEyyiLyBZtC5qkaKjn2X4AtbqYw&_nc_zt=23&_nc_ht=scontent.fsgn5-5.fna&_nc_gid=O078_EDKtYurqAKl6EGdmA&oh=00_AYEzXr5x9pDIuIMqfepvjtefu2A_s_pkHrDXVvWT1aaZag&oe=67E57EC8",
      "https://scontent.fsgn5-9.fna.fbcdn.net/v/t39.30808-6/481670631_942432358040471_184124765600051150_n.jpg?_nc_cat=105&ccb=1-7&_nc_sid=833d8c&_nc_ohc=kCBdrBbbqOcQ7kNvgHcupF1&_nc_oc=AdkiKzqv5LgB1oRVQ-bHAkn53YseRrNJ4iN_NZh7Bbl14sJOkQ1iitfPN3Rfy1Ic1x4&_nc_zt=23&_nc_ht=scontent.fsgn5-9.fna&_nc_gid=-xgbNPh4T8H7576KlbDV9A&oh=00_AYF1sPMWUenXlKtyEjRzmDy_RCaQDgqCwGs-pGoBNdDjSw&oe=67E59780",
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                promotions[index],
                fit: BoxFit.cover,
                width: 150,
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildPromoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Khuyến Mãi",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 107, 66, 38),
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Xử lý khi nhấn "Xem thêm"
          },
          child: Row(
            children: [
              Text(
                "Xem thêm",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.red.shade700, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatefulWidget {
  @override
  _PromoBannerState createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _bannerImages = [
    "https://mir-s3-cdn-cf.behance.net/projects/404/080032218987079.Y3JvcCwxODQxLDE0NDAsMzYwLDA.jpg",
    "https://png.pngtree.com/thumb_back/fh260/background/20210205/pngtree-milk-tea-poster-background-image_543456.jpg",
    "https://png.pngtree.com/thumb_back/fh260/png-vector/20200530/ourmid/pngtree-fruit-tea-ice-drink-png-image_2214922.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      setState(() {
        _currentPage = (_currentPage + 1) % _bannerImages.length;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _bannerImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _bannerImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 150,
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerImages.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Color.fromARGB(255, 107, 66, 38)
                      : Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  

}
