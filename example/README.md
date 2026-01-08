# Pure State Example App

Bu örnek uygulama, **Pure State** kütüphanesinin tüm gelişmiş özelliklerini gösteren kapsamlı bir Task Management (Görev Yönetimi) uygulamasıdır.

## 🏗️ Proje Yapısı

Proje, **Clean Architecture** ve **Feature-Based** yaklaşımını kullanarak organize edilmiştir:

```
lib/
├── core/                          # Uygulama genelinde paylaşılan kod
│   ├── services/                  # API ve servisler
│   │   └── api_service.dart
│   └── stores/                    # Store yönetimi
│       └── app_stores.dart
├── features/                      # Özellik bazlı modüller
│   ├── auth/                      # Kimlik doğrulama özelliği
│   │   ├── actions/               # Auth aksiyonları
│   │   │   └── user_actions.dart
│   │   ├── models/                # Auth modelleri
│   │   │   └── user_model.dart
│   │   ├── screens/               # Auth ekranları
│   │   │   └── login_screen.dart
│   │   └── states/                # Auth state'leri
│   │       └── user_state.dart
│   ├── tasks/                     # Görev yönetimi özelliği
│   │   ├── actions/
│   │   │   └── task_actions.dart
│   │   ├── models/
│   │   │   └── task_model.dart
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   ├── states/
│   │   │   └── task_state.dart
│   │   └── widgets/               # Task-specific widgets
│   │       ├── computed_statistics_widget.dart
│   │       └── task_list_widget.dart
│   └── settings/                  # Ayarlar özelliği
│       ├── actions/
│       │   └── settings_actions.dart
│       ├── screens/
│       │   └── settings_screen.dart
│       └── states/
│           └── settings_state.dart
└── main.dart                      # Uygulama giriş noktası
```

## ✨ Gösterilen Özellikler

### 1. **AsyncValue** 🔄
- **Dosya**: `features/auth/states/user_state.dart`, `features/tasks/states/task_state.dart`
- Asenkron operasyonları (loading, data, error) yönetir
- Login ve task yükleme işlemlerinde kullanılır

### 2. **Action Retry & Error Handling** 🔁
- **Dosya**: `features/auth/actions/user_actions.dart`, `features/tasks/actions/task_actions.dart`
- Network hatalarında otomatik yeniden deneme
- Exponential backoff stratejisi
- Özelleştirilebilir retry mantığı

### 3. **Authorization** 🔐
- **Dosya**: `features/tasks/actions/task_actions.dart`
- `PureAuthorizedAction` ile action-level yetkilendirme
- Role-based access control (Admin, User, Guest)
- Task silme ve oluşturma için yetki kontrolü

### 4. **State Validation** ✅
- **Dosya**: `features/settings/states/settings_state.dart`
- `ValidatableState` mixin ile state doğrulama
- Middleware ile otomatik validasyon
- Gerçek zamanlı validasyon feedback

### 5. **Computed Selectors** 🧮
- **Dosya**: `features/tasks/widgets/computed_statistics_widget.dart`
- Birden fazla store'dan türetilmiş değerler
- `PureComputedSelector2` ile user ve task state'lerinden istatistik hesaplama
- Memoization ile performans optimizasyonu

### 6. **Multi-Store Management** 🗂️
- **Dosya**: `core/stores/app_stores.dart`
- `StoreContainer` ile dependency injection
- Store'lar arası cross-reference
- Merkezi store yönetimi

### 7. **Time-Travel Debugging** ⏱️
- **Dosya**: `core/stores/app_stores.dart`
- User ve Task store'ları için replay özelliği
- State history tracking (50-100 entry)
- Debug senaryoları için geri alma/ileri alma

### 8. **Store Family & Auto-Dispose** 🏭
- **Dosya**: `core/stores/app_stores.dart`
- `PureStoreFamily` ile parametrik store oluşturma
- `PureAutoDisposeStore` ile otomatik kaynak temizleme
- User-specific task stores (5 dakika TTL)

### 9. **Action Batching** 📦
- Birden fazla aksiyonu tek state güncellemesinde birleştirme
- UI performans optimizasyonu

### 10. **Validation Middleware** 🛡️
- Otomatik state validation
- Hata yakalama ve loglama
- Real-time validation feedback

## 🎯 Feature Özellikleri

### Auth Feature (Kimlik Doğrulama)
- ✅ Login/Logout
- ✅ AsyncValue ile loading states
- ✅ Automatic retry on network errors
- ✅ User profile management
- ✅ Role-based authorization

### Tasks Feature (Görev Yönetimi)
- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Task filtering (All, Active, Completed)
- ✅ Authorization checks
- ✅ Computed statistics
- ✅ Real-time updates
- ✅ AsyncValue for async operations

### Settings Feature (Ayarlar)
- ✅ Theme management (Light/Dark/System)
- ✅ Notification preferences
- ✅ Auto-save toggle
- ✅ State validation (Max tasks limit)
- ✅ Real-time validation feedback

## 🚀 Çalıştırma

```bash
# Dependencies'leri yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

## 🔑 Demo Credentials

### Admin User:
- **Email**: admin@test.com
- **Password**: password
- **Permissions**: Tüm işlemler

### Regular User:
- **Email**: user@test.com
- **Password**: password
- **Permissions**: Sadece kendi task'larını silebilir

## 📚 Mimari Kararları

### Clean Architecture
- **Core**: Paylaşılan servisler ve store yönetimi
- **Features**: Domain-specific kod (auth, tasks, settings)
- **Separation of Concerns**: Her feature kendi models, states, actions ve screens'ine sahip

### Feature-Based Organization
- Her feature bağımsız bir modül
- Kolay test edilebilirlik
- Ölçeklenebilir yapı
- Açık dependency boundaries

### State Management Patterns
- **Unidirectional Data Flow**: Actions → State → UI
- **Immutable State**: Her state değişikliği yeni obje
- **Type-Safe Actions**: Compile-time güvenlik
- **Reactive UI**: Otomatik UI güncellemeleri

## 🎨 UI/UX Features

- ✅ Material Design 3
- ✅ Dark/Light theme support
- ✅ Responsive layout
- ✅ Loading indicators
- ✅ Error states
- ✅ Empty states
- ✅ Snackbar notifications
- ✅ Dialog interactions

## 🧪 Test Edilebilirlik

Proje yapısı test yazmayı kolaylaştırır:
- Feature-based organization ile unit test'ler
- Mock store'lar ile widget test'leri
- Integration test'ler için hazır yapı

## 📖 Öğrenme Kaynakları

Her özellik için detaylı açıklamalar:
- [Pure State Documentation](../README.md)
- [Examples](../EXAMPLES.md)
- [Improvements](../IMPROVEMENTS.md)

## 🔄 Güncelleme Geçmişi

### v1.0.0 - Feature-Based Architecture
- Clean Architecture yapısına geçiş
- Feature-based organization
- Tüm Pure State özelliklerinin entegrasyonu
- Kapsamlı örnekler ve dökümentasyon

## 💡 İpuçları

1. **Login**: Demo credential'lardan birini kullanın
2. **Theme**: Settings'den light/dark mode'u deneyin
3. **Validation**: Settings'de max tasks değerini 1'den küçük yapın
4. **Authorization**: Admin ve User hesapları arasındaki farkları deneyin
5. **Statistics**: Task oluşturup tamamlayarak computed statistics'i gözlemleyin
6. **Filtering**: Task filter'larını (All/Active/Completed) deneyin

## 🤝 Katkıda Bulunma

Pure State'e katkıda bulunmak için [CONTRIBUTING.md](../CONTRIBUTING.md) dosyasına bakın.

## 📄 Lisans

Bu örnek uygulama, Pure State kütüphanesi ile aynı lisansa sahiptir (MIT License).
