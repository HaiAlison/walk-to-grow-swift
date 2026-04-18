# Walk to Grow - Danh sach static let

Tai lieu nay tong hop cac hang so `static let` dang duoc dung trong project.

## 1) `Walk to Grow Shared/GameScene.swift`

### `FenceSheet`
- `cols = 8`: So cot cua sprite sheet hang rao.
- `rows = 10`: So hang cua sprite sheet hang rao.
- `horizontalFenceIndices = [1, 2, 3, 4, 5, 6, 7, 8]`: Danh sach frame hang rao ngang.
- `cornerTopLeft = 17`: Frame goc tren trai.
- `cornerTopRight = 19`: Frame goc tren phai.
- `cornerBottomLeft = 20`: Frame goc duoi trai.
- `cornerBottomRight = 22`: Frame goc duoi phai.
- `verticalFenceIndices = [25, 26, 27, 28]`: Danh sach frame hang rao doc.
- `verticalEndPost = 32`: Frame cot ket thuc hang rao doc.

### `CatWander`
- `movementKey = "cat_wander_movement"`: Key action di chuyen ngau nhien cua meo.
- `minPause = 0.35`: Thoi gian dung toi thieu giua cac buoc.
- `maxPause = 1.1`: Thoi gian dung toi da giua cac buoc.
- `restChance = 0.35`: Xac suat meo chon trang thai nghi.
- `minRestDuration = 1.0`: Thoi gian nghi toi thieu.
- `maxRestDuration = 5.0`: Thoi gian nghi toi da.
- `speedTilesPerSecond = 1.8`: Toc do di chuyen theo tile/giay.
- `minStepTiles = 1.0`: Do dai buoc toi thieu (theo tile).
- `maxStepTiles = 5.0`: Do dai buoc toi da (theo tile).
- `tapPauseKey = "cat_wander_tap_pause"`: Key action tam dung sau khi tap vao meo.
- `emojiKey = "cat_tap_emoji"`: Ten node emoji hien khi tap.
- `resumeAfterTap = 1.2`: Do tre truoc khi meo di chuyen lai sau tap.
- `emojis = ["😺", "😸", "😻", "😽", "😼", "🐾", "✨", "💤", "🍖", "💛"]`: Tap emoji ngau nhien hien tren meo.

## 2) `Walk to Grow iOS/Nodes/CatSheet1024Node.swift`

### Thuoc tinh static cap class
- `texturePixelWidth = 1024`: Chieu rong texture sheet premium.
- `texturePixelHeight = 544`: Chieu cao texture sheet premium.
- `headerHeight = 32`: Chieu cao vung header trong sheet (bo qua khi cat frame sprite).
- `cell = 32`: Kich thuoc moi o sprite (pixel).
- `spriteColumns = 24`: So cot o sprite trong sheet.
- `spriteRows = 16`: So hang o sprite trong sheet.
- `animationKey = "cat_sheet_1024_anim"`: Key action animation cua `CatSheet1024Node`.

### `Sheet`
- `sittingCols = 0..<4`: Dai cot cho animation ngoi.
- `lookingCols = 4..<8`: Dai cot cho animation nhin quanh.
- `layingCols = 8..<12`: Dai cot cho animation nam.
- `walkingCols = 12..<16`: Dai cot cho animation di bo.
- `runningCols = 16..<20`: Dai cot cho animation chay.
- `running2Cols = 20..<23`: Dai cot cho bien the animation chay 2.

## 3) `Walk to Grow iOS/Nodes/GrassNode.swift`

### `DaisySheet`
- `frameCount = 8`: So frame cua strip hoa cuc animate.
- `framePixelSize = 128`: Kich thuoc moi frame hoa cuc (pixel).

## 4) `Walk to Grow iOS/Nodes/CatNode.swift`

- `sheetImageName = "normal_cat"`: Ten imageset cua meo mac dinh.
- `columns = 8`: So cot cua sprite sheet meo mac dinh.
- `rows = 10`: So hang cua sprite sheet meo mac dinh.
- `animationKey = "cat_sheet_anim"`: Key action animation cua `CatNode`.

## Ghi chu
- Tai lieu nay phan anh cac `static let` hien co tai thoi diem tao.
- Khi them/sua `static let` moi, hay cap nhat lai file nay de giu dong bo tai lieu.
