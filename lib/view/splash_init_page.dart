import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../controllers/splash_controller.dart';
import 'ble_control_page.dart';

class SplashInitPage extends StatefulWidget {
  const SplashInitPage({super.key});

  @override
  State<SplashInitPage> createState() => _SplashInitPageState();
}

class _SplashInitPageState extends State<SplashInitPage> {
  final _controller = SplashController();
  String _status = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _startInitialization();
  }

  void _setupListeners() {
    _controller.messageStream.listen((message) {
      if (mounted) {
        setState(() => _status = message);
      }
    });

    _controller.stateStream.listen((state) {
      if (mounted) {
        setState(() => _hasError = state == InitializationState.error);

        if (state == InitializationState.completed) {
          _navigateToMainPage();
        }
      }
    });
  }

  Future<void> _startInitialization() async {
    await _controller.initializeApp();
  }

  void _navigateToMainPage() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => const BLEControlPage(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Image.asset(
                  'assets/images/esp-32-logo.png',
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'ESP32 BLE Controller',
                style: GoogleFonts.robotoMono(
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    textStyle: TextStyle(
                      fontSize: 14,
                      color:
                          _hasError ? AppColors.error : AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_hasError)
                CupertinoButton(
                  onPressed: _startInitialization,
                  color: AppColors.accent,
                  child: const Text('Retry'),
                )
              else
                const CupertinoActivityIndicator(radius: 15),
            ],
          ),
        ),
      ),
    );
  }
}
