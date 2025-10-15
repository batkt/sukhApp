import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/img/background_image.png'),
          fit: BoxFit.none,
          scale: 3,
        ),
      ),
      child: child,
    );
  }
}

class MedegdelPage extends StatefulWidget {
  const MedegdelPage({super.key});

  @override
  State<MedegdelPage> createState() => _MedegdelPageState();
}

class _MedegdelPageState extends State<MedegdelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Мэдэгдэл',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicator: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Бүгд'),
                      Tab(text: 'Санал хүсэлт'),
                      Tab(text: 'Гомдол'),
                      Tab(text: 'Мэдэгдэл'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList(),
                    _buildNotificationList(),
                    _buildNotificationList(),
                    _buildNotificationList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildNotificationItem(
          title: 'sanal',
          description: 'yhutgjioerkpfe.wlmkij n b',
          timestamp: '2025-08-29 14:40:28',
          hasButton: true,
        ),
        const SizedBox(height: 12),
        _buildNotificationItem(
          title: 'shaardlaga',
          description: 'yhutgjioerkpfe.wlmkij n b',
          timestamp: '2025-08-29 14:40:21',
          hasButton: false,
        ),
        const SizedBox(height: 12),
        _buildNotificationItem(
          title: 'shaardlaga',
          description: 'yhutgjioerkpfe.wlmkij n b',
          timestamp: '2025-08-29 14:40:12',
          hasButton: false,
        ),
        const SizedBox(height: 12),
        _buildNotificationItem(
          title: 'sanal',
          description: 'hiuhujdqwldjqdjwdqwdqdq',
          timestamp: '2025-08-29 14:36:15',
          hasButton: true,
        ),
        const SizedBox(height: 12),
        _buildNotificationItem(
          title: 'sanal',
          description: 'dqwdqw',
          timestamp: '2025-08-26 12:01:06',
          hasButton: true,
        ),
        const SizedBox(height: 12),
        _buildNotificationItem(
          title: 'sanal',
          description: 'lp',
          timestamp: '2025-08-26 12:00:58',
          hasButton: true,
        ),
      ],
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String description,
    required String timestamp,
    required bool hasButton,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2c3e50).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                timestamp,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
              if (hasButton) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFdc3545),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Хүлээгдэж байгаа',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
