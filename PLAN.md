# 미니만다 기능 추가 계획 (1.1 ~ 1.3)

작성일 2026-11-18. 기준: 브랜치 `feat/ads` (버전 `1.0.1+4`, 광고 포함, 테스트 95개 통과).
이 문서는 다른 모델이 **한 단계씩** 그대로 실행할 수 있게 쓴 작업 지시서다. 한 단계 = 브랜치 하나 = 워크트리 하나 = PR 하나.

## 다른 모델에게 주는 시작 지시문 (N만 바꿔서 그대로 붙여넣기)

```
PLAN.md를 읽고 N단계만 실행해줘. 다른 단계는 건드리지 마.
1. "워크트리 만들기" 절대로 워크트리와 브랜치를 만들고 그 안에서만 작업해.
2. 시작 전에 그 단계의 "선행 조건"을 확인하고, 맞지 않으면 작업하지 말고 보고해.
3. "공통 규칙"을 지켜. 특히 기존 파일에 dart format을 돌리지 마.
4. 끝나면 flutter analyze 0건, flutter test 전체 통과를 확인하고 커밋·푸시한 뒤 main으로 PR을 만들어. 병합은 내가 한다.
5. "완료 보고 형식"대로 보고해.
키 파일, .env, 광고 ID는 읽거나 출력하거나 저장소에 넣지 마. 스토어 업로드와 심사 제출은 하지 마.
```

## 0단계. 준비 (사용자 또는 메인 세션이 한 번만)

- [ ] `feat/ads`를 `main`에 병합한다 (PR). `feat/ads`는 `feat/keyboard-l10n-store-listing`을 포함하므로 이 PR 하나면 된다.
- [x] `.gitattributes`에 `comment_last.md merge=union` 추가 (여러 브랜치가 이 파일 끝에 줄을 더해도 충돌하지 않게).
- 0단계가 끝나기 전에는 어떤 단계도 시작하지 않는다. 모든 워크트리는 `origin/main`에서 만든다.

## 워크트리 만들기

```
cd ~/Documents/project/flutter/mandalart
git fetch origin
git worktree add ../mandalart-wt/<이름> -b <브랜치> origin/main
cd ../mandalart-wt/<이름>
flutter pub get
```

- `<이름>`과 `<브랜치>`는 아래 "단계 한눈에 보기" 표의 값을 쓴다. 예: `../mandalart-wt/backup-restore`, `feat/backup-restore`.
- 워크트리에는 저장소에서 제외된 파일(`fastlane/.env`, `ios/Flutter/AdMob.xcconfig`)이 없다. 그래서 워크트리 빌드는 **Google 테스트 광고**로 동작한다. 정상이다. 이 파일들을 복사하거나 만들지 않는다.
- 출시용 빌드와 fastlane 업로드 레인은 워크트리에서 실행하지 않는다.
- PR이 병합되면 사용자가 `git worktree remove ../mandalart-wt/<이름>`으로 지운다.

## 단계 한눈에 보기

| 단계 | 브랜치 (워크트리 이름은 `feat/` 뒤) | 내용 | DB 버전 | 새 의존성 | 선행 단계 |
|---|---|---|---|---|---|
| 1 | `feat/backup-restore` | 백업·복원 | 변경 없음 | file_picker | 0 |
| 2 | `feat/undo-delete` | 삭제 되돌리기 | 변경 없음 | 없음 | 1 |
| 3 | `feat/deadline` | 세부 목표 마감일 | 3 → **4** | 없음 | 0 |
| 4 | `feat/completed-at` | 완료 날짜 기록, 홈 요약 | 4 → **5** | 없음 | 3 |
| 5 | `feat/reminder` | 하루 한 번 알림 | 변경 없음 | flutter_local_notifications, timezone, flutter_timezone | 0 |
| 6 | `feat/polish` | 버전 자동 표시, 공유 이미지 다크 | 변경 없음 | package_info_plus | 0 |
| R1 | `chore/release-1.1` | 1.1.0 출시 준비 | | | 1~6 |
| 7 | `feat/templates` | 목표 템플릿 | 변경 없음 | 없음 | 1 |
| 8 | `feat/celebrate` | 8칸 완료 축하 | 변경 없음 | 없음 | 0 |
| 9 | `feat/board-manage` | 맨 위로 이동, 보관함, 복제 | 5 → **6** | 없음 | 4, 1 |
| 10 | `feat/board-color` | 보드 강조색 | 6 → **7** | 없음 | 9 |
| R2 | `chore/release-1.2` | 1.2.0 출시 준비 | | | 7~10 |
| 11 | `feat/expand-81` | 칸을 3×3으로 펼치기 (최대 81칸) | 7 → **8** | 없음 | 10, 2 |
| 12 | `feat/home-widget` | 홈 화면 위젯 | 변경 없음 | home_widget | R2 |
| 13 | `feat/remove-ads` | 광고 제거 인앱 결제 | 변경 없음 | in_app_purchase | R2 |
| R3 | `chore/release-1.3` | 1.3.0 출시 준비 | | | 11~13 |

**동시에 진행해도 되는 묶음** (같은 묶음 안에서는 워크트리를 여러 개 띄워도 된다):
- 묶음 A: 1, 3, 5, 6 → 그 뒤 2(1 병합 후), 4(3 병합 후)
- 묶음 B: 7, 8, 9 → 그 뒤 10(9 병합 후)
- 묶음 C: 11 → 그 뒤 12, 13

**DB 버전은 위 표의 번호로 고정한다.** DB를 바꾸는 단계는 시작할 때 `lib/core/db/sqlite_helper.dart`의 `version:` 값이 "내 버전 - 1"인지 확인한다. 다르면 선행 단계가 병합되지 않은 것이니 멈추고 보고한다.

## 공통 규칙 (반드시 지킨다)

**CLAUDE.md 규칙**
- 모든 응답과 코드 주석은 한글. 작업 리스트를 만들어 보여 주면서 진행한다.
- 작업 시작 전 `comment_last.md` 끝에 `\n## YYYY-MM-DD HH:MM:SS\n- 내용\n` 형식으로 지시 내용을 추가한다.
- 상태 관리는 riverpod만 쓴다 (`flutter_riverpod` 2.6, 기존 `StateNotifier` 패턴 유지).
- 키보드가 뜨는 화면은 `MaterialApp.builder`의 `dismissKeyboardOnTap`이 전체에 적용돼 있다. 이를 막는 `GestureDetector`를 바깥에 두지 않는다.

**코드**
- **기존 파일에 `dart format`을 돌리지 않는다.** 저장소가 포매터 기준과 달라 무관한 줄이 대량으로 바뀐다. 바꾼 줄만 주변 코드 모양에 맞춘다. 새로 만든 파일은 포매팅해도 된다.
- 새 문구는 `assets/translations/{en,ko,ja,es,ru,fr}.json` 6개 모두에 추가한다. `test/translations_test.dart`가 키와 `{변수}` 누락을 잡는다.
- 화면 본문은 `SafeArea(top: false)` 안에 둔다. 기존 위젯(`PrimaryButton`, `BottomAction`, `MmField`, `MmSheetFrame`, `showConfirmDialog`, `showMmSnack`, `context.mm` 색상)을 먼저 찾아 쓴다. 새 디자인 요소를 만들지 않는다.
- 새 의존성은 표에 적힌 것만 추가한다 (`flutter pub add <이름>`, 최신 안정 버전). API는 외워서 쓰지 말고 설치된 패키지의 README와 example을 확인한다.
- 모델에 필드를 추가하면 `toMap`/`fromMap`/`copyWith`를 함께 고치고, `fromMap`은 **그 키가 없어도**(옛 백업 파일) 동작해야 한다.
- 광고: 새 화면에 배너나 전면 광고를 추가하지 않는다. 광고 위치는 홈 목록 배너, 보드 배너, 새 보드 생성 뒤 전면 광고로 고정이다. `lib/core/ads/ads.dart`는 13단계만 고친다.
- 광고 외에 네트워크 요청, 분석 도구, 추적 도구를 넣지 않는다.

**테스트**
- 위젯 테스트의 `ProviderContainer`에는 `adsEnabledProvider.overrideWithValue(false)`가 있어야 한다 (`test/screens/app_flow_test.dart`의 `pumpApp` 참고).
- `test/screens/app_flow_test.dart`의 `_FakeDb implements SQLiteHelper`는 `SQLiteHelper`에 메서드를 추가하면 같이 구현해야 컴파일된다.
- DB 테스트는 `test/db/sqlite_helper_test.dart`의 기존 패턴(sqflite_common_ffi, 메모리 DB)을 따른다. DB 버전을 올리는 단계는 "이전 버전 → 새 버전 마이그레이션 후 기존 데이터 유지" 테스트를 반드시 넣는다.
- 각 단계 끝에 `flutter analyze` 이슈 0건, `flutter test` 전체 통과.

**건드리지 않는 것**
- `pubspec.yaml`의 `version:`, `fastlane/metadata/**`, `docs/privacy-policy.md`, `docs/support.md`: 출시 준비 단계(R1~R3)만 고친다.
- `fastlane/.env`, `ios/Flutter/AdMob.xcconfig`, `~/.appstore/**`: 읽지도 출력하지도 않는다.
- 업로드 레인(`fastlane ios beta`, `ios metadata`, `ios screenshots`, `android internal`, `android metadata`, `android changelogs`, `android images`, `android screenshots`)은 실행하지 않는다.
- PR은 만들되 병합하지 않는다.

**충돌이 나면**
- 다른 단계가 먼저 병합돼 PR이 충돌하면 `git fetch origin && git rebase origin/main`으로 맞춘다. 번역 JSON과 `settings_screen.dart`는 양쪽 추가분을 모두 남긴다. 그 뒤 analyze와 test를 다시 돌린다.

## 완료 보고 형식

```
## N단계 완료 보고
- 브랜치 / PR 링크:
- 바뀐 파일:
- flutter analyze: (결과 그대로)
- flutter test: (통과 수 / 전체)
- 직접 확인한 것: (시뮬레이터·에뮬레이터에서 본 것, 스크린샷 경로)
- 확인하지 못한 것:
- 계획과 다르게 한 것과 이유:
- 스토어 영향: (새 권한, 새 SDK, 개인정보 답변 변화. 없으면 "없음")
```

## 현재 구조 요약

| 위치 | 내용 |
|---|---|
| `lib/core/db/sqlite_helper.dart` | sqflite, DB 버전 3. 테이블 `mandalart_boards`, `goals`(보드당 position 0~7 고정 8개), `checklist_items`. 외래 키 `ON DELETE CASCADE`. 마이그레이션은 `static upgrade()`. |
| `lib/core/providers/goal_provider.dart` | `databaseProvider`, `mandalartBoardsProvider`(목록, 체크리스트 미포함), `currentBoardProvider`(열린 보드, 체크리스트 포함). 쓰기는 `_writeAndRefresh`로 둘 다 갱신. |
| `lib/core/providers/settings_provider.dart` | `AppSettings(themeMode)` + `SharedPreferences`. 설정 추가는 여기에 필드를 더한다. |
| `lib/models/goal_model.dart` | `MandalartBoard`, `Goal`, `ChecklistItem`, `GoalStatus`. `ChecklistItem`에는 `toMap`이 없다. |
| `lib/core/ads/ads.dart` | `adsEnabledProvider`, `adsReadyProvider`, `AdUnit`, `AdBanner`(Scaffold.bottomNavigationBar용), `loadInterstitial`. |
| `lib/screens/home_screen.dart` | `detailNavigatorKey` 중첩 Navigator. 폭 600 이상은 두 패널(`isTwoPane`). 목록 `_BoardListPane`(2열 `Wrap`), 카드 `_BoardCard`, `MiniBoard`. |
| `lib/screens/board_screen.dart` | 3×3 보드, `BoardCell`. 메뉴 `_showBoardMenu`, `showCardMenu`, 삭제 `_deleteBoard`. |
| `lib/screens/cell_sheets.dart` | 칸 편집 시트 `_CellSheet`(체크리스트, 완료 토글, `_clear`), 핵심 목표 시트 `_CenterSheet`. |
| `lib/screens/new_board_screen.dart` | 새 보드. `_create()`에서 `createBoardWithEmptyGoals` 후 `BoardScreen`으로 교체, 전면 광고 표시. |
| `lib/screens/settings_screen.dart` | `_SectionLabel`, `_Group`, `_Row`로 구성. 버전은 `_appVersion` 상수. |
| `lib/screens/share_screen.dart` | `ShareCard`를 PNG로 만들어 share_plus로 공유. `static const _c = MmColors.light` 고정. |
| `lib/core/widgets/mm_widgets.dart` | `PrimaryButton`, `BottomAction`, `MmField`, `showConfirmDialog`, `showMmSnack`, `MmSheetFrame`, `BackIcon`, `DashedBox`. |
| `test/` | db, models, providers, screens(`app_flow_test.dart`), translations, store_metadata. 총 95개. |

플랫폼: iOS 15.0 이상, Android minSdk는 Flutter 기본값(24), Flutter 3.47.

---

# 1.1 — 기본기

## 1단계. 백업·복원 (`feat/backup-restore`)

**목표:** 설정에서 전체 보드를 JSON 파일로 내보내고, 파일을 골라 불러온다.
**선행 조건:** 0단계 완료.

### 구현
- `lib/models/goal_model.dart`: `ChecklistItem.toMap()` 추가 (`id`, `goal_id`, `title`, `is_done`, `position`, `created_at`).
- 새 파일 `lib/core/backup/backup_codec.dart` (순수 Dart, Flutter import 없음):
  - `String encodeBackup(List<MandalartBoard> boards, {DateTime? now})`
  - `List<MandalartBoard> decodeBackup(String json)`
  - 포맷: `{"app":"miniManda","format":1,"exportedAt":"<ISO8601>","boards":[{...MandalartBoard.toMap(),"goals":[{...Goal.toMap(),"checklist":[ChecklistItem.toMap()]}]}]}`
  - 검증 (하나라도 어기면 `FormatException`): `app`이 `miniManda`, `format`이 1, `boards`가 리스트, 보드마다 `center_goal`이 비어 있지 않은 문자열, goal의 `position`이 0~7이고 중복 없음.
  - 불러올 때 goals가 8개보다 적으면 빠진 position을 빈 goal(`title: ''`)로 채운다. id 값은 믿지 않는다(DB가 새로 발급).
- `lib/core/db/sqlite_helper.dart`:
  - `Future<List<MandalartBoard>> readAllBoardsFull()`: 모든 보드를 체크리스트까지 읽는다 (`readMandalartBoard`를 보드마다 호출해도 된다).
  - `Future<List<int>> importBoards(List<MandalartBoard> boards, {required bool replace})`: 트랜잭션 하나. `replace`면 `mandalart_boards`를 전부 삭제(CASCADE로 나머지도 삭제). 보드 → goals → checklist_items 순으로 insert하되 `id`는 빼고, `parent_id`와 `goal_id`는 새로 발급된 id로 바꾼다. 새 보드 id 목록을 반환한다.
- `lib/core/providers/goal_provider.dart`: `MandalartBoardsNotifier`에 `Future<String> exportJson()`, `Future<int> importJson(String json, {required bool replace})`(가져온 보드 수 반환, 끝나면 `loadBoards()`). `replace`로 불러왔으면 `currentBoardProvider`를 `clearBoard()` 한다.
- 새 파일 `lib/screens/backup_screen.dart` (AppBar + `BackIcon`, 광고 없음):
  - **내보내기:** `path_provider` 임시 폴더에 `minimanda_backup_YYYYMMDD.json`을 쓰고 `share_plus`로 파일 공유. iPad 위치 지정(`sharePositionOrigin`)은 `share_screen.dart`의 `_share()` 방식을 그대로 따른다. 보드가 0개면 버튼 비활성.
  - **불러오기:** `file_picker`로 `.json` 하나 선택 → 5MB 넘으면 `backup.invalid_file` → `decodeBackup` → 확인 다이얼로그(보드 수 표시, "기존 보드에 추가" / "기존 보드를 지우고 교체" / 취소) → import → `backup.import_done` 스낵바.
  - `FormatException`은 `backup.invalid_file`, 그 밖의 실패는 `common.error` 스낵바.
- `lib/screens/settings_screen.dart`: 테마 그룹과 정보 그룹 사이에 `settings.data_section` 그룹, 행 `settings.backup`(아이콘 `Icons.save_alt_rounded`, 오른쪽 chevron) → `BackupScreen`.
- 번역 키: `settings.data_section`, `settings.backup`, `backup.title`, `backup.export`, `backup.export_hint`, `backup.import`, `backup.import_hint`, `backup.import_confirm_title`, `backup.import_confirm_body`({count}), `backup.import_merge`, `backup.import_replace`, `backup.import_done`({count}), `backup.invalid_file`.

### 테스트
- 새 `test/backup/backup_codec_test.dart`: 왕복 후 제목·메모·진행률·체크리스트가 같다. `app` 다름, `format` 2, position 중복, 깨진 JSON은 `FormatException`. goals 5개짜리는 8개로 채워진다.
- `test/db/sqlite_helper_test.dart`: `importBoards` 추가(기존 유지, 새 id), 교체(기존 삭제), 체크리스트의 `goal_id`가 새 goal을 가리킨다.
- `test/screens/app_flow_test.dart`: 설정 → 백업 화면 진입 1개. `_FakeDb`에 새 메서드 구현.

### 완료 기준
- Android 에뮬레이터와 iOS 시뮬레이터에서 내보내기 → 앱 데이터 삭제 → 불러오기로 보드와 체크리스트 상태가 복원된다.
- 새 권한이 추가되지 않았는지 `AndroidManifest`(병합 결과)와 `Info.plist`를 확인해 보고한다.

## 2단계. 삭제 되돌리기 (`feat/undo-delete`)

**목표:** 보드 삭제와 칸 비우기 뒤 스낵바에 "되돌리기" 버튼을 5초 보여 준다. 기존 확인 다이얼로그는 그대로 둔다.
**선행 조건:** 1단계 병합됨 (`importBoards`가 있어야 한다).

### 구현
- 방식: 삭제는 지금처럼 바로 하고, 지우기 직전의 값을 메모리에 들고 있다가 되돌리기를 누르면 다시 넣는다.
- `lib/core/widgets/mm_widgets.dart` `showMmSnack`: 선택 인자 `String? actionLabel`, `VoidCallback? onAction` 추가. 있으면 `SnackBarAction`을 붙이고 표시 시간을 5초로 한다.
- `lib/core/db/sqlite_helper.dart`: `Future<void> restoreGoal(Goal goal)` — 트랜잭션에서 해당 goal 행의 `title`, `description`, `progress`, `is_completed`를 되돌리고 체크리스트 항목을 다시 insert한다 (`clearGoal`은 행을 지우지 않고 비우기만 하므로 goal id는 그대로다).
- `lib/core/providers/goal_provider.dart`:
  - `MandalartBoardsNotifier.deleteBoard`가 삭제 전 `readMandalartBoard(id)` 결과를 반환: `Future<MandalartBoard?> deleteBoard(int id)`.
  - `Future<int?> restoreBoard(MandalartBoard board)`: `importBoards([board], replace: false)`로 다시 넣고 새 id 반환.
  - `CurrentBoardNotifier.clearGoal`이 비우기 전 `Goal`(체크리스트 포함)을 반환. `restoreGoal(Goal)` 추가(`_writeAndRefresh` 사용).
- `lib/screens/board_screen.dart` `_deleteBoard`: 스낵바에 되돌리기. 누르면 `restoreBoard` 후, 두 패널이고 열린 보드가 없으면 복원한 보드를 `loadBoard`.
- `lib/screens/cell_sheets.dart` `_clear`: 스낵바에 되돌리기 → `restoreGoal`. 시트는 이미 닫힌 뒤이므로 `ref`가 아니라 미리 잡아 둔 notifier를 쓴다.
- 번역 키: `common.undo`, `board.restored`, `cell.restored`.

### 테스트
- `test/providers/goal_provider_test.dart`: 삭제 → 복원 후 같은 내용의 보드가 있다(체크리스트 포함). 비우기 → 복원 후 제목·메모·체크리스트·진행률이 같다.
- `test/screens/app_flow_test.dart`: 보드 삭제 후 `common.undo`를 누르면 목록에 다시 보인다.

## 3단계. 세부 목표 마감일 (`feat/deadline`)

**목표:** 세부 목표 칸에 날짜 하나를 정하고, 보드 칸에 남은 일수를 보여 준다.
**선행 조건:** DB 버전이 3.

### 구현
- `goal_model.dart`: `Goal.dueDate`(`DateTime?`), `copyWith`에 `clearDueDate`. `int? daysLeft({DateTime? now})` — 시간은 버리고 날짜만 비교.
- `sqlite_helper.dart`: 버전 **4**. `upgrade()`에 `if (oldVersion < 4) ALTER TABLE goals ADD COLUMN due_date TEXT`, `_createDB`의 goals에도 추가. `Future<void> setGoalDueDate(int goalId, DateTime? date)`. `clearGoal`은 `due_date`도 null로.
- `goal_provider.dart`: `CurrentBoardNotifier.setGoalDueDate`.
- `cell_sheets.dart`: 메모 아래에 "마감일" 행. 누르면 `showDatePicker`(오늘~5년 뒤), 값이 있으면 지우기 버튼. 제목이 비어 있으면 완료 토글처럼 잠근다. 날짜 표시는 `DateFormat.yMMMd(context.locale.toLanguageTag())`.
- `board_screen.dart` `BoardCell`: 마감일이 있고 완료가 아니면 상태 줄에 `board.days_left`/`board.due_today`/`board.days_over`. 지난 경우 경고색 — `MmColors`에 `warn`이 없으면 라이트·다크 값을 추가한다(배경 대비 4.5:1 이상).
- 공유 이미지(`ShareCard`)에는 넣지 않는다.
- 2단계가 이미 병합돼 있으면 `restoreGoal`이 `due_date`도 되돌리게 한다.
- 번역 키: `cell.due_date`, `cell.due_none`, `cell.due_clear`, `board.days_left`({days}), `board.days_over`({days}), `board.due_today`.

### 테스트
- 모델: 직렬화 왕복, `due_date` 키가 없는 map도 읽힘, `daysLeft` 경계(오늘 0, 내일 1, 어제 -1).
- DB: 3 → 4 마이그레이션 후 기존 데이터 유지.
- 화면: 날짜를 정하면 칸에 남은 일수 문구가 보인다.

## 4단계. 완료 날짜 기록, 홈 요약 (`feat/completed-at`)

**목표:** 세부 목표와 체크리스트 항목이 완료된 시각을 저장하고, 홈 목록 위에 "이번 달 완료 N개"를 보여 준다.
**선행 조건:** 3단계 병합됨 (DB 버전이 4).

### 구현
- `goal_model.dart`: `Goal.completedAt`, `ChecklistItem.completedAt`(`DateTime?`).
- `sqlite_helper.dart`: 버전 **5**. `goals.completed_at TEXT`, `checklist_items.completed_at TEXT` 추가.
  - goal: `progress`가 100 미만 → 100이 되는 순간 현재 시각, 100 아래로 내려가면 null. 이미 100이면 덮어쓰지 않는다. `setGoalCompleted`, `_syncGoalProgress`, `clearGoal` 세 곳 모두.
  - 체크리스트 항목: `setChecklistItemDone`에서 같은 규칙.
  - 마이그레이션은 기존 완료 항목의 `completed_at`을 null로 둔다(과거 시각을 지어내지 않는다).
  - `Future<int> countCompletedSince(DateTime from)`: goals와 checklist_items에서 `completed_at >= from`인 개수의 합.
- `goal_provider.dart`: `monthlyCompletedProvider`(`FutureProvider<int>`, 이번 달 1일 0시 기준). `_writeAndRefresh`와 `loadBoards` 뒤에 invalidate.
- `home_screen.dart` `_BoardListPane`: "내 보드" 제목 줄 위에 한 줄 요약. 0이면 숨긴다.
- 번역 키: `home.monthly_done`({count}).

### 테스트
- DB: 완료 → 시각 기록, 해제 → null, 다시 완료 호출해도 첫 시각 유지, `countCompletedSince`, 4 → 5 마이그레이션.
- 화면: 완료가 1개 이상이면 요약이 보이고 0이면 없다.

## 5단계. 하루 한 번 알림 (`feat/reminder`)

**목표:** 설정에서 켜면 매일 정한 시각에 "오늘 목표 확인" 로컬 알림을 보낸다. 기본은 꺼짐, 기본 시각 21:00.
**선행 조건:** 0단계 완료.

### 구현
- 의존성: `flutter_local_notifications`, `timezone`, `flutter_timezone`. `flutter_local_notifications`는 **22.x(`^22.3.3`)로 고정**한다. 23.x는 AGP 9.1.1, compileSdk 37, Kotlin Gradle 플러그인 제거를 요구해 앱 빌드 설정 전체를 바꿔야 한다(AGP 9로 올리는 작업을 따로 할 때 함께 올린다). 앱 Gradle에 desugaring(`isCoreLibraryDesugaringEnabled = true`, `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`)을 켠다. `timezone`만으로는 기기 시간대를 알 수 없고 `tz.local` 기본값이 UTC라서, 그대로 예약하면 21:00이 한국에서 06:00에 울린다. `init()`에서 `tz.initializeTimeZones()` 뒤 `flutter_timezone`으로 기기 시간대 이름을 얻어 `tz.setLocalLocation(tz.getLocation(이름))`을 반드시 호출하고, 예약 시각은 `tz.TZDateTime(tz.local, ...)`로 만든다. 플랫폼 설정(AndroidManifest의 권한·리시버, iOS AppDelegate)은 **설치된 버전의 README**대로 한다. iOS 프로젝트는 UIScene 구조(`FlutterSceneDelegate`)임에 유의.
- Android는 **비정확 알람**(`AndroidScheduleMode.inexactAllowWhileIdle`)만 쓴다. `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM` 권한은 넣지 않는다(Play 정책 설명이 필요해진다). 앱 `AndroidManifest.xml`에 추가하는 것은 `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` 권한과 리시버 2개(`ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`. README의 선언을 그대로 쓴다)다. 리시버와 `RECEIVE_BOOT_COMPLETED`가 없으면 예약 알림이 울리지 않거나 재부팅 뒤 사라진다. `RECEIVE_BOOT_COMPLETED`는 일반 권한이라 Play 선언이 필요 없다.
- 새 파일 `lib/core/notifications/reminder_service.dart`: `init()`, `Future<bool> requestPermission()`, `schedule(TimeOfDay time, {required String title, required String body})`, `cancel()`. 알림 id는 1개로 고정, 매일 반복(`matchDateTimeComponents: DateTimeComponents.time`). 플러그인은 생성자로 주입받는다. `reminderServiceProvider`로 제공.
  - `init()`은 **권한을 요청하지 않는다.** `DarwinInitializationSettings`의 `requestAlertPermission`, `requestSoundPermission`, `requestBadgePermission`은 기본값이 `true`라서 그대로 두면 iOS 첫 실행 때 권한 팝업이 뜬다. 셋 다 `false`로 명시하고, 권한은 `requestPermission()`에서만 요청한다.
- `settings_provider.dart`: `AppSettings.reminderEnabled`(bool, 기본 false), `reminderTime`(TimeOfDay, 기본 21:00). SharedPreferences 키 `reminder_enabled`, `reminder_minutes`.
- `settings_screen.dart`: 테마 그룹 아래 `settings.reminder_section` 그룹. 스위치 행과 시각 행(`showTimePicker`, 꺼져 있으면 비활성). 권한 요청은 스위치를 켤 때만. 거부되면 스위치를 되돌리고 `settings.reminder_denied` 스낵바.
- 알림 문구는 예약하는 시점의 언어로 저장된다. 앱 시작 때 켜져 있으면 현재 언어로 다시 예약한다. 위치는 `main()`이 아니라 **`MaterialApp.builder` 안쪽**이다. `main()`에는 `ref`가 없고, `MyApp`(Localizations 바깥)의 첫 프레임은 번역 로드 전이라 `tr()`이 키 문자열을 돌려준다(에뮬레이터에서 알림 제목이 `reminder.title`로 온 것을 확인함). `builder`에서 작은 `ConsumerStatefulWidget`으로 감싸고, 처음 그릴 때·앱 언어가 바뀔 때·앱으로 돌아올 때(여행으로 시간대가 바뀌었거나 기기 설정에서 권한을 껐을 수 있다) 다시 예약한다. 권한이 꺼져 있으면 설정도 끈다. 기기 시간대는 예약할 때마다 다시 읽고, 내용이 같으면 다시 예약하지 않는다. 첫 프레임을 막지 않게 기다리지 않는다. 설정 변경과 예약은 riverpod `ReminderController`가 맡는다(예약 실패 시 설정을 끄고 남은 알림도 취소).
- 마감 하루 전 알림은 넣지 않는다.
- 번역 키: `settings.reminder_section`, `settings.reminder_enabled`, `settings.reminder_time`, `settings.reminder_denied`, `reminder.title`, `reminder.body`.

### 테스트
- `test/providers/settings_provider_test.dart`: 저장·복원, 기본값.
- 위젯 테스트에서는 `reminderServiceProvider`를 가짜로 override해 켜면 `schedule` 1회, 끄면 `cancel` 1회를 확인.

### 완료 기준
- Android 13 이상 에뮬레이터와 iOS 시뮬레이터에서 권한 다이얼로그, 1~2분 뒤 시각으로 맞춘 알림 수신, 끄면 오지 않는 것을 확인. 못 한 것은 "확인하지 못한 것"에 적는다.

## 6단계. 작은 다듬기 (`feat/polish`)

**선행 조건:** 0단계 완료.

### 6-1 버전 자동 표시
- 의존성 `package_info_plus`. `settings_screen.dart`의 `_appVersion` 상수를 지우고 `appVersionProvider`(`FutureProvider<String>`)로 `1.0.1 (4)` 형태를 보여 준다. 로딩 중은 빈 문자열.
- 테스트: `PackageInfo.setMockInitialValues`로 표시 확인. 기존 테스트가 `1.0.0` 문자열을 찾으면 고친다.

### 6-2 공유 이미지 다크 버전
- `share_screen.dart`: 미리보기 위에 선택 버튼 두 개(밝게 / 어둡게). 기본값은 현재 앱 테마. `ShareCard`의 `static const _c`를 생성자 인자 `MmColors colors`로 바꾸고, 내부에서 라이트 테마로 감싼 부분도 선택을 따른다.
- 선택을 바꾸면 이미지를 다시 만든다. 만드는 동안 버튼 비활성.
- 번역 키: `share.style_light`, `share.style_dark`.
- 테스트: 어둡게를 고르면 `ShareCard` 배경이 `MmColors.dark.bg`.

(예전 계획의 "첫 실행 예시 보드"는 뺐다. 7단계 템플릿이 같은 역할을 한다.)

## R1. 1.1.0 출시 준비 (`chore/release-1.1`)

**선행 조건:** 1~6단계 병합됨. 사용자가 시작을 지시함.

- `pubspec.yaml`: `version: 1.1.0+5` (스토어의 마지막 빌드 번호가 4보다 크면 그 다음 번호).
- 출시 노트 6개 언어: `fastlane/metadata/ios/<언어>/release_notes.txt`, `fastlane/metadata/android/<언어>/changelogs/default.txt` (Play 500자 제한).
- 소개 문구에 새 기능 문단 추가: iOS `description.txt`, Android `full_description.txt`. `test/store_metadata_test.dart` 통과.
- `fastlane/metadata/ios/review_information/notes.txt`: 3번(사용법)에 백업, 알림 추가. "첨부한 화면 녹화" 문단은 사용자에게 유지할지 묻는다.
- `docs/privacy-policy.md`: 알림(기기 안에서만 예약), 백업 파일(사용자가 직접 저장·공유) 문장 추가. 노션 페이지 수정은 사용자에게 알린다(아직 광고 내용도 반영 전).
- `flutter analyze`, `flutter test`, `flutter build ios --release --no-codesign`, `flutter build appbundle --release` 성공 확인.
- **업로드 레인은 실행하지 않는다.** 사용자에게 실행할 명령을 알려 준다: `fastlane ios beta`, `fastlane ios metadata`, `fastlane android build` 후 콘솔 업로드, `fastlane android changelogs`.
- 보고에 포함: Play 데이터 보안·권한 선언에서 바뀌는 것(알림 권한), App Store 개인정보 답변 변화 여부.

---

# 1.2 — 재미와 정리

## 7단계. 목표 템플릿 (`feat/templates`)

**목표:** 새 보드 화면에서 예시를 고르면 핵심 목표와 세부 목표 8개가 채워진 보드로 시작한다.
**선행 조건:** 1단계 병합됨 (`importBoards` 사용).

### 구현
- 템플릿 6개, id 고정: `english`(영어 회화), `health`(건강·운동), `career`(이직·취업 준비), `reading`(독서 습관), `saving`(저축), `exam`(자격증·시험).
- 문구는 번역 파일에 둔다: `template.<id>.name`(칩에 표시, 짧게), `template.<id>.center`(40자 이하), `template.<id>.goal_1`~`goal_8`(각 40자 이하). 6개 언어 모두 자연스러운 표현으로 쓴다(직역 금지). 그 밖에 `new.template_label`("예시로 시작하기"), `new.template_hint`.
- 새 파일 `lib/core/templates.dart`: `const templateIds = [...]`와, 현재 언어 문구로 `MandalartBoard`(subGoals 8개 포함)를 만드는 함수.
- `new_board_screen.dart`: 핵심 목표 입력칸 위에 가로 스크롤 칩 줄. 칩을 누르면 핵심 목표 칸을 템플릿 문구로 채우고 선택 표시. 다시 누르면 해제(입력칸은 그대로). 사용자가 핵심 목표를 고쳐 써도 선택은 유지된다.
- `_create()`: 템플릿이 선택돼 있으면 `createBoardWithEmptyGoals` 대신 `importBoards([board], replace: false)`로 세부 목표까지 넣고 반환된 id를 연다. 이후 흐름(스낵바, 화면 교체, 전면 광고)은 그대로.
- 저장된 뒤의 문구는 일반 데이터다. 언어를 바꿔도 번역되지 않는다(주석으로 남긴다).

### 테스트
- 템플릿마다 6개 언어에서 center와 goal 8개가 비어 있지 않고 40자 이하 (`test/translations_test.dart` 옆에 새 테스트).
- 화면: 칩 선택 → 만들기 → 보드에 세부 목표 8개가 채워져 있다. 선택 없이 만들면 지금과 같다.

## 8단계. 8칸 완료 축하 (`feat/celebrate`)

**목표:** 세부 목표 8개가 모두 완료되는 순간 축하 화면을 한 번 보여 주고 공유로 이어 준다.
**선행 조건:** 0단계 완료.

### 구현
- `board_screen.dart`: `ref.listen(currentBoardProvider, ...)`에서 **같은 보드 id**이고 `completedCount`가 8 미만 → 8이 된 경우에만 실행. 보드를 열 때 이미 8이면 실행하지 않는다. 저장은 하지 않는다(다시 미완료로 바꿨다가 완료하면 또 나와도 된다).
- 새 파일 `lib/screens/celebrate_dialog.dart`: 가운데 다이얼로그. 3×3 칸이 차례로 채워지는 짧은 애니메이션(1초 안팎, 새 의존성 없이 `AnimationController`), 제목, 버튼 둘("이미지로 공유" → `ShareScreen`, "닫기").
- `MediaQuery.disableAnimationsOf(context)`가 true면 애니메이션 없이 최종 상태만 보여 준다.
- 칸 편집 시트가 열려 있을 수 있다. 시트가 닫힌 뒤에 띄운다.
- 광고를 붙이지 않는다.
- 번역 키: `celebrate.title`, `celebrate.body`({title}), `celebrate.share`.

### 테스트
- 화면: 7칸 완료 상태에서 마지막 칸을 완료하면 `celebrate.title`이 보인다. 이미 8칸 완료인 보드를 열면 보이지 않는다.

## 9단계. 보드 정리 (`feat/board-manage`)

**목표:** 보드를 맨 위로 올리기, 보관함에 넣기와 꺼내기, 복제하기.
**선행 조건:** 4단계 병합됨 (DB 버전이 5), 1단계 병합됨.

### 구현
- `sqlite_helper.dart`: 버전 **6**. `mandalart_boards`에 `sort_order INTEGER NOT NULL DEFAULT 0`, `archived_at TEXT`. 마이그레이션에서 `sort_order`를 지금 순서(`created_at DESC`)대로 0, 1, 2…로 채운다.
  - 목록 정렬: `sort_order ASC, created_at DESC`. 새 보드와 복제본은 `MIN(sort_order) - 1`.
  - `readAllMandalartBoards({bool archived = false})`: `archived_at IS NULL`(기본) 또는 `IS NOT NULL`.
  - `moveBoardToTop(int id)`, `setBoardArchived(int id, bool archived)`, `duplicateBoard(int id)`(체크리스트 포함, 완료 상태는 그대로, 새 id 반환 — `importBoards` 재사용).
- `goal_model.dart`: `MandalartBoard.sortOrder`, `archivedAt`.
- `goal_provider.dart`: 위 세 동작을 notifier에 추가. `archivedBoardsProvider`(`FutureProvider`), 쓰기 뒤 invalidate.
- 메뉴(`board_screen.dart`의 `_showBoardMenu`, `showCardMenu`): "맨 위로 이동"(이미 맨 위면 숨김), "복제", "보관". 보관하면 열려 있던 보드는 닫는다(`_deleteBoard`의 처리와 같게).
- 새 파일 `lib/screens/archive_screen.dart`: 설정 → 데이터 그룹 → "보관함"(개수 표시). 목록 행마다 "꺼내기", "삭제". 비어 있으면 안내 문구.
- 끌어서 순서 바꾸기는 넣지 않는다(목록이 2열 `Wrap`이라 범위가 크다).
- 백업: 보관된 보드도 내보내기에 포함한다. `readAllBoardsFull`이 둘 다 읽게 한다.
- 번역 키: `board.menu_top`, `board.menu_duplicate`, `board.menu_archive`, `board.archived`, `board.duplicated`, `settings.archive`, `archive.title`, `archive.empty`, `archive.restore`, `archive.restored`.

### 테스트
- DB: 5 → 6 마이그레이션 후 순서 유지, 맨 위로 이동, 보관 시 기본 목록에서 빠짐, 복제본의 체크리스트.
- 화면: 보관 → 홈에서 사라짐 → 보관함에서 꺼내기 → 홈에 다시 보임.

## 10단계. 보드 강조색 (`feat/board-color`)

**목표:** 보드마다 강조색을 고른다. 보드 화면, 홈 카드, 공유 이미지에 적용된다.
**선행 조건:** 9단계 병합됨 (DB 버전이 6).

### 구현
- 색은 6개로 고정, DB에는 키만 저장: `yellow`(기본, 지금의 `#F2C230`), `coral` `#FF8A65`, `mint` `#6FCF97`, `sky` `#6CB8F0`, `lilac` `#B79CED`, `pink` `#F48FB1`. 모두 글자색 `#121212`와 대비 4.5:1 이상인지 계산해 확인하고, 미달이면 값을 조정해 보고한다.
- `sqlite_helper.dart`: 버전 **7**. `mandalart_boards.color TEXT`(null은 yellow). `setBoardColor(int id, String? color)`.
- `goal_model.dart`: `MandalartBoard.color`. `app_theme.dart`: 키 → 색 표와, `MmColors`의 accent 계열만 바꾼 복사본을 돌려주는 함수(알 수 없는 키는 yellow).
- 적용: `BoardScreen`, `_BoardCard`/`MiniBoard`, `ShareCard`를 그 보드의 색으로 만든 `MmColors`로 감싼다(Theme extension 교체). 앱 전체 강조색(버튼 그림자 등 보드와 무관한 곳)은 그대로 노랑.
- 고르는 곳: 핵심 목표 편집 시트(`_CenterSheet`)에 색 동그라미 6개 줄. 누르면 바로 저장. 각 동그라미에 색 이름 semantics 라벨.
- 번역 키: `center.color_label`, `color.yellow`, `color.coral`, `color.mint`, `color.sky`, `color.lilac`, `color.pink`.

### 테스트
- DB: 6 → 7 마이그레이션, 색 저장·읽기, 알 수 없는 키는 기본색.
- 화면: 색을 고르면 가운데 칸 라벨 색이 바뀐다.

## R2. 1.2.0 출시 준비 (`chore/release-1.2`)

R1과 같은 절차. `version: 1.2.0+<다음 빌드 번호>`. 스토어 스크린샷에 템플릿이나 색상 보드를 넣을지는 사용자에게 묻는다(디자인 프로젝트 작업이 따로 필요하다).

---

# 1.3 — 큰 기능

11~13단계는 범위가 크다. **구현 전에 설계 메모(바꿀 파일, 데이터 흐름, 위험 요소)를 먼저 보고하고 사용자 승인을 받은 뒤 구현한다.** 아래는 지켜야 할 요구 사항이다.

## 11단계. 칸을 3×3으로 펼치기 (`feat/expand-81`)

**목표:** 세부 목표 한 칸을 그 칸만의 3×3 보드로 펼친다. 깊이는 1단계까지(최대 81칸).
**선행 조건:** 10단계 병합됨 (DB 버전이 7), 2단계 병합됨.

### 요구 사항
- DB 버전 **8**: `mandalart_boards.parent_goal_id INTEGER REFERENCES goals(id) ON DELETE CASCADE`(null이면 일반 보드). 하위 보드는 홈 목록, 보관함, 보드 개수에 나오지 않는다.
- 칸 편집 시트에 "3×3으로 펼치기" 버튼. 조건: 제목이 있고, 체크리스트가 비어 있고, 이 보드가 하위 보드가 아닐 것. 조건이 안 되면 비활성과 이유 문구.
- 펼치면 하위 보드를 만든다(핵심 목표 = 그 칸 제목, 강조색 = 부모 보드 색). 그 칸은 완료 토글과 체크리스트 대신 "세부 보드 열기"를 보여 준다.
- 진행률: 하위 보드가 있는 칸의 `progress` = 하위 보드의 `overallProgress`. 하위 보드에 쓰기가 일어날 때 **같은 트랜잭션에서** 부모 칸을 갱신한다. 4단계의 `completed_at` 규칙도 그대로 적용된다.
- 칸 제목과 하위 보드 핵심 목표는 항상 같다(어느 쪽을 고쳐도 둘 다 바뀐다).
- 이동: 보드 화면에서 하위 보드를 열면 같은 Navigator에 쌓이고, 뒤로 가면 부모 보드가 최신 상태로 보인다. 한 패널과 두 패널 모두 동작해야 한다. `currentBoardProvider`가 하나뿐인 점을 설계 메모에서 어떻게 풀지 밝힌다.
- 접기: 하위 보드 메뉴의 "펼치기 취소"(확인 다이얼로그) → 하위 보드 삭제, 부모 칸 진행률 0. 부모 칸을 비우거나 부모 보드를 지우면 하위 보드도 지워진다. 되돌리기(2단계)는 하위 보드까지 복원해야 한다.
- 보드 칸(`BoardCell`)과 홈 `MiniBoard`에 "펼쳐진 칸" 표시(작은 격자 아이콘).
- 백업 포맷 **2**: goal에 선택 키 `"child": {보드}`. `decodeBackup`은 포맷 1과 2를 모두 읽는다. 복제(9단계)와 템플릿(7단계)이 깨지지 않는지 확인.
- 공유 이미지는 지금 보고 있는 보드 한 장만. 하위 보드를 만들 때는 전면 광고를 띄우지 않는다.
- 테스트: 7 → 8 마이그레이션, 진행률 전파, 삭제 전파, 백업 포맷 1·2 읽기, 화면 흐름(펼치기 → 하위 칸 완료 → 뒤로 → 부모 칸 진행률).

## 12단계. 홈 화면 위젯 (`feat/home-widget`)

**목표:** 가장 최근에 고친 보드의 3×3 상태를 홈 화면 위젯으로 보여 준다. 누르면 앱이 열린다.
**선행 조건:** R2 완료.

### 사용자가 먼저 해야 하는 것 (없으면 시작 불가)
- Apple Developer에서 App Group 만들기(예: `group.co.kr.myoung.ios.miniMandalart`)와 앱 ID에 연결. Xcode에서 위젯 확장 타깃 서명 확인.

### 요구 사항
- 의존성 `home_widget`. 위젯 설정 화면은 만들지 않는다(보드 선택 없음, 항상 "최근에 고친 보드").
- 앱 → 위젯 데이터: 보드 제목, 전체 진행률, 8칸 상태(빈칸/할 일/진행 중/완료), 강조색 키. `_writeAndRefresh`, 보드 삭제·보관·복원 뒤에 저장하고 위젯 갱신을 요청한다. 보드가 없으면 "보드를 만들어 보세요" 상태.
- iOS: WidgetKit 확장(SwiftUI), small과 medium 크기. 라이트·다크 대응. 최소 iOS 15.
- Android: `AppWidgetProvider` + `RemoteViews`, 2×2 기본 크기, 크기 조절 가능.
- 위젯 안 고정 문구는 6개 언어 네이티브 리소스로 둔다.
- 위젯에는 광고가 없고 네트워크를 쓰지 않는다.
- `fastlane ios beta` 빌드(`flutter build ipa`)가 확장 타깃까지 서명되는지 사용자가 확인해야 한다. 보고의 "확인하지 못한 것"에 적는다.

## 13단계. 광고 제거 인앱 결제 (`feat/remove-ads`)

**목표:** 한 번 결제하면 배너와 전면 광고가 모두 사라진다.
**선행 조건:** R2 완료.

### 사용자가 먼저 해야 하는 것 (없으면 시작 불가)
- App Store Connect와 Play Console에 비소모성 상품 등록(상품 ID 예: `remove_ads`), 가격 결정, 유료 앱 계약·세금·정산 계좌 완료. 상품 ID는 공개 식별자라 저장소에 넣어도 된다.

### 요구 사항
- 의존성 `in_app_purchase`. 서버 검증은 하지 않는다(서버가 없다).
- 구매 상태: SharedPreferences `ads_removed`에 저장하고, 앱 시작 때 스토어의 구매 내역으로 다시 확인한다.
- `lib/core/ads/ads.dart`의 `adsEnabledProvider`가 구매 상태를 따른다. 구매 즉시 화면의 배너가 사라져야 한다. 구매한 사용자에게는 동의 폼(UMP)과 광고 SDK 초기화도 하지 않는다.
- 설정에 "광고 제거" 행(가격 표시, 구매 후에는 "구매 완료")과 **"구매 복원"** 행(Apple 심사 필수).
- 결제 취소, 실패, 보류(pending), 상품 조회 실패를 각각 처리한다. 결제 중 중복 탭 방지.
- 테스트에서는 구매 서비스를 provider로 감싸 가짜로 override한다.
- 보고에 포함: App Store 개인정보(구매 항목), Play 데이터 보안, 심사용 상품 스크린샷 필요 여부.

## R3. 1.3.0 출시 준비 (`chore/release-1.3`)

R1과 같은 절차. 인앱 결제 상품은 앱 버전과 함께 심사에 제출해야 한다(사용자 작업으로 안내).

---

## 이번 범위에서 뺀 것

- 클라우드 동기화(iCloud, Drive): 계정과 충돌 처리가 필요하다. 백업 파일로 대체.
- 끌어서 보드 순서 바꾸기: 2열 목록에서 범위가 크다. "맨 위로 이동"으로 대체.
- 마감 하루 전 알림, 보드별 알림: 알림 수가 늘어 관리가 복잡하다.
- 개인 맞춤 광고와 iOS 추적 허용 팝업(ATT).
- 인앱 언어 선택: 시스템 설정으로 충분하다.
