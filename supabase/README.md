# 🗄️ Konfigurasi Supabase

Folder ini berisi dokumentasi dan struktur database Supabase yang digunakan dalam proyek Sinergista.

## 📂 Struktur File

- **`structure.sql`**: Definisi lengkap tabel, relasi, dan struktur database dalam format SQL.

## 🚀 Setup Database Baru

Jika Anda ingin membuat instance Supabase baru untuk development atau testing:

1. **Buat Project Supabase**

   - Buka [Supabase Dashboard](https://supabase.com/dashboard).
   - Buat project baru.

2. **Jalankan Query Structure**

   - Buka menu **SQL Editor** di dashboard project Anda.
   - Copy seluruh isi file `structure.sql`.
   - Paste ke editor dan jalankan query.
   - Ini akan membuat semua tabel yang diperlukan secara otomatis.

3. **Konfigurasi Environment**

   - Ambil `Project URL` dan `anon/public key` dari menu **Project Settings > API**.
   - Masukkan ke dalam file `.env` di root project aplikasi (lihat `.env.example`).

## 📊 Daftar Tabel Utama

| Nama Tabel           | Deskripsi                                                    |
| -------------------- | ------------------------------------------------------------ |
| `profiles`           | Data utama user (public) yang terhubung dengan `auth.users`. |
| `modules`            | Container utama untuk workspace/proyek/mata kuliah.          |
| `tasks`              | Tugas individu biasa (To-Do List).                           |
| `kanban_tasks`       | Tugas kolaboratif dalam Modul (Kanban Board).                |
| `focus_sessions`     | Riwayat sesi fokus (Timer/Pomodoro).                         |
| `notes`              | Catatan pribadi user.                                        |
| `journals`           | Jurnal refleksi harian.                                      |
| `budgets`            | Pencatatan keuangan/budget planner.                          |
| `achievements`       | Daftar pencapaian/gamifikasi sistem.                         |
| `assessment_history` | Riwayat pengerjaan quiz produktivitas.                       |

## 🛡️ Keamanan (Row Level Security)

RLS diaktifkan secara default pada semua tabel untuk memastikan privasi data.

- **Data Pribadi** (`tasks`, `notes`, `budgets`): Hanya bisa diakses oleh pemiliknya (`auth.uid() = user_id`).
- **Data Modul**: Bisa diakses oleh pemilik (`user_id`) DAN anggota tim (`module_members`).
- **Data Publik**: Profil user dan Banner tertentu bisa dilihat oleh umum.
