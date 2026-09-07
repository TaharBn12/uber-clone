# إعداد Firebase وبناء التطبيقات (APK)

هذا الدليل يشرح كيف تربط التطبيقات الثلاثة (`uber_users_app`، `uber_drivers_app`،
`uber_admin_panel`) بمشروع **Firebase الخاص بك**، وكيف تحصل على ملفات **APK**
جاهزة من GitHub Actions دون الحاجة لتثبيت Flutter محلياً.

> الحالة الحالية للمستودع: ملفات `google-services.json` تشير إلى مشروع صاحب
> المستودع الأصلي (`everyone-2de50`). التطبيقات تُبنى وتعمل، لكن بياناتك ستذهب
> إلى مشروعه. اتّبع الخطوات أدناه لتحويلها إلى مشروعك.

---

## 1. إنشاء مشروع Firebase

1. افتح [console.firebase.google.com](https://console.firebase.google.com) → **Add project**.
2. فعّل الخدمات التي تستخدمها التطبيقات:

   | الخدمة | المكان في Console | ملاحظات |
   |---|---|---|
   | **Authentication** | Build → Authentication → Sign-in method | فعّل **Phone** و **Google** |
   | **Realtime Database** | Build → Realtime Database → Create database | البيانات الرئيسية (users, drivers, tripRequests…) |
   | **Cloud Firestore** | Build → Firestore Database → Create database | يُستخدم في تسجيل السائقين |
   | **Storage** | Build → Storage → Get started | صور السائقين والوثائق |
   | **Cloud Messaging** | مفعّل تلقائياً | إشعارات الرحلات للسائقين |

   > أنشئ **Realtime Database** و **Storage** *قبل* تنزيل `google-services.json`
   > حتى يحتوي الملف على `firebase_url` و `storage_bucket`.

## 2. تسجيل تطبيقات Android

في **Project settings → Your apps → Add app → Android** سجّل ثلاثة تطبيقات
بأسماء الحزم التالية (يجب أن تطابق `applicationId` في `android/app/build.gradle`):

| التطبيق | Package name |
|---|---|
| تطبيق المستخدمين | `com.example.uber_users_app` |
| تطبيق السائقين | `com.example.uber_drivers_app` |
| لوحة الإدارة | `com.example.uber_admin_panel` |

- لتسجيل الدخول بـ Google أضف بصمة **SHA-1** (و SHA-256) لكل تطبيق. للحصول عليها
  من مفتاح الـ debug:
  ```bash
  keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android
  ```
  وإن كنت ستوقّع الإصدار بمفتاحك الخاص (القسم 6) أضف بصمته أيضاً.
- بعد تسجيل التطبيقات الثلاثة نزّل **`google-services.json`** مرة واحدة (ملف
  واحد يحوي التطبيقات الثلاثة لأنها في نفس المشروع).

## 3. تسجيل تطبيق ويب (للوحة الإدارة على المتصفح)

**Add app → Web** → أعطه اسماً → انسخ كائن `firebaseConfig` واحفظه في ملف
نصي، مثلاً `firebase_web_config.txt`:

```js
const firebaseConfig = {
  apiKey: "...",
  authDomain: "...firebaseapp.com",
  databaseURL: "https://...firebasedatabase.app",
  projectId: "...",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "1:...:web:...",
};
```

## 4. تطبيق الإعدادات على المستودع

السكربت `tools/configure_firebase.py` (يحتاج Python 3 فقط) ينسخ
`google-services.json` إلى التطبيقات الثلاثة ويولّد `lib/firebase_options.dart`
لكل تطبيق من نفس القيم:

```bash
python3 tools/configure_firebase.py \
  --google-services ~/Downloads/google-services.json \
  --web-config ~/Downloads/firebase_web_config.txt
```

- إن لم تسجّل تطبيق ويب بعد، احذف `--web-config`؛ ستُملأ قيم الويب بقيم
  مؤقتة (`YOUR_WEB_API_KEY`) ويعمل Android بشكل طبيعي.
- لتطبيق واحد فقط: `--apps uber_admin_panel`.
- السكربت يتحقق أولاً من أن الملف يحوي أسماء الحزم الثلاثة؛ إن نقص أحدها لن
  يغيّر أي شيء ويخبرك بما ينقص.

ثم راجع التغييرات وارفعها:

```bash
git add */android/app/google-services.json */lib/firebase_options.dart
git commit -m "Configure Firebase project"
git push
```

> بديل: إن كان لديك Flutter و FlutterFire CLI محلياً يمكنك تشغيل
> `flutterfire configure` داخل كل تطبيق؛ الملفات المولّدة متوافقة.

## 5. مفاتيح إضافية (اختيارية لكنها ضرورية لعمل الميزات)

| المفتاح | يُستخدم في | أين يوضع |
|---|---|---|
| **Google Maps API key** (Maps SDK for Android + Places + Directions) | الخرائط والبحث والمسارات في تطبيقي المستخدمين والسائقين | GitHub secret `GOOGLE_MAPS_API_KEY`، أو محلياً `--dart-define=GOOGLE_MAPS_API_KEY=...` + `maps.apiKey=...` في `android/local.properties` |
| **Stripe publishable key** | الدفع في تطبيق المستخدمين | secret `STRIPE_PUBLISHABLE_KEY` أو `--dart-define=STRIPE_PUBLISHABLE_KEY=...` |
| **Stripe secret key** | إنشاء PaymentIntent من داخل التطبيق (نمط تجريبي فقط) | secret `STRIPE_SECRET_KEY` أو `--dart-define=STRIPE_SECRET_KEY=...` |
| **مفتاح حساب الخدمة (FCM)** | إرسال إشعار "طلب رحلة جديد" إلى السائق | Project settings → Service accounts → **Generate new private key** ← احفظه في `uber_users_app/assets/firebase/service_account.json` (مُتجاهَل في git) أو secret `FCM_SERVICE_ACCOUNT_JSON` |

بدون هذه المفاتيح يُبنى التطبيق وينطلق، لكن الخرائط/الدفع/الإشعارات لن تعمل.

> ⚠️ وضع مفتاح Stripe السري أو مفتاح حساب الخدمة داخل التطبيق مناسب للتجربة
> فقط؛ في الإنتاج انقل هذه العمليات إلى Cloud Functions أو خادم خاص بك.

## 6. الحصول على APK من GitHub Actions

الـ workflow `.github/workflows/build-apks.yml` يبني تلقائياً:

- **APK إصدار** لكل تطبيق من الثلاثة، و
- **حزمة ويب** للوحة الإدارة،

عند كل push إلى `master` (أو فروع `arena/**`) وعند كل Pull Request، ويمكن تشغيله
يدوياً من تبويب **Actions → Build APKs → Run workflow**.

**أين أجد الملفات؟** Actions → اختر التشغيل → قسم **Artifacts** في أسفل الصفحة:
`uber_users_app-apk`، `uber_drivers_app-apk`، `uber_admin_panel-apk`،
`uber_admin_panel-web`.

**إصدار رسمي:** ادفع وسماً يبدأ بـ `v` وستُرفق ملفات APK بصفحة Releases:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### الأسرار (Settings → Secrets and variables → Actions → New repository secret)

| الاسم | مطلوب؟ | الوصف |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | موصى به | مفتاح خرائط Google |
| `STRIPE_PUBLISHABLE_KEY` | اختياري | Stripe |
| `STRIPE_SECRET_KEY` | اختياري | Stripe (تجريبي) |
| `FCM_SERVICE_ACCOUNT_JSON` | اختياري | محتوى ملف JSON لحساب الخدمة كاملاً |
| `ANDROID_KEYSTORE_BASE64` | اختياري | keystore التوقيع مشفّراً بـ base64 |
| `ANDROID_KEYSTORE_PASSWORD` | مع السابق | كلمة سر الـ keystore |
| `ANDROID_KEY_ALIAS` | مع السابق | اسم المفتاح |
| `ANDROID_KEY_PASSWORD` | مع السابق | كلمة سر المفتاح |

بدون أسرار التوقيع يُوقَّع الـ APK بمفتاح debug مؤقت (يعمل للتثبيت والتجربة،
لكن يجب حذف النسخة السابقة قبل تثبيت نسخة جديدة، ولا يصلح لمتجر Play).

لإنشاء keystore وتحويله إلى base64:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
base64 -w0 upload-keystore.jks > keystore.b64   # ضع محتوى الملف في ANDROID_KEYSTORE_BASE64
```

## 7. البناء محلياً (اختياري)

```bash
cd uber_users_app
flutter pub get
flutter build apk --release \
  --dart-define=GOOGLE_MAPS_API_KEY=... \
  --dart-define=STRIPE_PUBLISHABLE_KEY=... \
  --dart-define=STRIPE_SECRET_KEY=...
# الناتج: build/app/outputs/flutter-apk/app-release.apk
```

لتوقيع محلي أنشئ `android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks   # نسبةً إلى android/app/
```

## 8. قواعد الأمان (مهم قبل النشر)

بعد إنشاء قواعد البيانات تكون في وضع الاختبار أو مغلقة. للتجربة السريعة:

- **Realtime Database → Rules**
  ```json
  { "rules": { ".read": "auth != null", ".write": "auth != null" } }
  ```
- **Firestore → Rules** و **Storage → Rules**: اسمح بالقراءة/الكتابة للمستخدمين
  المسجّلين (`request.auth != null`) ثم شدّد القواعد حسب حاجتك.

---

## استكشاف الأخطاء

| المشكلة | السبب المحتمل / الحل |
|---|---|
| `No matching client found for package name` أثناء البناء | `google-services.json` لا يحوي اسم الحزمة؛ سجّل التطبيق في Console وأعد تشغيل السكربت |
| التطبيق يعمل لكن لا بيانات تظهر | تحقق من قواعد الأمان (القسم 8) ومن أن `databaseURL` صحيح في `firebase_options.dart` |
| تسجيل الدخول بـ Google يفشل | أضف بصمة SHA-1 للتطبيق في Console ونزّل `google-services.json` من جديد |
| الخريطة رمادية | مفتاح `GOOGLE_MAPS_API_KEY` مفقود أو غير مفعّل لـ Maps SDK for Android |
| لا تصل الإشعارات للسائق | لم يُضبط مفتاح حساب الخدمة (`FCM_SERVICE_ACCOUNT_JSON`) أو أنه لمشروع آخر |
| `Missing classes detected while running R8` في تطبيق المستخدمين | قواعد R8 الخاصة بـ Stripe موجودة في `uber_users_app/android/app/proguard-rules.pro`؛ إن أضفت مكتبة جديدة تحتاج قواعد، أضفها إلى نفس الملف (انظر `build/app/outputs/mapping/release/missing_rules.txt`) |
| فشل البناء في GitHub Actions | افتح التشغيل → الوظيفة الفاشلة → قسم **Summary** يعرض أسطر الخطأ، وملف السجل الكامل مرفوع كـ artifact باسم `<app>-build-log` |
