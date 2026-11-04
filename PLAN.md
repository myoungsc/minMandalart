# 미니만다 1.1 작업 계획

작성일 2026-11-05. 기준 커밋 `6f51e36` (브랜치 `feat/keyboard-l10n-store-listing`).
이 문서는 다른 모델이 그대로 실행할 수 있게 쓴 작업 지시서다. 단계 순서대로 진행하고, 단계마다 커밋 하나를 남긴다.

## 공통 규칙 (CLAUDE.md와 같음, 반드시 지킨다)

- 모든 응답과 코드 주석은 한글.
- 작업 시작 전 `comment_last.md`에 `\n## YYYY-MM-DD HH:MM:SS\n- 내용\n` 형식으로 지시 내용을 추가.
- 상태 관리는 riverpod만 쓴다 (`flutter_riverpod` 2.6, `StateNotifier` 패턴이 이미 쓰이고 있으니 같은 패턴 유지).
- 키보드가 뜨는 화면은 `MaterialApp.builder`의 `dismissKeyboardOnTap`이 전체에 적용돼 있다. 이를 막는 `GestureDetector`를 바깥에 두지 않는다.
- 새 문구는 `assets/translations/{en,ko,ja,es,ru,fr}.json` 6개 모두에 추가한다. `test/translations_test.dart`가 키 누락을 잡는다.
- 모든 화면은 `SafeArea(top: false)` 안에 둔다 (AppBar가 위쪽을 처리).
- 각 단계 끝에 `flutter analyze` 이슈 0건, `flutter test` 전체 통과를 확인하고 결과를 그대로 보고한다.
- 키 파일, `.env`, 광고 ID 같은 비밀 값은 저장소에 넣지 않는다. 경로나 변수 이름만 쓴다.
- 스토어 업로드는 사용자가 승인한 뒤에만, 심사 제출은 사용자가 직접 한다.

## 현재 구조 요약

| 위치 | 내용 |
|---|---|
| `lib/core/db/sqlite_helper.dart` | sqflite, DB 버전 3. 테이블 `mandalart_boards`, `goals`, `checklist_items`. `upgrade()`로 마이그레이션. |
| `lib/core/providers/goal_provider.dart` | `databaseProvider`, `mandalartBoardsProvider`(목록), `currentBoardProvider`(열린 보드). 쓰기 후 `_writeAndRefresh`로 둘 다 갱신. |
| `lib/core/providers/settings_provider.dart` | `AppSettings(themeMode)` + `SharedPreferences`. 설정 추가는 여기에 필드를 더한다. |
| `lib/models/goal_model.dart` | `MandalartBoard`, `Goal`, `ChecklistItem`, `GoalStatus`. `toMap`/`fromMap` 있음. |
| `lib/screens/home_screen.dart` | `detailNavigatorKey` 중첩 Navigator. 600dp 이상은 두 패널. 보드 목록 `_BoardListPane`, 카드 `_BoardCard`. |
| `lib/screens/board_screen.dart` | 3x3 보드. `bottomNavigationBar: BottomAction(공유 버튼)`. 보드 삭제 `_deleteBoard` (593행). |
| `lib/screens/cell_sheets.dart` | 셀 편집 시트, 체크리스트, `clearGoal` 호출(153행). |
| `lib/screens/settings_screen.dart` | 테마 선택, 만다라트 소개, 버전(`_appVersion` 상수 하드코딩). |
| `lib/screens/share_screen.dart` | `ShareCard`를 1080px PNG로 만들어 share_plus로 공유. 항상 라이트 팔레트. |
| `lib/core/widgets/mm_widgets.dart` | `PrimaryButton`, `BottomAction`, `MmField`, `MmSheetFrame`, `BackIcon`, `DashedBox`. |
| `test/` | db, models, providers, screens(`app_flow_test.dart`), translations, store_metadata. 총 95개. |
| `fastlane/` | `ios beta`, `ios metadata`, `android build`, `android internal`, `android metadata`. 빌드 번호는 `pubspec.yaml`에서. |

의존성: flutter_riverpod, sqflite, path_provider, path, intl, easy_localization, share_plus, shared_preferences. dev: sqflite_common_ffi, flutter_launcher_icons.

## 단계 순서와 브랜치

| 순서 | 브랜치 | 내용 | 새 의존성 |
|---|---|---|---|
| 1 | `feat/backup-restore` | 백업·복원 (JSON 내보내기/불러오기) | file_picker |
| 2 | `feat/undo-delete` | 삭제 취소 (보드, 셀 비우기) | 없음 |
| 3 | `feat/deadline` | 목표 마감일 | 없음 |
| 4 | `feat/completed-at` | 완료 날짜 기록 + 홈 요약 | 없음 |
| 5 | `feat/reminder` | 하루 한 번 리마인더 알림 | flutter_local_notifications, timezone |
| 6 | `feat/polish` | 버전 자동 표시, 공유 이미지 다크, 첫 실행 예시 보드 | package_info_plus |
| 7 | `feat/ads` | 하단 배너 광고 | google_mobile_ads |
| 8 | `chore/release-1.1` | 개인정보 처리방침, 스토어 메타데이터 갱신, 빌드 번호, TestFlight·Play 내부 테스트 | 없음 |

각 단계는 PR을 만들어 `main`에 합친다. 1~4는 서로 독립이라 순서를 바꿔도 된다. 5는 3에 의존(마감일 알림 문구). 7은 8보다 먼저 끝나야 한다(개인정보 처리방침에 광고 내용이 들어가야 함).

---

## 1단계. 백업·복원

**목표:** 설정 화면에서 전체 보드를 JSON 파일로 내보내고, 파일을 골라 불러온다. 기기 교체와 앱 삭제에 대비한다.

### 파일
- 새 파일 `lib/core/backup/backup_codec.dart`: 순수 Dart. `String encode(List<MandalartBoard>)`, `List<MandalartBoard> decode(String)`. 포맷:
  ```json
  { "app": "miniManda", "format": 1, "exportedAt": "ISO8601", "boards": [ MandalartBoard.toMap() + "goals": [ Goal.toMap() + "checklist": [ChecklistItem.toMap()] ] ] }
  ```
  `format`이 1이 아니거나 `app`이 다르면 `FormatException`을 던진다. id는 내보내되 불러올 때는 무시한다(새 id 발급).
- `lib/core/db/sqlite_helper.dart`: `Future<void> importBoards(List<MandalartBoard> boards, {required bool replace})` 추가. 한 트랜잭션 안에서 `replace`면 세 테이블을 비우고, 보드 → goals → checklist_items 순으로 insert. 기존 `createBoardWithEmptyGoals`와 달리 goals를 데이터대로 넣는다.
- `lib/core/providers/goal_provider.dart`: `MandalartBoardsNotifier`에 `exportJson()`(DB에서 전체 읽어 encode)과 `importJson(String, {required bool replace})` 추가. import 후 `loadBoards()`.
- 새 파일 `lib/screens/backup_screen.dart`: 설정 → "백업과 복원" 행에서 진입. 두 버튼.
  - **내보내기:** `path_provider` 임시 폴더에 `minimanda_backup_YYYYMMDD.json` 저장 후 `SharePlus.instance.share(ShareParams(files: [...]))`. iPad용 `sharePositionOrigin`은 `share_screen.dart`의 `_share()`를 그대로 따른다.
  - **불러오기:** `file_picker`로 `.json` 선택 → decode → 보드 수를 보여 주는 확인 다이얼로그("기존 N개를 지우고 교체" / "기존 것에 추가" / 취소) → import → 스낵바.
  - 실패는 모두 `common.error` 스낵바.
- `lib/screens/settings_screen.dart`: `settings.info_section` 위에 `settings.data_section` 그룹 추가, 행 `settings.backup`.
- `pubspec.yaml`: `file_picker` 추가 (최신 안정 버전, `flutter pub add file_picker`).
- 번역 키: `settings.data_section`, `settings.backup`, `backup.title`, `backup.export`, `backup.import`, `backup.export_hint`, `backup.import_confirm_title`, `backup.import_confirm_body` ({count}), `backup.import_replace`, `backup.import_merge`, `backup.import_done` ({count}), `backup.invalid_file`.

### 테스트
- `test/backup/backup_codec_test.dart`: encode → decode 왕복이 같은 값, 체크리스트 포함, 잘못된 포맷은 `FormatException`.
- `test/db/sqlite_helper_test.dart`에 `importBoards` replace/merge 두 케이스 추가(sqflite_common_ffi 사용, 기존 테스트 패턴 따름).
- `test/screens/app_flow_test.dart`에 설정 → 백업 화면 진입 테스트 1개.

### 완료 기준
- 시뮬레이터에서 내보내기 → 파일 앱에 저장 → 앱 삭제 후 재설치 → 불러오기로 보드와 체크리스트 상태가 그대로 복원된다.
- iOS: `file_picker`는 추가 Info.plist 키가 없어도 동작한다. Android: 권한 불필요(SAF 사용). 둘 다 확인하고 보고.

---

## 2단계. 삭제 취소

**목표:** 보드 삭제와 셀 비우기 뒤 스낵바에 "되돌리기"를 5초 보여 준다.

### 방법
- DB에서 바로 지우지 않고, 지운 데이터를 메모리에 들고 있다가 스낵바가 닫히면 그대로 둔다. 되돌리기를 누르면 다시 insert한다. 실제 삭제는 이미 됐으므로 "되돌리기 = 재삽입"이다. 가장 단순한 구현이고 앱 종료 시 유실 걱정이 없다.
- `goal_provider.dart`:
  - `MandalartBoardsNotifier.deleteBoard`는 삭제 전 `readMandalartBoard(id)`로 전체 스냅샷을 반환값으로 돌려준다. `Future<MandalartBoard?> deleteBoard(int id)`.
  - `restoreBoard(MandalartBoard)`: 1단계의 `importBoards([board], replace: false)`를 재사용. (1단계 전에 하면 여기서 `importBoards`를 먼저 만든다.)
  - `CurrentBoardNotifier.clearGoal`은 비우기 전 `Goal` 스냅샷(체크리스트 포함)을 반환. `restoreGoal(Goal)`: `updateGoal` + 체크리스트 재삽입. `sqlite_helper.dart`에 `restoreGoal(Goal)` 트랜잭션 추가.
- UI: `board_screen.dart` `_deleteBoard`(593행)와 `cell_sheets.dart` 153행에서 `ScaffoldMessenger`에 `SnackBarAction(label: 'common.undo'.tr())`. 기존 확인 다이얼로그는 유지해도 되지만, 되돌리기가 있으면 다이얼로그는 빼는 것을 권한다(사용자에게 확인받고 결정).
- 번역 키: `common.undo`, `board.deleted` , `cell.cleared`.

### 테스트
- `test/providers/goal_provider_test.dart`: deleteBoard → restoreBoard 후 목록에 같은 내용(새 id)으로 존재. clearGoal → restoreGoal 후 제목·체크리스트 복원.

---

## 3단계. 목표 마감일

**목표:** 셀(부속 목표)에 날짜 하나를 선택할 수 있고, 보드에 남은 일수(또는 지난 일수)를 보여 준다.

### 파일
- `goal_model.dart`: `Goal`에 `DateTime? dueDate` 추가. `toMap`/`fromMap`/`copyWith` 반영. `int? get daysLeft` (오늘 기준, 날짜 단위 비교).
- `sqlite_helper.dart`: DB 버전 4. `upgrade()`에 `ALTER TABLE goals ADD COLUMN due_date TEXT`. `_createDB`에도 컬럼 추가. `updateGoalText`와 비슷한 `setGoalDueDate(int goalId, DateTime?)` 추가.
- `goal_provider.dart`: `CurrentBoardNotifier.setGoalDueDate`.
- `cell_sheets.dart`: 편집 시트에 "마감일" 행 추가. `showDatePicker`(기본 위젯, 새 의존성 없음) 사용, 선택 해제 버튼 포함. 날짜 표시는 `intl`의 `DateFormat.yMMMd(context.locale.toString())`.
- `board_screen.dart` `BoardCell`: dueDate가 있으면 셀 하단 상태 줄에 작은 글씨로 `D-7` 형태. 지났고 미완료면 `c.accent`가 아닌 경고색(테마에 `MmColors.warn`이 없으면 추가). 완료된 셀은 표시 안 함.
- `share_screen.dart` `ShareCard._cell`: 같은 표시를 넣되 공간이 좁으면 생략 가능. 1080px 결과물에서 글자가 잘리지 않는지 확인.
- 번역 키: `cell.due_date`, `cell.due_date_none`, `cell.due_clear`, `board.days_left` ({days}), `board.days_over` ({days}), `board.due_today`.

### 테스트
- `test/models/goal_model_test.dart`: dueDate 직렬화 왕복, `daysLeft` 경계(오늘=0, 내일=1, 어제=-1).
- `test/db/sqlite_helper_test.dart`: 버전 3 → 4 마이그레이션 후 기존 데이터 유지, 컬럼 존재.
- `app_flow_test.dart`: 날짜 선택 후 셀에 `D-` 문구 표시.

---

## 4단계. 완료 날짜 기록 + 홈 요약

**목표:** 셀과 체크리스트가 완료된 시각을 저장하고, 홈 상단에 "이번 달 완료 N개"를 보여 준다.

### 파일
- `goal_model.dart`: `Goal.completedAt`, `ChecklistItem.completedAt` (`DateTime?`).
- `sqlite_helper.dart`: DB 버전 5. `ALTER TABLE goals ADD COLUMN completed_at TEXT`, `ALTER TABLE checklist_items ADD COLUMN completed_at TEXT`. `setGoalCompleted`, `setChecklistItemDone`, `_syncGoalProgress`에서 완료로 바뀌는 순간 `DateTime.now()`를 넣고, 해제되면 null. 이미 완료 상태인데 다시 완료 호출되면 덮어쓰지 않는다.
- `sqlite_helper.dart`: `Future<int> countCompletedSince(DateTime from)` (goals + checklist_items 합).
- `goal_provider.dart`: `monthlyCompletedProvider = FutureProvider<int>` (이달 1일 기준). `_writeAndRefresh`에서 `ref.invalidate(monthlyCompletedProvider)`.
- `home_screen.dart` `_BoardListPane`: 목록 위에 한 줄 요약 타일. 0이면 숨긴다.
- 번역 키: `home.monthly_done` ({count}).

### 테스트
- db 테스트: 완료 → completed_at 기록, 해제 → null, 재완료 시 기존 값 유지, `countCompletedSince`.
- 마이그레이션 4 → 5.

---

## 5단계. 리마인더 알림

**목표:** 설정에서 켜면 매일 지정한 시각에 "오늘 목표 확인" 로컬 알림. 마감 하루 전 알림은 이번에 넣지 않는다(다음 버전).

### 파일
- `pubspec.yaml`: `flutter_local_notifications`, `timezone` 추가. (`flutter_timezone`은 넣지 않는다. `timezone` 패키지의 `tz.local`로 충분하며, 매일 반복은 `zonedSchedule` + `matchDateTimeComponents: DateTimeComponents.time`.)
- 새 파일 `lib/core/notifications/reminder_service.dart`: `init()`, `schedule(TimeOfDay)`, `cancel()`. 알림 id 고정 1개.
- `settings_provider.dart`: `AppSettings`에 `reminderEnabled`(bool), `reminderTime`(TimeOfDay, 기본 21:00) 추가, SharedPreferences 키 `reminder_enabled`, `reminder_minutes`. `setReminder(bool, TimeOfDay)`에서 서비스 호출.
- `settings_screen.dart`: 테마 그룹 아래 "알림" 그룹. 스위치 행 + 시각 행(`showTimePicker`). 권한 거부 시 스위치를 되돌리고 안내 스낵바.
- `main.dart`: `ReminderService.init()`을 `runApp` 전에 호출.
- 플랫폼 설정:
  - Android: `AndroidManifest.xml`에 `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM` 대신 `USE_EXACT_ALARM`은 쓰지 말고 **비정확 알람**(`AndroidScheduleMode.inexactAllowWhileIdle`)을 쓴다. 정확 알람 권한은 Play 정책상 설명이 필요하다. `RECEIVE_BOOT_COMPLETED` 리시버 추가(패키지 README대로).
  - iOS: `AppDelegate.swift`에 `UNUserNotificationCenter.current().delegate` 설정(패키지 README대로). 권한 요청은 스위치를 켤 때만.
- 알림 본문은 기기 언어로: 알림을 예약하는 시점의 `context.locale` 문구를 저장. 언어를 바꾸면 다음 저장 때 갱신된다(이 한계는 주석으로 남긴다).
- 번역 키: `settings.reminder_section`, `settings.reminder_enabled`, `settings.reminder_time`, `settings.reminder_denied`, `reminder.title`, `reminder.body`.

### 테스트
- `settings_provider_test.dart`: 저장·복원, 기본값 21:00.
- 알림 자체는 위젯 테스트로 못 하므로 `ReminderService`를 인터페이스 없이 생성자 주입만 받게 두고(`FlutterLocalNotificationsPlugin` 주입), 테스트에서 `setMockMethodCallHandler`로 예약 호출 1회를 확인하는 테스트 1개.
- 실기기 확인 필수: Android 13+ 권한 다이얼로그, iOS 권한 다이얼로그, 시각 변경 후 재예약.

---

## 6단계. 작은 다듬기

### 6-1 버전 자동 표시
- `pubspec.yaml`: `package_info_plus`.
- `settings_screen.dart`: `_appVersion` 상수 삭제. `appVersionProvider = FutureProvider<String>`로 `PackageInfo.fromPlatform()` 읽어 `"1.1.0 (4)"` 형태 표시. 로딩 중은 빈 문자열.
- 테스트: `PackageInfo.setMockInitialValues`로 표시 확인 1개. 기존 `app_flow_test.dart`에서 `1.0.0` 문자열을 찾는 테스트가 있으면 수정.

### 6-2 공유 이미지 다크 버전
- `share_screen.dart`: 미리보기 위에 세그먼트 두 개(밝게 / 어둡게). 기본은 현재 앱 테마에 따른다. `ShareCard`의 `static const _c = MmColors.light`를 생성자 파라미터 `MmColors colors`로 바꾼다. `Theme(data: AppTheme.lightTheme ...)`로 감싼 `DashedBox`도 선택한 테마를 따른다.
- 선택을 바꾸면 `_generate()`를 다시 호출. 생성 중에는 세그먼트 비활성.
- 번역 키: `share.style_light`, `share.style_dark`.
- 테스트: 어둡게 선택 후 `ShareCard`의 배경색이 `MmColors.dark.bg`.

### 6-3 첫 실행 예시 보드
- `settings_provider.dart` 또는 별도 SharedPreferences 키 `sample_board_seeded`. 첫 실행이고 보드가 0개면 예시 보드 1개를 생성(제목 `sample.center`, 부속 목표 8개 `sample.goal_1`~`sample.goal_8`, 체크리스트 2~3개, 일부 완료 상태). 문구는 현재 언어로 넣는다(저장 뒤에는 번역되지 않는 데이터이므로).
- 예시 보드는 보통 보드와 똑같이 지울 수 있다. 홈 `_HomeEmpty`는 그대로 유지(예시를 지운 뒤 보이는 화면).
- 생성 위치: `main.dart`에서 `ProviderScope` 생성 후, 앱 첫 프레임 전에 `mandalartBoardsProvider.notifier`로 수행. 이미 DB에 보드가 있는 기존 사용자에겐 만들지 않는다.
- 번역 키: `sample.center`, `sample.goal_1`~`sample.goal_8`, `sample.check_1`~`sample.check_3`.
- 테스트: 빈 DB + 플래그 없음 → 보드 1개 생성. 플래그 있음 → 생성 안 함. 보드 있음 → 생성 안 함.

---

## 7단계. 하단 배너 광고

**목표:** 홈(보드 목록)과 보드 화면 하단에 AdMob 앵커 적응형 배너를 넣는다. 셀 편집 시트, 공유 화면, 설정, 새 보드 화면에는 넣지 않는다(키보드와 겹치고 작업을 방해함).

### 사용자에게 먼저 받아야 하는 값 (없으면 이 단계 시작 불가)
- AdMob **앱 ID** iOS, Android 각 1개 (`ca-app-pub-XXXX~YYYY`).
- AdMob **배너 광고 단위 ID** iOS, Android 각 1개 (`ca-app-pub-XXXX/ZZZZ`).
- 값은 저장소에 넣지 않는다. 아래 "비밀 값 전달 방식"을 따른다.

### 비밀 값 전달 방식
- 앱 ID는 네이티브 설정 파일에 들어가야 하므로 완전히 숨길 수 없다. 광고 ID는 비밀 키가 아니라 공개 식별자이므로 저장소에 들어가도 보안 문제는 없다. 다만 사용자 규칙에 따라 **`--dart-define`으로 주입**하고 기본값은 Google 테스트 ID로 둔다.
  - Dart: `const bannerUnitId = String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: <플랫폼별 테스트 ID>)`. 플랫폼별 테스트 ID는 google_mobile_ads 문서의 공식 테스트 배너 ID를 쓴다(문서에서 확인 후 기입, 외워서 쓰지 않는다).
  - Android 앱 ID: `android/app/build.gradle.kts`에 `manifestPlaceholders["admobAppId"]`를 `~/.appstore/miniManda-key.properties`와 같은 방식으로 `~/.appstore/miniManda-admob.properties`에서 읽는다. 파일이 없으면 Google 테스트 앱 ID. `AndroidManifest.xml`에 `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="${admobAppId}"/>`.
  - iOS 앱 ID: `ios/Runner/Info.plist`의 `GADApplicationIdentifier`는 `$(ADMOB_APP_ID)` 빌드 설정으로 두고, `ios/Flutter/AdMob.xcconfig`(gitignore)에서 값을 읽는다. `Debug.xcconfig`/`Release.xcconfig`에 `#include? "AdMob.xcconfig"`. 없으면 테스트 앱 ID가 기본이 되도록 `Generated.xcconfig` 뒤에 기본값 포함.
  - `fastlane/Fastfile`의 `ios beta`, `android build`에 `--dart-define=ADMOB_BANNER_ID=...`를 `.env`에서 읽어 넘긴다. `.env.example`에 변수 이름만 추가: `ADMOB_BANNER_ID_IOS`, `ADMOB_BANNER_ID_ANDROID`.
  - `.gitignore`: `ios/Flutter/AdMob.xcconfig`.

### 파일
- `pubspec.yaml`: `google_mobile_ads` (최신 안정 버전). iOS 최소 버전 15.0은 충족. Android minSdk는 `flutter.minSdkVersion`(현재 Flutter 3.47 기준 24)이므로 google_mobile_ads 요구 사항을 충족한다. 패키지 문서의 최소 버전이 24보다 높으면 보고한다.
- `main.dart`: `MobileAds.instance.initialize()`는 `runApp` 뒤에 비동기로 호출(첫 프레임을 막지 않게).
- 새 파일 `lib/core/ads/ad_banner.dart`: `AdBanner` 위젯.
  - `AnchoredAdaptiveBannerAdSize`를 화면 폭으로 계산. 두 패널(600dp 이상)에서는 **오른쪽 패널 폭이 아닌 전체 창 폭**으로 홈 Scaffold 하단에 하나만 둔다.
  - 로드 실패 시 높이 0 (`SizedBox.shrink`), 레이아웃이 튀지 않게 로드 전에도 예상 높이를 미리 확보.
  - `dispose`에서 `ad.dispose()`.
  - 광고 영역은 `SafeArea(top: false)` 안.
- 배치:
  - `home_screen.dart`: `_DetailRoot`의 Scaffold(98행, 113행 두 곳)에서 `bottomNavigationBar: AdBanner()`. 두 패널 모드에서는 바깥 Scaffold에 한 번만.
  - `board_screen.dart`: 기존 `BottomAction(공유 버튼)` 아래에 배너. `bottomNavigationBar: Column(mainAxisSize: min, children: [BottomAction(...), AdBanner()])`. 단, 홈이 두 패널일 때 보드는 홈 Scaffold 안에 있으므로 중복 표시가 된다. **두 패널에서는 보드 화면에 배너를 넣지 않는다** (`MediaQuery.sizeOf(context).width >= 600`이면 생략, 기준값은 `home_screen.dart`의 분기 상수를 재사용).
- 동의와 추적:
  - **UMP(User Messaging Platform) 동의 폼**: `google_mobile_ads`에 포함된 `ConsentInformation`으로 앱 시작 시 `requestConsentInfoUpdate` → 필요하면 `loadAndShowConsentFormIfRequired`. EU 사용자(es, fr 지원 중) 대응. AdMob 콘솔에서 GDPR 메시지를 만들어 두어야 한다(사용자 작업, 보고 시 안내).
  - **iOS ATT**: 개인화 광고를 하려면 `app_tracking_transparency` 패키지와 `NSUserTrackingUsageDescription`이 필요하다. **이번에는 비개인화 광고만 요청**(`AdRequest(nonPersonalizedAds: true)`)하고 ATT는 넣지 않는다. 수익은 낮지만 심사 항목이 줄어든다. 추적을 원하면 다음 버전에서 추가.
  - iOS `Info.plist`에 `SKAdNetworkItems` 목록 추가 (Google 문서의 최신 목록을 그대로 복사, 외워서 쓰지 않는다).
- 광고 없는 선택지: 유료 제거는 이번 범위 밖. 설정에 넣지 않는다.

### 테스트
- `AdBanner`는 플러그인 없이 위젯 테스트가 안 되므로, `adsEnabledProvider = Provider<bool>((_) => true)`를 두고 테스트에서 `false`로 override. 기존 `app_flow_test.dart` 전부에 override 추가. `false`면 `SizedBox.shrink`.
- 실기기(또는 시뮬레이터)에서 테스트 광고 ID로 배너가 뜨는 것, 폰 세로/가로, 600dp 이상 두 패널에서 하나만 보이는 것, 보드 화면에서 공유 버튼이 배너 위에 정상 위치하는 것을 스크린샷으로 확인하고 보고.

### 스토어 영향 (8단계에서 처리)
- App Store 개인정보 라벨: "데이터 수집 안 함" → 광고 SDK가 수집하는 항목(기기 ID, 광고 데이터, 대략적 위치 등)으로 변경. Google 문서의 AdMob 데이터 공개 가이드를 따른다.
- Play 데이터 보안 양식: 같은 내용.
- 개인정보 처리방침에 AdMob 사용과 Google 정책 링크 명시.

---

## 8단계. 출시 준비 1.1

### 8-1 개인정보 처리방침과 지원 페이지
- 저장소 `docs/` 폴더에 `privacy.html`(한/영 병기), `support.html`을 만들어 GitHub Pages로 공개. 저장소 Settings → Pages → `main` 브랜치 `/docs`는 사용자가 직접 설정(안내).
- 내용: 저장되는 데이터(기기 내 SQLite, 서버 전송 없음), 백업 파일은 사용자가 직접 공유, 알림 권한 용도, AdMob 광고와 수집 항목, 문의 이메일(사용자가 지정), 개정일.
- URL 형식 예: `https://<github-id>.github.io/<repo>/privacy.html`. 사용자에게 확인받은 뒤 아래 메타데이터에 넣는다.

### 8-2 스토어 메타데이터
- `fastlane/metadata/ios/*/release_notes.txt`, `fastlane/metadata/android/*/changelogs/default.txt`: 1.1 변경 사항(백업, 되돌리기, 마감일, 알림, 광고 안내) 6개 언어.
- `fastlane/metadata/ios/*/description.txt`, `android/*/full_description.txt`: 새 기능 문단 추가. `test/store_metadata_test.dart` 통과 확인.
- `fastlane/metadata/ios/{locale}/privacy_url.txt`, `support_url.txt` 추가. Play는 콘솔에서 사용자가 직접 입력.
- 스크린샷: 아직 자동화 없음. 사용자가 원하면 `screenshots` 레인은 별도 작업.

### 8-3 빌드와 배포
- `pubspec.yaml`: `version: 1.1.0+4`.
- `flutter analyze` 0건, `flutter test` 전체 통과, `flutter build ios --release --no-codesign`, `flutter build appbundle --release` 성공 확인.
- `fastlane ios beta` → TestFlight 처리 상태 `VALID` 확인 (업로드 전 사용자 승인).
- `fastlane android internal` → Play 내부 테스트 트랙 (업로드 전 사용자 승인).
- 심사 제출은 하지 않는다.
- `fastlane ios metadata`, `fastlane android metadata`는 사용자가 문구를 읽고 승인한 뒤에만.

---

## 사용자가 결정하거나 제공해야 하는 것 (한 번에 물어볼 것)

1. AdMob 앱 ID 2개, 배너 광고 단위 ID 2개.
2. 개인정보 처리방침 문의 이메일, GitHub Pages 사용 여부.
3. 삭제 확인 다이얼로그를 되돌리기로 대체할지(2단계).
4. 리마인더 기본 시각 21:00 유지 여부(5단계).
5. 광고를 비개인화로만 시작하는 것에 동의하는지(7단계).
6. 각 단계 PR을 바로 `main`에 합칠지, 모아서 합칠지.

## 범위에서 뺀 것과 이유

- 마감 하루 전 알림: 알림 수가 늘어 권한 관리가 복잡해진다. 1.2에서.
- 클라우드 동기화(iCloud, Drive): 계정과 충돌 처리가 필요. JSON 백업으로 대체.
- 광고 제거 인앱 결제: 결제 심사 항목이 추가된다. 광고 반응을 보고 결정.
- 인앱 언어 선택: 시스템 설정으로 충분(Android 13+ 앱별 언어 등록 완료).
