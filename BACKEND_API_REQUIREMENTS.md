# 백엔드 API 요구사항 정리

## 프로젝트 개요
- 사용자의 옷장(wardrobe)을 관리하고 AI 기반 의류 추천 시스템을 제공하는 Flutter 앱
- 현재 백엔드 URL: `http://localhost:5000` (개발환경) / `http://10.0.2.2:5000` (안드로이드)

---

## 인증 (Authentication)

### 1. 로그인 API
- **엔드포인트**: `/api/auth/login` (미구현 - 현재는 로컬 더미 데이터 사용)
- **메서드**: POST
- **요청 본문**:
  ```json
  {
    "id": "string",
    "password": "string"
  }
  ```
- **응답**:
  ```json
  {
    "success": true,
    "token": "string (JWT or similar)",
    "user": {
      "id": "string",
      "gender": "male|female",
      "bodyShape": "string"
    }
  }
  ```

### 2. 회원가입 API
- **엔드포인트**: `/api/auth/register` (미구현 - 현재는 로컬 더미 데이터 사용)
- **메서드**: POST
- **요청 본문**:
  ```json
  {
    "id": "string",
    "password": "string",
    "gender": "male|female",
    "bodyShape": "string"
  }
  ```
- **응답**:
  ```json
  {
    "success": true,
    "token": "string",
    "user": {
      "id": "string",
      "gender": "male|female",
      "bodyShape": "string"
    }
  }
  ```

### 3. 로그아웃 API
- **엔드포인트**: `/api/auth/logout`
- **메서드**: POST
- **요청 헤더**: `Authorization: Bearer {token}`
- **응답**:
  ```json
  {
    "success": true
  }
  ```

---

## 옷장 관리 (Wardrobe)

### 1. 옷장 아이템 조회 API ✅
- **엔드포인트**: `/api/wardrobe/items`
- **메서드**: GET
- **요청 헤더**: `Authorization: Bearer {token}`
- **쿼리 파라미터**: (선택사항)
  - `category`: 상의(top), 하의(bottom) 등
  - `color`: 색상 필터
  - `page`: 페이지 번호
  - `limit`: 개수 제한
- **응답**:
  ```json
  {
    "items": [
      {
        "id": "string",
        "name": "string",
        "image_url": "string",
        "attributes": {
          "category": {
            "main": "top|bottom|outer|accessory",
            "sub": "string (e.g., T-shirt, Jeans)"
          },
          "color": {
            "primary": "string (hex or name)",
            "secondary": "string (optional)"
          },
          "material": "string (optional)",
          "brand": "string (optional)"
        }
      }
    ],
    "total": "number",
    "page": "number"
  }
  ```

### 2. 아이템 추가 API ✅
- **엔드포인트**: `/api/wardrobe/items`
- **메서드**: POST
- **요청 헤더**: 
  - `Authorization: Bearer {token}`
  - `Content-Type: multipart/form-data`
- **요청 본문**:
  ```
  - image: File (required)
  - name: string (optional)
  - category_main: string (optional)
  - category_sub: string (optional)
  - color: string (optional)
  - attributes: JSON string (optional)
  ```
- **응답**:
  ```json
  {
    "success": true,
    "item": {
      "id": "string",
      "name": "string",
      "image_url": "string",
      "attributes": {}
    }
  }
  ```

### 3. 아이템 상세 조회 API
- **엔드포인트**: `/api/wardrobe/items/{id}`
- **메서드**: GET
- **요청 헤더**: `Authorization: Bearer {token}`
- **응답**: 단일 아이템 객체 (위 아이템 조회 응답의 items 배열 요소와 동일)

### 4. 아이템 수정 API
- **엔드포인트**: `/api/wardrobe/items/{id}`
- **메서드**: PUT
- **요청 헤더**: 
  - `Authorization: Bearer {token}`
  - `Content-Type: application/json` 또는 `multipart/form-data`
- **요청 본문**: 수정할 필드들 (name, attributes 등)
- **응답**: 수정된 아이템 객체

### 5. 아이템 삭제 API
- **엔드포인트**: `/api/wardrobe/items/{id}`
- **메서드**: DELETE
- **요청 헤더**: `Authorization: Bearer {token}`
- **응답**:
  ```json
  {
    "success": true,
    "message": "Item deleted successfully"
  }
  ```

---

## 의류 속성 추출 (Attribute Extraction)

### 1. 이미지 속성 추출 API ✅
- **엔드포인트**: `/api/extract`
- **메서드**: POST
- **요청 헤더**: `Content-Type: multipart/form-data`
- **요청 본문**:
  ```
  - image: File (required)
  ```
- **응답**:
  ```json
  {
    "success": true,
    "attributes": {
      "category": {
        "main": "top|bottom|outer|accessory",
        "sub": "T-shirt|Jeans|Jacket|etc"
      },
      "color": {
        "primary": "string (hex or color name)",
        "secondary": "string (optional)"
      },
      "material": "string (cotton|polyester|wool|etc)",
      "style": "string (casual|formal|sporty|etc)",
      "pattern": "string (solid|striped|checked|etc)",
      "condition": "new|good|worn",
      "confidence": "number (0-100)"
    }
  }
  ```

---

## 의류 추천 (Recommendation)

### 1. 코디 추천 API ✅
- **엔드포인트**: `/api/recommend/outfit`
- **메서드**: GET
- **요청 헤더**: `Authorization: Bearer {token}`
- **쿼리 파라미터**:
  - `count`: 추천 개수 (기본값: 1)
  - `use_gemini`: Gemini AI 사용 여부 (기본값: true)
  - `occasion`: 상황 (casual|formal|sport|date|etc) (선택)
  - `season`: 계절 필터 (선택)
  - `temperature`: 온도 기반 추천 (선택)
- **응답**:
  ```json
  {
    "outfits": [
      {
        "id": "string (optional)",
        "top": {
          "id": "string",
          "name": "string",
          "image_url": "string",
          "attributes": {}
        },
        "bottom": {
          "id": "string",
          "name": "string",
          "image_url": "string",
          "attributes": {}
        },
        "score": "number (0-100)",
        "reasoning": "string (추천 이유 설명)",
        "style_description": "string (코디 스타일 설명)",
        "reasons": [
          "string (추천 이유 목록)"
        ]
      }
    ]
  }
  ```

### 2. 커스텀 추천 API
- **엔드포인트**: `/api/recommend/outfit/custom`
- **메서드**: POST
- **요청 헤더**: 
  - `Authorization: Bearer {token}`
  - `Content-Type: application/json`
- **요청 본문**:
  ```json
  {
    "filters": {
      "color": ["string"],
      "style": "string",
      "occasion": "string",
      "temperature": "number",
      "season": "string"
    },
    "count": "number (기본값: 1)"
  }
  ```
- **응답**: 위의 코디 추천 API 응답과 동일

---

## 사용자 프로필 (User Profile)

### 1. 사용자 프로필 조회 API
- **엔드포인트**: `/api/user/profile`
- **메서드**: GET
- **요청 헤더**: `Authorization: Bearer {token}`
- **응답**:
  ```json
  {
    "id": "string",
    "name": "string (optional)",
    "gender": "male|female",
    "bodyShape": "string (slim|normal|athletic|curvy|etc)",
    "preferredColors": ["string"],
    "preferredStyles": ["string"],
    "createdAt": "ISO 8601 timestamp",
    "updatedAt": "ISO 8601 timestamp"
  }
  ```

### 2. 사용자 프로필 수정 API
- **엔드포인트**: `/api/user/profile`
- **메서드**: PUT
- **요청 헤더**: 
  - `Authorization: Bearer {token}`
  - `Content-Type: application/json`
- **요청 본문**:
  ```json
  {
    "name": "string (optional)",
    "gender": "male|female (optional)",
    "bodyShape": "string (optional)",
    "preferredColors": ["string"] (optional)",
    "preferredStyles": ["string"] (optional)"
  }
  ```
- **응답**: 수정된 프로필 객체 (위 조회 응답과 동일)

---

## 아웃핏/코디 저장 (Saved Outfits)

### 1. 코디 저장 API
- **엔드포인트**: `/api/outfits`
- **메서드**: POST
- **요청 헤더**: 
  - `Authorization: Bearer {token}`
  - `Content-Type: application/json`
- **요청 본문**:
  ```json
  {
    "topId": "string",
    "bottomId": "string",
    "name": "string (optional)",
    "notes": "string (optional)",
    "tags": ["string"] (optional)",
    "occasion": "string (optional)"
  }
  ```
- **응답**:
  ```json
  {
    "success": true,
    "outfit": {
      "id": "string",
      "top": {},
      "bottom": {},
      "name": "string",
      "notes": "string",
      "savedAt": "ISO 8601 timestamp"
    }
  }
  ```

### 2. 저장된 코디 목록 조회 API
- **엔드포인트**: `/api/outfits`
- **메서드**: GET
- **요청 헤더**: `Authorization: Bearer {token}`
- **쿼리 파라미터**:
  - `page`: 페이지 번호
  - `limit`: 개수 제한
  - `occasion`: 상황별 필터
- **응답**:
  ```json
  {
    "outfits": [
      {
        "id": "string",
        "top": {},
        "bottom": {},
        "name": "string",
        "notes": "string",
        "occasion": "string",
        "savedAt": "ISO 8601 timestamp"
      }
    ],
    "total": "number",
    "page": "number"
  }
  ```

### 3. 코디 삭제 API
- **엔드포인트**: `/api/outfits/{id}`
- **메서드**: DELETE
- **요청 헤더**: `Authorization: Bearer {token}`
- **응답**:
  ```json
  {
    "success": true
  }
  ```

---

## 에러 처리

모든 API는 다음과 같은 에러 응답 형식을 따라야 합니다:

```json
{
  "success": false,
  "error": "string (에러 메시지)",
  "code": "string (에러 코드: INVALID_REQUEST|UNAUTHORIZED|NOT_FOUND|SERVER_ERROR|etc)"
}
```

### HTTP 상태 코드
- `200 OK`: 요청 성공
- `201 Created`: 리소스 생성 성공
- `400 Bad Request`: 잘못된 요청
- `401 Unauthorized`: 인증 실패
- `403 Forbidden`: 권한 없음
- `404 Not Found`: 리소스를 찾을 수 없음
- `500 Internal Server Error`: 서버 오류

---

## 구현 상태 요약

| API | 상태 | 비고 |
|-----|------|------|
| 로그인 | ❌ 미구현 | 로컬 더미 데이터 사용 중 |
| 회원가입 | ❌ 미구현 | 로컬 더미 데이터 사용 중 |
| 로그아웃 | ❌ 미구현 | - |
| 옷장 아이템 조회 | ✅ 구현중 | `/api/wardrobe/items` 사용 중 |
| 아이템 추가 | ✅ 구현중 | 이미지 업로드 포함 |
| 아이템 상세 조회 | ❌ 미구현 | - |
| 아이템 수정 | ❌ 미구현 | - |
| 아이템 삭제 | ❌ 미구현 | - |
| 이미지 속성 추출 | ✅ 구현중 | `/api/extract` 사용 중 |
| 코디 추천 | ✅ 구현중 | `/api/recommend/outfit` 사용 중 (Gemini 옵션) |
| 커스텀 추천 | ❌ 미구현 | - |
| 사용자 프로필 조회 | ❌ 미구현 | - |
| 프로필 수정 | ❌ 미구현 | - |
| 코디 저장 | ❌ 미구현 | - |
| 저장된 코디 목록 | ❌ 미구현 | - |
| 코디 삭제 | ❌ 미구현 | - |

---

## 현재 구현된 API 엔드포인트

```
Base URL: http://localhost:5000 (개발환경)

✅ GET  /api/wardrobe/items          - 옷장 아이템 조회
✅ POST /api/extract                 - 이미지 속성 추출
✅ GET  /api/recommend/outfit        - 코디 추천 (Gemini 사용 가능)
```

---

## 개발 우선순위

### Phase 1 (필수)
1. 인증 시스템 (로그인, 회원가입, 토큰 관리)
2. 옷장 CRUD (Create, Read, Update, Delete)
3. 코디 저장/관리

### Phase 2 (권장)
1. 사용자 프로필 시스템
2. 고급 필터링 및 검색
3. 추천 알고리즘 개선

### Phase 3 (추가기능)
1. 소셜 피드
2. 코디 공유
3. 통계 및 분석
