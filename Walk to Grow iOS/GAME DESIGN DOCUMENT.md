# 🎮 GAME DESIGN DOCUMENT (GDD)

# 1. 📖 TITLE PAGE

- **Game Name:** Walk to Grow (working title)
- **Game Catch Phrase:** “Walk more, care more.”
- **Document Type:** Game Concept Document
- **Document Version:** v2.0

---

# 2. 👤 CREDIT PAGE

- **Document Purpose:** Thiết kế game idle kết hợp fitness và pet simulation
- **Working Title:** Walk to Grow
- **Game Concept:**
    
    Một game nơi người chơi đi bộ ngoài đời để nuôi và chăm sóc pet (mèo) trong game
    
- **Game Document Author:** Mai Thanh Hải

---

# 3. 🧩 INTRODUCTION

*Walk to Grow* là một tựa game mobile thuộc thể loại idle kết hợp với fitness và pet simulation. Trò chơi được thiết kế nhằm khuyến khích người chơi hình thành thói quen đi bộ thông qua cơ chế game hóa, trong đó hành động di chuyển ngoài đời thực sẽ trực tiếp ảnh hưởng đến tiến trình trong game.

Thông qua việc tích hợp dữ liệu từ hệ thống sức khỏe (ví dụ Apple Health), số bước chân của người chơi sẽ được chuyển đổi thành tài nguyên chính trong game gọi là “Life Energy”. Tài nguyên này được sử dụng để chăm sóc và nuôi dưỡng một pet ảo (mèo), bao gồm việc cho ăn, tương tác và mở khóa các nội dung mới.

Khác với các game idle truyền thống, trò chơi không yêu cầu người chơi tương tác liên tục mà thay vào đó, tiến trình được gắn với hành vi ngoài đời thực. Trọng tâm trải nghiệm không nằm ở cạnh tranh mà ở việc tạo kết nối cảm xúc giữa người chơi và pet, từ đó thúc đẩy hành vi tích cực một cách tự nhiên.

- **Genre:** Idle + Fitness + Pet Simulation
- **Player Type:** Casual / Adult / Office worker
- **Gameplay:** Đi bộ → nhận Energy → chăm sóc pet (mèo) → tiến triển
- **Technical Form:** Mobile app (iOS)
- **Reference:** Forest, Walkr
- **Theme:** Life simulation / Companion (pet bonding)
- **Design Intentions:** Original

---

# 4. 🔍 GAME ANALYSIS

## Genre

- Idle
- Simulation (Pet care)
- Fitness gamification

## Game Elements

- Walking (real-world input)
- Energy collection
- Feeding pet
- Pet progression
- Collection

## Theme

- Life simulation
- Companion (pet bonding)

## Style

- Cute, minimal, friendly
- Soft animation

## Player

- Single player

## Player Immersion

- Emotional (bond với pet)
- Habit-driven satisfaction

---

# 5. 🧠 GAME TECHNICAL

- **Technical Form:** 2D
- **View:** Top-down / simple UI
- **Platform:** iOS (HealthKit integration)
- **Language:** Swift hoặc Unity (C#)
- **Device:** Mobile

---

# 6. 💰 GAME SALES

- **Consumer Group:**
    - Người muốn tạo thói quen đi bộ
    - Người thích pet / casual game
- **Payment Model:**
    - Free-to-play
    - Cosmetic / pet purchase

---

# 7. 🎮 CORE GAMEPLAY

## Core Loop

1. Người chơi đi bộ ngoài đời
2. Game ghi nhận số bước
3. Chuyển đổi thành Life Energy
4. Dùng Energy để mua thức ăn
5. Cho mèo ăn → tăng trạng thái & tiến triển
6. Mèo phát triển / mở khóa nội dung mới

---

## Supporting Loops

- Daily Check-in → nhận reward
- Routine Streak → tăng bonus
- Collection → mở khóa mèo mới

---

# 8. ⚙️ CORE SYSTEMS

## 8.1 👣 Walking System

- Step → Energy
- Bonus cho:
    - Đi liên tục
    - Đạt goal ngày

---

## 8.2 🐱 Pet System

### Default

- Người chơi có 1 mèo ban đầu

### Pet States

- Hungry
- Happy
- Sleeping
- Playful

### Feeding

- Energy → đổi Food
- Food → tăng trạng thái pet

### Progression

- Feed nhiều → unlock:
    - Animation
    - Interaction

link asset pack [https://last-tick.itch.io/animated-pixel-cats-64x64](https://last-tick.itch.io/animated-pixel-cats-64x64)

---

## 8.3 💰 Currency System

### Energy

- Kiếm từ walking
- Dùng để:
    - Mua food

### Coin / Gem

- Kiếm từ:
    - Check-in
    - Achievement
- Dùng để:
    - Mua mèo mới
    - Cosmetic

---

## 8.4 🔁 Routine Streak System

- User chọn ngày hoạt động
- Hoàn thành đúng ngày → tăng streak
- Skip ngày ngoài routine → không ảnh hưởng
- Miss ngày trong routine → reset

---

## 8.5 🎁 Daily Check-in

- Login mỗi ngày → nhận reward
- Có streak riêng
- Không ảnh hưởng walking streak

---

# 9. 👤 PLAYER ELEMENTS

## Default

- 1 pet (mèo)
- 1 lượng Energy ban đầu

## Actions

- Đi bộ
- Cho pet ăn
- Tương tác với pet
- Mua pet mới

## Player Properties

- Steps
- Energy
- Coins/Gems
- Pet status
- Streak

## Player Rewards

- Energy
- Food
- Pet mới
- Cosmetic

---

# 10. 🖥️ UI / HUD

- Main Screen: Pet + trạng thái
- HUD:
    - Step count
    - Energy
    - Pet mood

---

# 11. 🌍 GLOBAL ELEMENTS

### ⏰ Time System

- Thời gian thực (real-time)
- Ảnh hưởng:
    - Pet hoạt động
    - Check-in
    - Streak

### 🌗 Day/Night Cycle

- Ngày / đêm thay đổi
- Ảnh hưởng:
    - Animation của mèo
    - UI (màu sáng/tối)

---

# 12. 🎨 ART DIRECTION

- Style: Cute, clean
- Color: Pastel
- Animation: Smooth, chậm

---

# 13. 🔊 AUDIO

- Ambient nhẹ
- Sound phản hồi khi feed pet

---

# 14. 🏗️ GAME ARCHITECTURE

- Home (Pet screen)
- Reward screen
- Shop
- Collection

---

# 15. ⚙️ TECHNICAL DOCUMENT

## System Requirements

- iOS 14+
- HealthKit access

## Core Systems

- Step tracking
- Energy conversion
- Pet state machine

---

# 16. ⚠️ RISKS

- Cheat step
- User churn
- Balance reward

---

# 17. 📅 ROADMAP

## Phase 1 (MVP)

- Walking → Energy
- 1 pet
- Feeding system

---

## Phase 2

- Multiple pets
- Streak system
- Check-in

---

## Phase 3

- Events
- Social
- Expansion

---

# 18. 🎯 DESIGN GOAL

- Giúp người chơi:
    - Đi bộ nhiều hơn
    - Tạo thói quen
    - Gắn bó với pet

---

# 19. 🔚 CONCLUSION

Game hướng tới việc biến hành động đơn giản ngoài đời (đi bộ) thành một trải nghiệm có ý nghĩa thông qua việc chăm sóc và phát triển một pet ảo, từ đó tạo động lực duy trì thói quen lâu dài.