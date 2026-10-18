# سامانه سبک مدیریت کارتریج (MVP)

## وضعیت تحویل
سورس Android Flutter + Node.js API + PostgreSQL + Docker Compose + دستور ساخت خودکار APK.
در محیط تهیه پروژه Android SDK/Flutter SDK قابل دسترسی نبود؛ APK واقعی در این تحویل **ساخته یا روی گوشی تست نشده است**.

## ساخت APK با GitHub Actions
1. محتویات این پوشه را در یک GitHub repository خصوصی قرار دهید.
2. در `.github/workflows/android-apk.yml` مقدار `https://YOUR-API-DOMAIN.example` را با HTTPS دامنه واقعی API جایگزین کنید.
3. Actions → Android debug APK → Run workflow را بزنید.
4. در صورت موفقیت Analyze و Build، فایل artifact با نام `cartridge-android-debug-apk` را دریافت کنید.
5. پس از استقرار Backend و تأمین PostgreSQL، آن را در گوشی نصب و سناریوهای تحویل/پرداخت را تست کنید.

## Backend
`docker compose up --build -d`، ابتدا `.env.example` را به `server/.env` کپی کنید و رمز مدیر و JWT_SECRET قوی وارد نمایید.
**هشدار**: API فعلی نمونه اجرایی اولیه است؛ تأیید دوطرفه، پرداخت بانکی قابل‌راستی‌آزمایی، دسترسی دقیق اسناد و کنترل تمام خطاهای هم‌زمان هنوز باید تکمیل شوند. برای داده‌های واقعی یا انتشار عمومی مناسب نیست.
