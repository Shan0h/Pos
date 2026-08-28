# Tutorial Setup Produk & POS Modern

Selamat datang ke panduan rasmi penggunaan sistem **POS Modern (Beta)**. Tutorial ini akan membimbing anda tentang cara menyediakan produk dan menggunakan fungsi canggih seperti kod bar dan cetakan automatik.

---

## 1. Menambah Produk Baru
Produk baru boleh ditambah melalui halaman **Inventory**.

1. Buka menu tepi (Drawer) dan klik **Inventory**.
2. Tekan ikon tambah `+` di penjuru kanan.
3. Isikan maklumat penting:
   * **Nama**: Nama produk (Contoh: "Nasi Lemak Ayam"). *Kategori pintar akan dijana secara automatik menggunakan perkataan pertama, iaitu "Nasi"*.
   * **Kod**: Masukkan kod bar unik jika anda menggunakan pengimbas kod bar. Jika tidak, masukkan sebarang kod rawak seperti `P01`.
   * **Harga Jual**: Masukkan harga. **Jika anda menetapkan Harga Jual = 0**, sistem akan memaparkan kotak 'Open Price' apabila produk ini dipilih pada POS Modern. Ini berguna untuk item seperti Nasi Campur.

---

## 2. Menggunakan Pengimbas Kod Bar (Barcode Scanner)
Sistem POS Modern kini menyokong pengimbas kod bar perkakasan!

1. Sambungkan pengimbas kod bar anda (USB atau Bluetooth).
2. Di skrin **Modern POS**, klik pada ruangan `Search or Scan Barcode...` supaya kursor berkelip di dalam kotak tersebut.
3. Tembak kod bar pada produk.
4. Pengimbas akan menaip kod secara automatik dan menekan `Enter`.
5. Produk akan terus masuk ke dalam *Cart*!

---

## 3. Cetakan Tersepadu & Laci Tunai
Apabila anda selesai membuat pesanan, tekan butang **PAY NOW**.

Sistem akan:
1. Menyimpan data penjualan ke dalam rekod pangkalan data.
2. Mencetak resit secara automatik menggunakan pencetak (Thermal Printer) yang telah dikonfigurasikan di halaman tetapan cetakan.
3. Menendang laci tunai (Cash Drawer Kick) supaya laci terbuka secara automatik untuk memulangkan baki.

---

## 4. Pengurusan Kuantiti
Jika anda tersalah tekan atau pelanggan ingin mengurangkan pesanan:
1. Tekan butang tolak `-` pada *Ticket Panel* (senarai pesanan di sebelah kanan).
2. Jika kuantiti item ialah 2, ia akan dikurangkan menjadi 1.
3. Jika kuantiti item ialah 1, menekan `-` sekali lagi akan memadam produk tersebut terus dari pesanan.

Semoga tutorial ini membantu operasi perniagaan anda! 🚀
