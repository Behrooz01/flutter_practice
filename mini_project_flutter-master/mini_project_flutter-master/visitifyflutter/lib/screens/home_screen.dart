import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async'; // 1. Necessary for StreamSubscription
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/services.dart'; // For platform exceptions

// -----------------------------------------------------------------------------
// Razorpay Service (Requires 'razorpay_flutter' package)
// -----------------------------------------------------------------------------

class RazorpayService {
  late Razorpay _razorpay;

  // **IMPORTANT: Replace this with your actual Public Test Key ID**
  static const String _razorpayKeyId = 'YOUR_PUBLIC_TEST_KEY_ID_HERE';

  RazorpayService({required VoidCallback onSuccess}) {
    _razorpay = Razorpay();
    // Use the provided callback on successful payment
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      _handlePaymentSuccess(response);
      onSuccess(); // Clear the cart after success
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void openCheckout(BuildContext context, double amount) {
    if (_razorpayKeyId == 'YOUR_PUBLIC_TEST_KEY_ID_HERE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your Razorpay Test Key ID first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Razorpay amount is in the smallest currency unit (e.g., paise for INR)
    int amountInPaise = (amount * 100).round();

    var options = {
      'key': _razorpayKeyId,
      'amount': amountInPaise,
      'name': 'Domino\'s Clone',
      'description': 'Pizza Order Payment',
      // Placeholder data for prefill
      'prefill': {'contact': '9876543210', 'email': 'test@example.com'},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("SUCCESS: ${response.paymentId}");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("ERROR: ${response.code} - ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("EXTERNAL_WALLET: ${response.walletName}");
  }
}

// -----------------------------------------------------------------------------
// HomeScreen with Bottom Navigation and Cart State
// -----------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Map<dynamic, dynamic>> _cartItems = [];

  void _addItemToCart(Map<dynamic, dynamic> pizza) {
    setState(() {
      _cartItems.add(pizza);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${pizza['title'] ?? 'Item'} added to cart!'),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      // Navigate back to the home screen after checkout success
      _selectedIndex = 0;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _pages => [
    HomePage(addItemToCart: _addItemToCart),
    CartPage(
      cartItems: _cartItems,
      // Pass the clearCart function to the CartPage
      clearCart: _clearCart,
    ),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.redAccent,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(_cartItems.length.toString()),
              isLabelVisible: _cartItems.isNotEmpty,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HomePage (Data Fetching and Display)
// -----------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  final void Function(Map<dynamic, dynamic>) addItemToCart;

  const HomePage({super.key, required this.addItemToCart});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  List<Map<dynamic, dynamic>> offers = [];
  List<Map<dynamic, dynamic>> pizzas = [];
  bool isLoading = true;

  late StreamSubscription _offersSubscription;
  late StreamSubscription _pizzasSubscription;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Clean up the stream subscriptions to prevent memory leaks
  @override
  void dispose() {
    _offersSubscription.cancel();
    _pizzasSubscription.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    // Firebase stream listeners
    fetchOffers();
    fetchPizzas();

    // Simulate initial loading time
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => isLoading = false);
  }

  void fetchOffers() {
    _offersSubscription = dbRef.child("offers").onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final temp = data.values.map((e) => Map.from(e)).toList();
        setState(() => offers = temp);
      } else {
        setState(() => offers = []);
      }
    });
  }

  void fetchPizzas() {
    _pizzasSubscription = dbRef.child("pizzas").onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final temp = data.values.map((e) => Map.from(e)).toList();
        setState(() => pizzas = temp);
      } else {
        setState(() => pizzas = []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Domino’s Clone 🍕',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 Offers Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '🔥 Offers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: 180,
              child: offers.isEmpty && !isLoading
                  ? const Center(child: Text("No offers available"))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return Container(
                    margin: const EdgeInsets.all(8),
                    width: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: NetworkImage(offer['imageUrl'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🍕 Pizza Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '🍕 Pizzas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            pizzas.isEmpty && !isLoading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No pizzas available"),
              ),
            )
                : GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: pizzas.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final pizza = pizzas[index];
                return PizzaItem(
                  pizza: pizza,
                  onAddToCart: widget.addItemToCart,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pizza Item Widget
// -----------------------------------------------------------------------------

class PizzaItem extends StatelessWidget {
  final Map<dynamic, dynamic> pizza;
  final void Function(Map<dynamic, dynamic>) onAddToCart;

  const PizzaItem({
    super.key,
    required this.pizza,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              pizza['imageUrl'] ?? '',
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error, color: Colors.red),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              pizza['title'] ?? 'Unknown Pizza',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Price and Cart Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "₹${pizza['price'] ?? '0.00'}",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: Colors.redAccent),
                onPressed: () => onAddToCart(pizza),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CartPage (Displaying Cart Items, Totals, and Checkout)
// -----------------------------------------------------------------------------

class CartPage extends StatefulWidget {
  final List<Map<dynamic, dynamic>> cartItems;
  final VoidCallback clearCart;

  const CartPage({super.key, required this.cartItems, required this.clearCart});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Initialize Razorpay Service and pass the clearCart callback
  late RazorpayService _razorpayService;
  final double _deliveryCharge = 50.0;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService(onSuccess: widget.clearCart);
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  double get _subtotal {
    double total = 0.0;
    for (var item in widget.cartItems) {
      total += double.tryParse(item['price'].toString()) ?? 0.0;
    }
    return total;
  }

  double get _grandTotal {
    // Only charge delivery if subtotal > 0
    return _subtotal > 0 ? _subtotal + _deliveryCharge : 0.0;
  }

  void _startCheckout() {
    if (_grandTotal > 0) {
      _razorpayService.openCheckout(context, _grandTotal);
    }
  }

  Widget _buildSummaryRow(String title, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.redAccent : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cartItems.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Your cart is empty 🛒",
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          // Cart Items List
          Expanded(
            child: ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return ListTile(
                  leading: Image.network(
                    item['imageUrl'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(item['title'] ?? 'Unknown Item'),
                  subtitle: Text("Price: ₹${item['price'] ?? '0.00'}"),
                  // Placeholder for removal/quantity
                );
              },
            ),
          ),

          // Cart Summary and Checkout Button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Totals
                _buildSummaryRow("Subtotal", _subtotal),
                _buildSummaryRow("Delivery Fee", _deliveryCharge),
                const Divider(),
                _buildSummaryRow("Grand Total", _grandTotal, isTotal: true),
                const SizedBox(height: 16),

                // Checkout Button
                ElevatedButton.icon(
                  onPressed: _startCheckout,
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    "CHECKOUT (PAY ₹${_grandTotal.toStringAsFixed(2)})",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ProfilePage (Attractive Layout)
// -----------------------------------------------------------------------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Section
            Container(
              color: Colors.redAccent.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.person_outline, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome, Pizza Lover!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'user.email@example.com',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 2. Account Management Section
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('ACCOUNT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: Column(
                children: const [
                  ProfileMenuItem(icon: Icons.history, title: 'Order History'),
                  Divider(height: 0, indent: 15, endIndent: 15),
                  ProfileMenuItem(icon: Icons.location_on_outlined, title: 'Saved Addresses'),
                  Divider(height: 0, indent: 15, endIndent: 15),
                  ProfileMenuItem(icon: Icons.wallet_outlined, title: 'Payment Methods'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Settings and Support Section
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('SUPPORT & APP', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: Column(
                children: const [
                  ProfileMenuItem(icon: Icons.settings_outlined, title: 'App Settings'),
                  Divider(height: 0, indent: 15, endIndent: 15),
                  ProfileMenuItem(icon: Icons.help_outline, title: 'Help & FAQ'),
                  Divider(height: 0, indent: 15, endIndent: 15),
                  ProfileMenuItem(icon: Icons.info_outline, title: 'About App'),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. Logout Button
            TextButton.icon(
              onPressed: () {
                // Handle Logout logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logging out...')),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Helper Widget for Profile Menu Items
// -----------------------------------------------------------------------------

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon!')),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}