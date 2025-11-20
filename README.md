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
* **Fitur 1:** Kebutuhan Tugas (CRUD, Sub-tasks, Priority).
* **Fitur 3:** Tracking Progress (Kanban Board & Timeline).
* **Fitur 9:** Arsip (Riwayat tugas/modul selesai).
* **Fitur 10:** Pengelompokan Berdasarkan Warna (Color Tags).
* **Fitur 13:** Add New Modul (Container Proyek).

### 🔹 Fokus & Produktivitas
* **Fitur 2:** Pengingat Deadline (Notifikasi H-1, H-3 Jam).
* **Fitur 4:** Timer (Stopwatch & Pomodoro Focus).

### 🔹 Akademik & Catatan
* **Fitur 6:** Exam (Upload materi & persiapan ujian).
* **Fitur 12:** Notes (Rich Text Editor).
* **Fitur 15:** Template Jurnal (Refleksi Harian).

### 🔹 Kolaborasi & Sosial
* **Fitur 5:** Login & Autentikasi (Auth System).
* **Fitur 7:** Koneksi Pengguna (Friend list & Request).
* **Fitur 8:** Revisi Pekerjaan (Shared tasks & Comments).

### 🔹 Finansial & Personalisasi
* **Fitur 11:** Achievement (Gamifikasi & XP System).
* **Fitur 14:** Budget Planner (Pencatatan Keuangan).
* **Fitur 16:** Mode Gelap/Terang (Theme Settings).

---

## 🏗 Arsitektur & Struktur Folder

Project ini menggunakan **Feature-First Architecture**.
**PENTING:** Perhatikan nomor fitur di komentar folder agar Anda tidak salah menaruh file kodingan.

```text
lib/
├── core/                  # Komponen Global (Shared)
│   ├── constants/         # Colors, Strings, API Urls
│   ├── theme/             # AppTheme (Light/Dark Logic)
│   └── widgets/           # Widget umum (Button, InputField, Cards)
├── features/              # MODUL FITUR (Area Kerja Utama)
│   ├── auth/              # Fitur 5 (Login/Register)
│   ├── tasks/             # Fitur 1, 3, 9, 10, 13 (Manajemen Tugas & Modul)
│   ├── focus/             # Fitur 2, 4 (Timer & Deadline)
│   ├── academic/          # Fitur 6, 12, 15 (Exam, Notes, Jurnal)
│   ├── collaboration/     # Fitur 7, 8 (Koneksi & Revisi)
│   ├── finance/           # Fitur 14 (Budget Planner)
│   ├── gamification/      # Fitur 11 (Achievement & Profil)
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
````

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

## 🤝 Panduan Kontribusi (WAJIB BACA)

Agar tidak terjadi **Merge Conflict** antar anggota kelompok, patuhi aturan main ini:

### 1. Aturan Branch (Cabang)
* ⛔ **JANGAN** pernah push kode langsung ke branch `main`.
* ✅ Selalu buat branch baru dari `main` sebelum mulai coding.
* **Format Nama Branch:** `feature/nama-fitur` atau `fix/nama-error`.
    * *Contoh:* `feature/timer-pomodoro`, `feature/budget-ui`, `fix/login-bug`.

### 2. Aturan Commit
Gunakan format standar agar riwayat perubahan mudah dibaca oleh tim (bisa Bahasa Indonesia atau Bahasa Inggris):
* `feat`: untuk fitur baru (contoh: `feat: menambahkan logika timer pomodoro`).
* `fix`: untuk perbaikan bug (contoh: `fix: memperbaiki error login google`).
* `ui`: untuk perubahan tampilan/widget (contoh: `ui: update warna tombol simpan`).
* `docs`: untuk dokumentasi (contoh: `docs: update readme instalasi`).
* `refactor`: untuk merapikan kode tanpa mengubah fungsi.

### 3. Alur Kerja (Workflow) Harian

1.  **Update Local Main:**
    ```bash
    git checkout main
    git pull origin main
    ```

2.  **Buat Branch Kerja:**
    ```bash
    git checkout -b feature/fitur-saya
    ```

3.  **Coding & Commit:**
    Lakukan perubahan, lalu commit dengan pesan jelas.
    ```bash
    git commit -m "feat: implement pomodoro logic"
    ```

4.  **Push:**
    ```bash
    git push origin feature/fitur-saya
    ```

5.  **Pull Request (PR):**
    Buka GitHub, buat PR ke `main`, dan minta review.

---

## 👥 Tim Pengembang & Pembagian Tugas

Berikut adalah pembagian tanggung jawab fitur sinergista.

| Nama Anggota | Fitur Utama 1 | Fitur Utama 2 | Folder Kerja Utama |
| :--- | :--- | :--- | :--- |
| **Aldani Prasetyo** | Fitur 4: Timer | Fitur 10: Color Grouping | `features/focus` & `features/tasks` |
| **Bagus Subekti** | Fitur 12: Notes | Fitur 1: Kebutuhan Tugas | `features/academic` & `features/tasks` |
| **Eric Vincentius J.** | Fitur 2: Deadline | Fitur 14: Budget Planner | `features/focus` & `features/finance` |
| **Burju Ferdinand H.** | Fitur 7: Koneksi | Fitur 15: Template Jurnal | `features/collaboration` & `features/academic` |
| **Antony Purnamarasid** | Fitur 6: Exam | Fitur 3: Tracking Progress | `features/academic` & `features/tasks` |
| **Faris Abqori** | Fitur 9: Arsip | Fitur 8: Revisi Pekerjaan | `features/tasks` & `features/collaboration` |
| **Marcellino SP P.** | Fitur 11: Achievement | Fitur 16: Mode Gelap/Terang | `features/gamification` & `features/settings` |

---
*Dokumentasi Teknis - Kelompok 4 Sinergista © 2025*