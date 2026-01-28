import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '약관 및 정책',
          style: TextStyle(
            color: AppTheme.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Codify 법적 고지 및 약관'),
            const SizedBox(height: 8),
            const Text(
              '최종 수정일: 2026년 1월 26일',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('1. 서비스 이용약관 (Terms & Conditions)'),
            _buildSubTitle('제1조 목적'),
            _buildParagraph(
              '본 약관은 Codify(이하 "회사")가 제공하는 AI 기반 디지털 클로젯 및 스타일링 추천 서비스(이하 "서비스")의 이용 조건 및 절차를 규정합니다. 본 서비스는 Microsoft Azure 클라우드 환경을 기반으로 제공됩니다.',
            ),
            _buildSubTitle('제2조 AI 기반 서비스의 특성 및 면책'),
            _buildBulletPoint(
              '본 서비스는 GPT-4o, SAM 등 인공지능 알고리즘을 활용하여 코디를 제안합니다.',
            ),
            _buildBulletPoint(
              'AI가 제공하는 정보는 확률적 추론에 기반하며, 회사는 추천 결과의 완전성, 무결성, 특정 상황에의 적합성을 보장하지 않습니다.',
            ),
            _buildBulletPoint(
              '기상 데이터 오류 또는 AI 환각(Hallucination) 현상으로 인한 결과에 대해 회사는 고의 또는 중대한 과실이 없는 한 책임을 지지 않습니다.',
            ),
            _buildSubTitle('제3조 지적재산권 및 라이선스'),
            _buildBulletPoint(
              '사용자 콘텐츠: 사용자가 업로드한 의류 이미지의 저작권은 사용자에게 귀속됩니다.',
              isBoldStart: true,
            ),
            _buildBulletPoint(
              '라이선스 부여: 사용자는 서비스 제공, AI 모델 학습, 이미지 검색 성능 개선을 위해 회사가 해당 콘텐츠를 전 세계적으로, 무상으로, 비독점적으로 사용, 복제, 수정(배경 제거 및 특징 추출 등)할 수 있는 권한을 부여합니다.',
              isBoldStart: true,
            ),
            const Divider(color: AppTheme.borderLight, height: 48),

            _buildSectionTitle('2. 개인정보 처리방침 (Privacy Policy)'),
            _buildSubTitle('제1조 수집하는 개인정보 항목'),
            _buildParagraph('서비스는 맞춤형 코디 제안을 위해 다음과 같은 정보를 수집합니다:'),
            _buildBulletPoint(
              '필수 정보: 계정 정보(ID, 이메일), 신체 정보(성별, 나이, 신장, 몸무게, 체형 데이터)',
              isBoldStart: true,
            ),
            _buildBulletPoint(
              '선택 정보: 위치 정보 (실시간 날씨 기반 추천 시 사용 후 즉시 파기)',
              isBoldStart: true,
            ),
            _buildBulletPoint(
              '자동 수집: 접속 로그, 쿠키, 이용 기록, 기기 정보',
              isBoldStart: true,
            ),

            _buildSubTitle('제2조 개인정보의 처리 목적'),
            _buildParagraph('수집된 정보는 다음의 목적을 위해 이용됩니다:'),
            _buildBulletPoint('AI 알고리즘 기반 개인화된 핏(Fit) 및 스타일 분석'),
            _buildBulletPoint('서비스 이용에 따른 본인 식별 및 불량 회원의 부정이용 방지'),
            _buildBulletPoint('신규 서비스(기능) 개발 및 통계 분석'),

            _buildSubTitle('제3조 데이터 위탁 및 국외 이전'),
            _buildParagraph(
              '서비스는 안정적인 운영을 위해 Microsoft Azure를 이용하며, 데이터는 암호화되어 안전하게 관리됩니다.',
            ),
            _buildBulletPoint(
              '위탁 업체: Microsoft Corporation (Azure)',
              isBoldStart: true,
            ),
            _buildBulletPoint(
              '위탁 업무: 클라우드 인프라 제공, 데이터 스토리지, AI API 연산',
              isBoldStart: true,
            ),

            _buildSubTitle('제4조 개인정보의 파기'),
            _buildParagraph(
              '사용자가 회원 탈퇴를 요청하거나 개인정보 수집 목적이 달성된 경우, 해당 정보는 지체 없이 파기합니다. 단, AI 학습을 위해 익명화된 벡터 데이터는 통계적 목적으로 보관될 수 있습니다.',
            ),
            const Divider(color: AppTheme.borderLight, height: 48),

            _buildSectionTitle('3. 쿠키 정책 (Cookie Policy)'),
            _buildSubTitle('제1조 쿠키의 정의 및 목적'),
            _buildParagraph(
              '쿠키는 웹사이트 접속 시 사용자의 브라우저에 저장되는 작은 텍스트 파일입니다. Codify는 사용자 경험 개선 및 로그인 상태 유지를 위해 쿠키를 사용합니다.',
            ),
            _buildSubTitle('제2조 사용하는 쿠키의 종류'),
            _buildBulletPoint(
              '필수 쿠키: 로그인 세션 유지 및 보안 기능을 위해 필수적입니다.',
              isBoldStart: true,
            ),
            _buildBulletPoint(
              '분석 쿠키: 서비스 이용 패턴 분석을 통해 성능을 개선합니다.',
              isBoldStart: true,
            ),

            _buildSubTitle('제3조 쿠키 설정 거부'),
            _buildParagraph(
              '사용자는 브라우저 설정을 통해 쿠키 저장을 거부할 수 있습니다. 단, 필수 쿠키를 차단할 경우 서비스의 일부 기능 이용에 제한이 있을 수 있습니다.',
            ),

            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const Text(
                    '© 2026 Codify. All rights reserved.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Contact: support@codify-ai.com',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMain,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 60, height: 3, color: AppTheme.primary),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildSubTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, {bool isBoldStart = false}) {
    // Splits text by explicit bold marker if needed, or just renders
    // Simple implementation for the plan
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: AppTheme.primary, height: 1.6),
          ),
          Expanded(
            child: isBoldStart && text.contains(':')
                ? RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textMuted,
                      ),
                      children: [
                        TextSpan(
                          text: text.substring(0, text.indexOf(':') + 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                          ),
                        ),
                        TextSpan(text: text.substring(text.indexOf(':') + 1)),
                      ],
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppTheme.textMuted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
