# מדריך בנייה ופריסה

---

## 🌐 ווב — Firebase

```bash
flutter build web
firebase deploy --only hosting
```

האתר יעלה ל: https://app-shiba.web.app

---

## 📱 אנדרואיד — AAB לגוגל פליי

```bash
flutter build appbundle
```

הקובץ נמצא ב:
```
build\app\outputs\bundle\release\app-release.aab
```

העלי את הקובץ הזה ל-Google Play Console.

---

## ⚠️ אם יש שגיאת חתימה ב-AAB

```bash
flutter build appbundle --release
```

ודאי שקיים קובץ `android\key.properties` עם פרטי ה-keystore.
