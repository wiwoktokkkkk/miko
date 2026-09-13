# Miko

Aplikasi pembaca komik Android berbasis Flutter dengan antarmuka bergaya iOS (Cupertino). Konten komik, manhwa, dan manhua dibaca langsung dari situs publik [komiku.org](https://komiku.org) melalui mesin scrape yang dipindahkan dari skrip Python ke Dart murni.

## Fitur

- Beranda: peringkat harian, peringkat mingguan, komik terbaru, baru ditambahkan, dan umpak genre
- Populer: peringkat lengkap (lebih dari 350 judul)
- Jelajah: katalog dengan filter tipe (Manga / Manhwa / Manhua), 98 genre, status (Ongoing / Tamat), pengurutan, dan pemuatan tanpa batas (infinite scroll)
- Cari: pencarian khusus judul komik dengan cover (hasil tidak bercampur posting chapter)
- Favorit: simpan komik favorit dan riwayat baca untuk melanjutkan
- Detail series: sinopsis, status, rating, genre, dan daftar chapter (terbaru di atas) dengan pencarian chapter
- Reader: gulir vertikal berkelanjutan, bilah atas/bawah otomatis tersembunyi, indikator kemajuan, navigasi chapter sebelumnya/berikutnya, dan pemulihan otomatis bila satu halaman gagal dimuat
- Mode gelap mengikuti pengaturan sistem
- Tampilan pemuatan (skeleton) dan penangan error dengan tombol coba lagi di semua layar

## Teknologi

| Komponen | Pemilih |
| --- | --- |
| Framework | Flutter (Dart) |
| UI | Cupertino (gaya iOS 17) |
| Jaringan | `http` |
| Cache gambar | `cached_network_image` |
| Penyimpanan lokal | `shared_preferences` (favorit + riwayat) |
| Ikon | `cupertino_icons` (SF Symbols) |

Struktur kode:

```
lib/
  main.dart                 # Entry point
  src/
    app.dart                # Shell root (tab bar + tab)
    models.dart             # Model data
    theme/app_theme.dart    # Palet & tema light/dark
    api/
      parser.dart           # Mesin parser HTML/JSON komiku.org
      client.dart           # Klien HTTP + cache TTL
    state/app_store.dart    # Favorit & riwayat baca
    widgets/                # Cover, card, komponen bersama
    screens/                # Beranda, Populer, Jelajah, Cari, Favorit, Detail, Reader
```

## Menjalankan

Prasyarat: Flutter SDK dan Android SDK.

```bash
flutter pub get
flutter test          # unit test parser
flutter analyze       # analisis statis
flutter run           # jalankan di perangkat/emulator
```

Build APK release:

```bash
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

## Catatan

- Data berasal dari halaman publik komiku.org (tidak ada login).
- Gambar dimuat dengan header `User-Agent` dan `Referer`; host CDN `.to` yang mati otomatis diganti ke `.org`.
- Aplikasi ini untuk penggunaan pribadi dan menghormati sumber konten.
