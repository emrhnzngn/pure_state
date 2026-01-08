# Pure State Example - Todo Manager

Bu, Pure State paketinin kapsamlı bir örnek uygulamasıdır. Modern bir Todo Manager uygulaması olarak, paketin tüm özelliklerini gösterir.

## Özellikler

### State Management
- ✅ **Multi-Store Yapısı**: Todo ve Settings için ayrı store'lar
- ✅ **Store Container**: Store'lar arası iletişim
- ✅ **Priority Queue**: Action öncelik sıralaması
- ✅ **Middleware**: Logging ve monitoring
- ✅ **Async Actions**: Simüle edilmiş API çağrıları

### UI Bileşenleri
- ✅ **PureBuilder**: State değişikliklerinde otomatik rebuild
- ✅ **PureSelector**: Sadece seçili state değiştiğinde rebuild
- ✅ **PureListener**: Side effect'ler için listener
- ✅ **PureProvider**: Store'ları widget tree'ye sağlama

### Todo Özellikleri
- ✅ Todo ekleme, düzenleme, silme
- ✅ Todo tamamlama/tamamlanmamış yapma
- ✅ Kategori bazlı filtreleme
- ✅ Arama fonksiyonu
- ✅ Öncelik seviyeleri (Düşük, Orta, Yüksek)
- ✅ İstatistikler (Toplam, Tamamlanan, Aktif, Yüksek Öncelik)
- ✅ Filtreleme (Tümü, Aktif, Tamamlanan)

### Settings
- ✅ Tema değiştirme (Sistem, Açık, Koyu)
- ✅ Dil seçimi
- ✅ Bildirim ayarları
- ✅ Animasyon ayarları

## Proje Yapısı

```
example/
├── lib/
│   ├── main.dart                 # Ana uygulama dosyası
│   ├── models/                   # State modelleri
│   │   ├── todo_model.dart
│   │   └── app_settings_model.dart
│   ├── actions/                  # Action sınıfları
│   │   ├── todo_actions.dart
│   │   └── settings_actions.dart
│   ├── stores/                   # Store yapılandırmaları
│   │   └── app_stores.dart
│   ├── screens/                  # Ekranlar
│   │   ├── todo_list_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/                  # Widget bileşenleri
│       ├── todo_item_widget.dart
│       ├── todo_stats_widget.dart
│       └── add_todo_dialog.dart
└── pubspec.yaml
```

## Kullanılan Pure State Özellikleri

### 1. Multi-Store Yapısı
```dart
final container = StoreContainer();
final todoStore = PureStore<TodoState>(...);
final settingsStore = PureStore<AppSettingsState>(...);

container.register<TodoState>(todoStore);
container.register<AppSettingsState>(settingsStore);
```

### 2. Action Priority
```dart
class LoadTodosAction extends PureAction<TodoState> {
  @override
  int get priority => 3; // Çok yüksek öncelik
}
```

### 3. Middleware
```dart
todoStore.addMiddleware(pureLogger);
todoStore.addMiddlewareWithResult(pureLoggerWithResult);
```

### 4. PureSelector (Performans Optimizasyonu)
```dart
PureSelector<TodoState, TodoStats>(
  selector: (state) => state.stats,
  builder: (context, stats) => ...,
)
```

### 5. PureListener (Side Effects)
```dart
PureListener<TodoState>(
  listener: (context, state) {
    // State değişikliklerinde yan etkiler
  },
  listenWhen: (previous, current) => ...,
)
```

### 6. Async Actions
```dart
@override
FutureOr<TodoState> execute(TodoState currentState) async {
  await Future.delayed(Duration(seconds: 1));
  // Async işlemler
}
```

## Çalıştırma

1. Önce paketi yükleyin:
```bash
cd example
flutter pub get
```

2. Uygulamayı çalıştırın:
```bash
flutter run
```

## Öğrenilen Kavramlar

Bu örnek uygulama şunları gösterir:

1. **State Management**: Pure State ile state yönetimi
2. **Action Pattern**: Action-based state updates
3. **Middleware**: Action'ları intercept etme ve loglama
4. **Multi-Store**: Birden fazla store'u yönetme
5. **Performance**: PureSelector ile optimize rebuild'ler
6. **Side Effects**: PureListener ile yan etkileri yönetme
7. **Async Operations**: Async action'lar ve timeout handling
8. **Error Handling**: Hata yönetimi ve kullanıcı geri bildirimi

## Notlar

- Bu örnek uygulama, Pure State paketinin tüm özelliklerini gösterir
- Gerçek bir API entegrasyonu yerine simüle edilmiş async işlemler kullanılmıştır
- UI/UX modern ve kullanıcı dostu olacak şekilde tasarlanmıştır
- Tüm state değişiklikleri loglanır (middleware sayesinde)

