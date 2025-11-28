# ⚡ Sinergista - Aplikasi Mobile Dashboard Tugas Dan Life Planner Menggunakan Flutter

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![Status](https://img.shields.io/badge/Status-Active%20Development-green)

> **Sinergista** adalah aplikasi produktivitas mobile yang mengintegrasikan manajemen tugas, akademik, finansial, dan kolaborasi tim dalam satu ekosistem. Aplikasi ini dirancang untuk mahasiswa dan profesional muda guna mengatasi masalah "fragmentasi aplikasi" (tool fatigue).

---

## 📋 Daftar Isi

1. [Fitur Utama](#-fitur-utama)
2. [Arsitektur & Struktur Folder](#-arsitektur--struktur-folder)
3. [Instalasi & Setup](#-instalasi--setup)
4. [Panduan Kontribusi (Git Flow)](#-panduan-kontribusi-wajib-baca)
5. [Tim Pengembang & Pembagian Tugas](#-tim-pengembang--pembagian-tugas)

---

## 🚀 Fitur Utama

Aplikasi ini terdiri dari 16 fitur inti yang dikelompokkan berdasarkan fungsinya:

### 🔹 Manajemen Inti (Core Task)

- **Fitur 1:** Kebutuhan Tugas (CRUD, Sub-tasks, Priority).
- **Fitur 3:** Tracking Progress (Kanban Board & Timeline).
- **Fitur 9:** Arsip (Riwayat tugas/modul selesai).
- **Fitur 10:** Pengelompokan Berdasarkan Warna (Color Tags).
- **Fitur 13:** Add New Modul (Container Proyek).

### 🔹 Fokus & Produktivitas

- **Fitur 2:** Pengingat Deadline (Notifikasi H-1, H-3 Jam).
- **Fitur 4:** Timer (Stopwatch & Pomodoro Focus).

### 🔹 Akademik & Catatan

- **Fitur 6:** Exam (Upload materi & persiapan ujian).
- **Fitur 12:** Notes (Rich Text Editor).
- **Fitur 15:** Template Jurnal (Refleksi Harian).

### 🔹 Kolaborasi & Sosial

- **Fitur 5:** Login & Autentikasi (Auth System).
- **Fitur 7:** Koneksi Pengguna (Friend list & Request).
- **Fitur 8:** Revisi Pekerjaan (Shared tasks & Comments).

### 🔹 Finansial & Personalisasi

- **Fitur 11:** Achievement (Gamifikasi & XP System).
- **Fitur 14:** Budget Planner (Pencatatan Keuangan).
- **Fitur 16:** Mode Gelap/Terang (Theme Settings).

---

## 🏗 Arsitektur & Struktur Folder

Project ini menggunakan **Feature-First Architecture**.
**PENTING:** Perhatikan nomor fitur di komentar folder agar Anda tidak salah menaruh file kodingan.

```text
lib/
├── core/                  # Komponen Global (Shared)
│   ├── constants/         # Colors, Strings, API Urls
│   ├── theme/             # AppTheme (Light/Dark Logic)
│   ├── providers/         # State Management (Theme, etc)
│   └── widgets/           # Widget umum (Button, InputField, Cards)
├── features/              # MODUL FITUR (Area Kerja Utama)
│   ├── auth/              # Fitur 5 (Login/Register)
│   ├── tasks/             # Fitur 1, 3, 9, 10, 13 (Manajemen Tugas, Modul, Arsip)
│   ├── focus/             # Fitur 2, 4 (Timer & Deadline)
│   ├── academic/          # Fitur 6, 12, 15 (Exam, Notes, Jurnal)
│   ├── collaboration/     # Fitur 7, 8 (Koneksi & Revisi)
│   ├── finance/           # Fitur 14 (Budget Planner)
│   ├── gamification/      # Fitur 11 (Achievement)
│   ├── profile/           # Halaman Profil User
│   └── settings/          # Fitur 16 (Pengaturan Tema)
└── main.dart
```

---

## 🛠 Instalasi & Setup

Ikuti langkah ini agar environment lokal sama dengan tim:

### Clone Repository

```bash
git clone https://github.com/AldaniP/sinergista.git
cd sinergista
```

### Install Dependencies

```bash
flutter pub get
```

### Cek Environment

```bash
flutter analyze
```

### Jalankan Aplikasi

```bash
flutter run
```

---

## 🤝 Panduan Kontribusi

Agar tidak terjadi **Merge Conflict** antar anggota kelompok, patuhi aturan main ini:

### 1. Aturan Branch (Cabang)

- ⛔ **JANGAN** pernah push kode langsung ke branch `main`.
- ✅ Selalu buat branch baru dari `main` sebelum mulai coding.
- **Format Nama Branch:** `feature/nama-fitur` atau `fix/nama-error`.
  - _Contoh:_ `feature/timer-pomodoro`, `feature/budget-ui`, `fix/login-bug`.

### 2. Aturan Commit

Gunakan format standar agar riwayat perubahan mudah dibaca oleh tim (bisa Bahasa Indonesia atau Bahasa Inggris):

- `feat`: untuk fitur baru (contoh: `feat: menambahkan logika timer pomodoro`).
- `fix`: untuk perbaikan bug (contoh: `fix: memperbaiki error login google`).
- `ui`: untuk perubahan tampilan/widget (contoh: `ui: update warna tombol simpan`).
- `docs`: untuk dokumentasi (contoh: `docs: update readme instalasi`).
- `refactor`: untuk merapikan kode tanpa mengubah fungsi.

### 3. Panduan Penggunaan Git & Skenario

Berikut adalah panduan langkah demi langkah untuk skenario umum yang akan sering dihadapi.

#### A. Memulai Fitur Baru (Create Branch)

Gunakan skenario ini saat baru akan memulai mengerjakan tugas atau fitur baru.

1.  **Pindah ke branch main:**
    ```bash
    git checkout main
    ```
2.  **Update main lokal dengan yang ada di GitHub:**
    ```bash
    git pull origin main
    ```
3.  **Buat branch baru dan langsung pindah ke sana:**
    ```bash
    git checkout -b feature/nama-fitur-anda
    ```

#### B. Menyimpan & Upload Pekerjaan (Push)

Lakukan ini secara berkala (misal setiap selesai satu fungsi kecil) agar progres tersimpan.

1.  **Cek file apa saja yang berubah:**
    ```bash
    git status
    ```
2.  **Siapkan file untuk disimpan (Staging):**
    ```bash
    git add .
    ```
3.  **Simpan perubahan (Commit):**
    ```bash
    git commit -m "feat: pesan commit anda"
    ```
4.  **Kirim ke GitHub (Push):**
    ```bash
    git push origin feature/nama-fitur-anda
    ```

#### C. Update Branch dari Main (Sync/Rebase)

Lakukan ini jika ada teman lain yang sudah merge kode mereka ke `main`, dan Anda ingin kode Anda juga memiliki perubahan terbaru tersebut (agar tidak konflik nanti).

1.  **Pastikan Anda di branch fitur Anda:**
    ```bash
    git checkout feature/nama-fitur-anda
    ```
2.  **Ambil info terbaru dari GitHub:**
    ```bash
    git fetch origin
    ```
3.  **Gabungkan perubahan main ke branch Anda (Rebase):**
    ```bash
    git rebase origin/main
    ```
    > **Catatan:** Jika terjadi _conflict_, perbaiki file yang konflik, lalu jalankan `git add .` dan `git rebase --continue`.

#### D. Menghapus Branch (Cleanup)

Lakukan ini jika ingin hapus branch.

1.  **Pindah ke main:**
    ```bash
    git checkout main
    ```
2.  **Update main:**
    ```bash
    git pull origin main
    ```
3.  **Hapus branch di lokal laptop Anda:**
    ```bash
    git branch -d feature/nama-fitur-yang-sudah-selesai
    ```
    _(Gunakan `-D` (huruf besar) jika branch belum di-merge tapi ingin dipaksa hapus)_

#### E. Menyimpan Sementara (Stash)

Gunakan ini jika Anda ingin pindah branch tapi pekerjaan di branch saat ini belum selesai dan belum siap di-commit.

1.  **Simpan perubahan sementara:**
    ```bash
    git stash
    ```
2.  **Pindah ke branch lain (misal main):**
    ```bash
    git checkout main
    ```
3.  **Kembali ke branch awal:**
    ```bash
    git checkout feature/nama-fitur-anda
    ```
4.  **Kembalikan perubahan yang disimpan tadi:**
    ```bash
    git stash pop
    ```

#### F. Mengambil Branch Teman (Checkout Remote)

Gunakan ini jika Anda ingin mencoba atau melanjutkan fitur yang dikerjakan teman di laptop Anda.

1.  **Ambil semua info terbaru:**
    ```bash
    git fetch origin
    ```
2.  **Lihat daftar branch yang ada:**
    ```bash
    git branch -a
    ```
3.  **Checkout ke branch teman:**
    ```bash
    git checkout feature/nama-fitur-teman
    ```

#### G. Mengatasi Konflik (Conflict Resolution)

Konflik terjadi saat Anda dan teman mengedit baris yang sama di file yang sama.

1.  **Identifikasi file yang konflik:**
    Saat `git rebase` atau `git merge`, terminal akan memberitahu file mana yang konflik.
2.  **Buka file tersebut di Text Editor (VS Code):**
    Cari tanda `<<<<<<<`, `=======`, dan `>>>>>>>`.
3.  **Pilih kode yang benar:**
    Hapus tanda-tanda tersebut dan sisakan kode yang diinginkan (gabungan atau salah satu).
4.  **Simpan file.**
5.  **Lanjutkan proses git:**
    ```bash
    git add .
    git rebase --continue
    ```
    _(Gunakan `git merge --continue` jika Anda sedang melakukan merge)_

#### H. Perintah Berguna Lainnya

- **Melihat semua branch:** `git branch -a`
- **Melihat riwayat commit:** `git log --oneline`
- **Membatalkan perubahan di satu file:** `git checkout -- namafile.dart`
- **Membatalkan semua perubahan yang belum di-add:** `git checkout .`
- **Melihat siapa yang mengedit baris kode:** `git blame namafile.dart`

---

## 👥 Tim Pengembang & Pembagian Tugas

Berikut adalah pembagian tanggung jawab fitur sinergista.

| Nama Anggota            | Fitur Utama 1         | Fitur Utama 2               | Folder Kerja Utama                             |
| :---------------------- | :-------------------- | :-------------------------- | :--------------------------------------------- |
| **Aldani Prasetyo**     | Fitur 4: Timer        | Fitur 10: Color Grouping    | `features/focus` & `features/tasks`            |
| **Bagus Subekti**       | Fitur 12: Notes       | Fitur 1: Kebutuhan Tugas    | `features/academic` & `features/tasks`         |
| **Eric Vincentius J.**  | Fitur 2: Deadline     | Fitur 14: Budget Planner    | `features/focus` & `features/finance`          |
| **Burju Ferdinand H.**  | Fitur 7: Koneksi      | Fitur 15: Template Jurnal   | `features/collaboration` & `features/academic` |
| **Antony Purnamarasid** | Fitur 6: Exam         | Fitur 3: Tracking Progress  | `features/academic` & `features/tasks`         |
| **Faris Abqori**        | Fitur 9: Arsip        | Fitur 8: Revisi Pekerjaan   | `features/tasks` & `features/collaboration`    |
| **Marcellino SP P.**    | Fitur 11: Achievement | Fitur 16: Mode Gelap/Terang | `features/gamification` & `features/settings`  |

---

_Dokumentasi Teknis - Kelompok 4 Sinergista © 2025_
