# Pull Request: [Style] Rename 'My Wardrobe' to 'My Closet' for better UX

## Issue: #1 - 브랜딩 및 UX 개선을 위한 명칭 변경
사용자들이 더 친근하게 느낄 수 있도록 'Wardrobe'라는 표현 대신 'Closet'이라는 단어를 사용하도록 수정합니다.

## Proposed Changes
- `lib/screens/wardrobe_screen.dart` 파일의 AppBar 타이틀을 'My Wardrobe'에서 'My Closet'으로 수정했습니다.

## Git Workflow Simulation
1. **이슈 확인**: #1 "Rename Wardrobe to Closet"
2. **브랜치 생성**: `git checkout -b feature/rename-to-closet`
3. **코드 수정**: `wardrobe_screen.dart`의 텍스트 수정
4. **커밋**: `git commit -m "style: rename 'My Wardrobe' to 'My Closet' for better UX"`
5. **풀리퀘스트 생성**: 현재 보고서와 함께 `main` 브랜치로의 병합 요청

## Verification Status
- [x] 타이틀 텍스트 변경 확인
- [x] 코드 컴파일 상태 확인
