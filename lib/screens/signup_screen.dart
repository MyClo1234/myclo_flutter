import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'main_wrapper.dart';
import 'terms/terms_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Account
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _isAgreed = false;

  // Step 2: Physical Info (New)
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Step 3: Gender
  String? _selectedGender;

  // Step 4: Body Shape
  String? _selectedBodyShape;

  @override
  void dispose() {
    _pageController.dispose();
    _idController.dispose();
    _pwController.dispose();
    _confirmPwController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Account Validation
      final id = _idController.text.trim();
      final pw = _pwController.text.trim();
      final confirmPw = _confirmPwController.text.trim();

      if (id.isEmpty || pw.isEmpty || confirmPw.isEmpty) {
        _showSnackBar('모든 필드에 입력해주세요.');
        return;
      }
      if (pw != confirmPw) {
        _showSnackBar('비밀번호가 일치하지 않습니다.');
        return;
      }
    } else if (_currentStep == 1) {
      // Physical Info Validation
      if (_ageController.text.isEmpty ||
          _heightController.text.isEmpty ||
          _weightController.text.isEmpty) {
        _showSnackBar('모든 정보를 입력해주세요.');
        return;
      }
    } else if (_currentStep == 2) {
      // Gender Validation
      if (_selectedGender == null) {
        _showSnackBar('성별을 선택해주세요.');
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentStep++;
      // Auto-select first shape if not already selected when entering Step 4 (Body Shape)
      if (_currentStep == 3 && _selectedBodyShape == null) {
        final List<String> shapes = _selectedGender == 'man'
            ? [
                'slim.png',
                'round.png',
                'normal.png',
                'skinny.png',
                'athletic.png',
              ]
            : [
                'slim.png',
                'normal.png',
                'round.png',
                'curvy.png',
                'average.png',
              ];
        if (_selectedBodyShape == null) {
          _selectedBodyShape = shapes[0];
        }
      }
    });
  }

  void _prevStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep--);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSignup() {
    if (_selectedBodyShape == null) {
      _showSnackBar('체형을 선택해주세요.');
      return;
    }

    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final height = int.tryParse(_heightController.text.trim()) ?? 0;
    final weight = int.tryParse(_weightController.text.trim()) ?? 0;

    ref
        .read(authProvider.notifier)
        .register(
          _idController.text.trim(),
          _pwController.text.trim(),
          _selectedGender!,
          _selectedBodyShape!,
          age,
          height,
          weight,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        _showSnackBar(next.error!);
      }

      // Explicit navigation on success
      if (next.isAuthenticated == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainWrapper()),
          (route) => false,
        );
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgDark, AppTheme.bgDark.withBlue(40)],
          ),
        ),
        child: SafeArea(
          child: ResponsiveWrapper(
            maxWidth: 800,
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStepAccount(),
                      _buildStepPhysicalInfo(),
                      _buildStepGender(),
                      _buildStepBodyShape(),
                    ],
                  ),
                ),
                _buildFooter(authState.isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = ['계정 생성', '신체 정보', '성별 선택', '체형 선택'];
    final title = titles.length > _currentStep ? titles[_currentStep] : '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textMain),
            onPressed: _currentStep == 0
                ? () => Navigator.pop(context)
                : _prevStep,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepAccount() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _idController,
            label: '아이디',
            icon: Icons.person_outline,
            hint: 'ID를 입력하세요',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _pwController,
            label: '비밀번호',
            icon: Icons.lock_outline,
            hint: '비밀번호를 입력하세요',
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPwController,
            label: '비밀번호 확인',
            icon: Icons.lock_reset,
            hint: '다시 한 번 입력하세요',
            isPassword: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _isAgreed,
                  activeColor: AppTheme.primary,
                  checkColor: AppTheme.bgDark,
                  side: const BorderSide(color: AppTheme.textMuted),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) {
                    setState(() => _isAgreed = val ?? false);
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '이용약관에 동의합니다',
                style: TextStyle(color: AppTheme.textMain),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.info_outline, color: AppTheme.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepPhysicalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _ageController,
            label: '나이',
            icon: Icons.calendar_today,
            hint: '예: 25',
            keyboardType: TextInputType.number,
            onChanged: (val) {
              if (val.isNotEmpty && int.tryParse(val) == null) {
                _ageController.text = val.replaceAll(RegExp(r'[^0-9]'), '');
                _ageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _ageController.text.length),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _heightController,
            label: '키 (cm)',
            icon: Icons.height,
            hint: '예: 175',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _weightController,
            label: '몸무게 (kg)',
            icon: Icons.monitor_weight_outlined,
            hint: '예: 70',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildStepGender() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildSelectionCard(
            title: '남성',
            icon: Icons.male,
            isSelected: _selectedGender == 'man',
            onTap: () => setState(() {
              _selectedGender = 'man';
              _selectedBodyShape = null;
            }),
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: '여성',
            icon: Icons.female,
            isSelected: _selectedGender == 'woman',
            onTap: () => setState(() {
              _selectedGender = 'woman';
              _selectedBodyShape = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBodyShape() {
    final List<String> shapes = _selectedGender == 'man'
        ? ['slim.png', 'round.png', 'normal.png', 'skinny.png', 'athletic.png']
        : ['slim.png', 'normal.png', 'round.png', 'curvy.png', 'average.png'];

    final isWeb = ResponsiveHelper.isWeb(context);

    if (isWeb) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              '체형을 선택하세요',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: shapes.length,
              itemBuilder: (context, index) {
                final shape = shapes[index];
                final isSelected = _selectedBodyShape == shape;
                final folder = _selectedGender == 'man'
                    ? 'result_shapes_man'
                    : 'result_shapes_woman';

                return GestureDetector(
                  onTap: () => setState(() => _selectedBodyShape = shape),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.white10,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.asset(
                              'assets/images/$folder/$shape',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          width: double.infinity,
                          color: AppTheme.primary.withOpacity(
                            isSelected ? 0.1 : 0,
                          ),
                          child: Center(
                            child: Text(
                              _getShapeName(shape),
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textMain,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
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

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 450,
            child: PageView.builder(
              itemCount: shapes.length,
              onPageChanged: (index) {
                setState(() => _selectedBodyShape = shapes[index]);
              },
              itemBuilder: (context, index) {
                final shape = shapes[index];
                final isSelected = _selectedBodyShape == shape;
                final folder = _selectedGender == 'man'
                    ? 'result_shapes_man'
                    : 'result_shapes_woman';

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.white10,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Image.asset(
                            'assets/images/$folder/$shape',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.image_not_supported,
                                  color: AppTheme.textMuted,
                                  size: 64,
                                ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        color: AppTheme.primary.withOpacity(
                          isSelected ? 0.1 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getShapeName(shape),
                              style: TextStyle(
                                fontSize: 18,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textMain,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(shapes.length, (index) {
              final isSelectedIndex =
                  shapes.indexOf(_selectedBodyShape ?? '') == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelectedIndex ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelectedIndex ? AppTheme.primary : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const Text(
            '좌우로 밀어서 체형을 선택하세요',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed:
                isLoading ||
                    (_currentStep == 0 && !_isAgreed) // Step 0: Check required
                ? null
                : (_currentStep == 3 ? _handleSignup : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.bgDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.bgDark,
                      ),
                    ),
                  )
                : Text(
                    _currentStep == 3 ? '완료' : '다음',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 12),
          if (ref.watch(authProvider).error != null)
            Text(
              ref.watch(authProvider).error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              size: 32,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppTheme.primary : AppTheme.textMain,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: AppTheme.textMain),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.7)),
            filled: true,
            fillColor: AppTheme.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  String _getShapeName(String filename) {
    final map = {
      'slim.png': '슬림',
      'round.png': '라운드',
      'normal.png': '노멀',
      'skinny.png': '스키니',
      'athletic.png': '애슬레틱',
      'curvy.png': '커비',
      'average.png': '에버리지',
    };
    return map[filename] ?? filename.replaceAll('.png', '');
  }
}
