# EA Foods - Pre-Order Mobile App

A Flutter mobile application for EA Foods' pre-order system, built as part of a technical assignment for a Flutter Mobile Engineer position.

## 📱 Overview

This app implements a pre-order system where:
- All orders are placed in advance (no ad-hoc sales)
- Customers place pre-orders for next-day delivery
- Orders are stock-driven (cannot exceed available inventory)
- Delivery windows & cut-offs: Orders after 6:00 PM go to +2 days
- Ops managers update stock balances twice daily (morning/evening)

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter 3.8.1+
- **State Management**: Provider
- **Local Storage**: SQLite (via sqflite package)
- **HTTP Client**: http package for API calls
- **Date/Time**: intl package
- **JSON Serialization**: json_annotation + build_runner
- **UUID Generation**: uuid package
- **Testing**: flutter_test

### Project Structure
```
lib/
├── models/           # Data models with JSON serialization
│   ├── product.dart & product.g.dart
│   ├── order.dart & order.g.dart
│   ├── delivery_slot.dart & delivery_slot.g.dart
│   └── stock_update.dart & stock_update.g.dart
├── services/         # Business logic and data services
│   ├── database_service.dart    # SQLite operations
│   └── order_service.dart       # Order business logic
├── providers/        # State management with Provider
│   ├── product_provider.dart    # Product state management
│   └── order_provider.dart      # Order state management
├── screens/          # UI screens
│   ├── home_screen.dart         # Main navigation
│   ├── stock_view_screen.dart   # Inventory management
│   ├── preorder_form_screen.dart # Order placement
│   ├── my_orders_screen.dart    # Customer order view
│   ├── order_management_screen.dart # Business order management
│   └── stock_history_screen.dart # Stock update history
├── constants.dart    # App constants and colors
└── main.dart         # App entry point
```

## 🚀 Setup & Installation

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd eafoods
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate required files**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📋 Features Implemented

### ✅ Core Requirements
- [x] **Stock View Screen**: Ops manager can update inventory levels
- [x] **Pre-Order Form**: Product search, slot selection, cut-off enforcement
- [x] **My Orders Screen**: View and cancel orders with offline support
- [x] **Offline-First**: Local SQLite database for offline functionality
- [x] **Business Logic**: Cut-off times, stock validation, delivery slots
- [x] **Order Management Screen**: Business operations (confirm, deliver, cancel)
- [x] **Stock History Screen**: Complete audit trail of stock changes

### 🎯 Key Features

#### Stock Management
- View all products with current stock levels
- Update stock levels with morning/evening updates
- Low stock and out-of-stock indicators
- Stock update history tracking

#### Pre-Order System
- Product search and filtering
- Shopping cart functionality
- Delivery slot selection (Morning 8-11, Afternoon 12-3, Evening 4-7)
- Cut-off time enforcement (6:00 PM)
- Customer information collection

#### Order Management
- View all orders with status tracking
- Cancel pending orders
- Offline order queuing
- Order synchronization when online

#### Offline Support
- Local SQLite database storage
- Offline order placement
- Automatic sync when connection restored
- Data persistence across app restarts
- Conflict resolution for duplicate orders

## 🧪 Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/product_test.dart

# Run with coverage
flutter test --coverage
```

### Test Coverage
- **Model Tests**: Product, Order, OrderItem, DeliverySlot models
- **Service Tests**: OrderService business logic validation
- **Widget Tests**: Basic UI component tests
- **Integration Tests**: Business logic scenarios (order placement, cancellation, stock updates)
- **Database Tests**: SQLite operations (requires device/emulator)

### Test Files Structure
```
test/
├── models/
│   ├── product_test.dart
│   └── order_test.dart
├── services/
│   ├── order_service_test.dart
│   └── database_service_test.dart
├── integration/
│   └── business_logic_test.dart
└── widget_test.dart
```

## 📱 Screenshots

### Main Screens
1. **Dashboard**: Overview with quick stats and actions
2. **Stock View**: Inventory management for ops managers
3. **Pre-Order Form**: Multi-step order placement process
4. **My Orders**: Order history and management

## 🔧 Configuration

### Environment Setup
The app is configured to work with:
- Local development environment
- Mock API endpoints (configurable in services)
- SQLite database for local storage
- Offline-first architecture

### API Configuration
Update API endpoints in:
- `lib/services/order_service.dart` - Order synchronization
- Mock server URL: `https://api.eafoods.com` (configurable)

## 📊 Design Notes

### Architecture Decisions

#### 1. **Offline-First Design**
**Decision**: Implemented offline-first architecture with SQLite local storage
**Rationale**: 
- Ensures app functionality in areas with poor connectivity
- Meets assignment requirement for offline capability
- Provides better user experience with instant responses
- Allows for data persistence across app restarts

**Implementation**:
- SQLite database for local data storage
- Order queuing system for offline orders
- Automatic synchronization when connection is available
- Conflict resolution using `ConflictAlgorithm.replace`

#### 2. **State Management: Provider Pattern**
**Decision**: Used Provider over Bloc/Riverpod/GetX
**Rationale**:
- Simpler learning curve and implementation
- Sufficient for the app's complexity level
- Built-in Flutter support with good documentation
- Easier to test and debug

**Implementation**:
- `ProductProvider`: Manages product state, filtering, and sorting
- `OrderProvider`: Handles order state, cart management, and synchronization
- Reactive UI updates with `Consumer` widgets

#### 3. **Database: SQLite over Hive**
**Decision**: Used SQLite via `sqflite` package instead of Hive
**Rationale**:
- Better for complex relational data (orders, order items, stock updates)
- More mature and stable for production use
- Better query performance for large datasets
- Standard SQL support for complex operations

**Implementation**:
- Four main tables: products, orders, order_items, stock_updates
- Foreign key relationships for data integrity
- Indexed queries for performance
- Transaction support for data consistency

#### 4. **Business Logic Separation**
**Decision**: Separated business logic into dedicated service classes
**Rationale**:
- Single Responsibility Principle
- Easier testing and maintenance
- Reusable across different UI components
- Clear separation of concerns

**Implementation**:
- `OrderService`: Order creation, validation, cancellation logic
- `DatabaseService`: All database operations
- Business rules centralized in service layer

### Assumptions Made

#### 1. **User Roles & Authentication**
**Assumption**: Simplified to two roles - Customer and Operations Manager
**Rationale**: Assignment focused on core functionality, not authentication
**Impact**: 
- No login/logout functionality
- Role-based access control not implemented
- All users have access to all features

#### 2. **Payment Integration**
**Assumption**: Payment processing not required
**Rationale**: Assignment focused on order flow and inventory management
**Impact**:
- Orders are placed without payment
- No payment status tracking
- Focus on stock management and delivery

#### 3. **Real-time Synchronization**
**Assumption**: Periodic sync instead of real-time updates
**Rationale**: Simpler implementation for assignment scope
**Impact**:
- Manual sync trigger required
- No WebSocket implementation
- Orders sync when user initiates

#### 4. **Product Images**
**Assumption**: Placeholder images for all products
**Rationale**: Focus on functionality over visual assets
**Impact**:
- No image upload functionality
- Static placeholder images
- No image optimization

#### 5. **Delivery Logistics**
**Assumption**: Simple delivery slot system
**Rationale**: Assignment focused on pre-order system
**Impact**:
- No GPS tracking
- No delivery route optimization
- No driver assignment system

### Trade-offs Made

#### 1. **Performance vs. Simplicity**
**Trade-off**: Chose simpler Provider over more complex Bloc
**Pros**: Easier to implement and maintain
**Cons**: Less scalable for very large applications
**Mitigation**: Can migrate to Bloc if needed in future

#### 2. **Offline vs. Real-time**
**Trade-off**: Prioritized offline functionality over real-time sync
**Pros**: Better user experience in poor connectivity
**Cons**: Data might be stale until sync
**Mitigation**: Clear indicators for offline status and sync state

#### 3. **Local Storage vs. Cloud Storage**
**Trade-off**: Local SQLite over cloud database
**Pros**: Works offline, faster queries, no network dependency
**Cons**: Data not shared across devices
**Mitigation**: Sync mechanism for data sharing

#### 4. **UI Complexity vs. Functionality**
**Trade-off**: Simple Material Design over custom UI
**Pros**: Consistent, accessible, faster development
**Cons**: Less unique visual identity
**Mitigation**: Custom colors and branding where appropriate

### Technical Constraints

#### 1. **Assignment Requirements**
- 24-hour time limit
- No external infrastructure
- Local development only
- Open-source libraries only

#### 2. **Flutter Limitations**
- SQLite requires device/emulator for testing
- No built-in offline sync mechanism
- Limited real-time capabilities without WebSocket

#### 3. **Development Environment**
- Single developer
- No collaboration tools
- Limited testing infrastructure

### Future Improvements

#### 1. **Authentication & Security**
- JWT-based authentication
- Role-based access control
- Biometric authentication
- Data encryption at rest

#### 2. **Real-time Features**
- WebSocket integration
- Push notifications
- Live order tracking
- Real-time stock updates

#### 3. **Advanced Features**
- Barcode scanning
- Image upload and management
- Advanced search and filtering
- Analytics and reporting
- Multi-language support

#### 4. **Performance Optimizations**
- Image caching and optimization
- Database query optimization
- Lazy loading for large datasets
- Background sync

#### 5. **Production Readiness**
- CI/CD pipeline
- Automated testing
- Error monitoring
- Performance monitoring
- Security scanning

## ⏱️ Time Spent

### Detailed Development Breakdown

#### **Phase 1: Project Setup & Architecture (2 hours)**
- **Environment Setup**: 30 minutes
  - Flutter project initialization
  - Dependencies configuration (Provider, SQLite, HTTP, etc.)
  - Project structure planning
- **Database Design**: 45 minutes
  - SQLite schema design
  - Table relationships planning
  - Migration strategy
- **Architecture Planning**: 45 minutes
  - State management strategy
  - Service layer design
  - File structure organization

#### **Phase 2: Data Models & Serialization (2.5 hours)**
- **Core Models**: 1.5 hours
  - Product model with JSON serialization
  - Order and OrderItem models
  - DeliverySlot model
  - StockUpdate model
- **Code Generation**: 30 minutes
  - build_runner setup
  - JSON serialization generation
  - Model testing
- **Model Validation**: 30 minutes
  - Business rule validation
  - Data integrity checks
  - Edge case handling

#### **Phase 3: Database Service Implementation (3 hours)**
- **Database Service**: 2 hours
  - SQLite initialization and setup
  - CRUD operations for all models
  - Transaction management
  - Error handling and logging
- **Data Seeding**: 30 minutes
  - Sample product data
  - Database initialization
  - Test data setup
- **Database Testing**: 30 minutes
  - Unit tests for database operations
  - Data integrity validation
  - Performance testing

#### **Phase 4: Business Logic Services (2.5 hours)**
- **Order Service**: 1.5 hours
  - Order creation and validation
  - Stock management logic
  - Cutoff time enforcement
  - Server synchronization
- **Stock Management**: 45 minutes
  - Stock update logic
  - Inventory tracking
  - Stock restoration on cancellation
- **Business Rules**: 15 minutes
  - Delivery date calculation
  - Order status management
  - Validation rules

#### **Phase 5: State Management (2 hours)**
- **Product Provider**: 1 hour
  - Product state management
  - Filtering and sorting
  - Search functionality
- **Order Provider**: 1 hour
  - Order state management
  - Cart functionality
  - Order synchronization
  - Error handling

#### **Phase 6: UI Screens Development (5 hours)**
- **Home Screen & Navigation**: 30 minutes
  - Bottom navigation setup
  - Screen routing
  - Dashboard layout
- **Stock View Screen**: 1.5 hours
  - Product list display
  - Stock update functionality
  - Search and filtering
  - History integration
- **Pre-Order Form Screen**: 2 hours
  - Multi-step form design
  - Product selection
  - Cart management
  - Customer details form
  - Delivery slot selection
- **My Orders Screen**: 1 hour
  - Order list display
  - Order status tracking
  - Cancellation functionality
- **Order Management Screen**: 30 minutes
  - Business operations interface
  - Order confirmation
  - Status management

#### **Phase 7: Additional Features (2 hours)**
- **Stock History Screen**: 45 minutes
  - Stock update history
  - Filtering by product
  - Audit trail display
- **Order Management Features**: 45 minutes
  - Business order operations
  - Status updates
  - Debug information
- **UI Polish**: 30 minutes
  - Error handling
  - Loading states
  - User feedback

#### **Phase 8: Testing Implementation (2.5 hours)**
- **Model Tests**: 1 hour
  - Product model tests
  - Order model tests
  - JSON serialization tests
- **Service Tests**: 1 hour
  - OrderService tests
  - DatabaseService tests
  - Business logic validation
- **Integration Tests**: 30 minutes
  - End-to-end scenarios
  - Business workflow tests
  - Error scenario testing

#### **Phase 9: Bug Fixes & Optimization (2 hours)**
- **Stock Reduction Fix**: 30 minutes
  - Fixed timing of stock reduction
  - Assignment compliance
- **UI Updates**: 45 minutes
  - Order cancellation UI refresh
  - Debug information addition
  - Error handling improvements
- **Code Quality**: 45 minutes
  - Linting fixes
  - Code optimization
  - Documentation updates

#### **Phase 10: Documentation & Finalization (1.5 hours)**
- **README Updates**: 1 hour
  - Comprehensive documentation
  - Design notes expansion
  - Setup instructions
- **Code Comments**: 30 minutes
  - Inline documentation
  - API documentation
  - Business logic explanations

### **Total Time Breakdown**
- **Core Development**: 18 hours
- **Testing**: 2.5 hours
- **Documentation**: 1.5 hours
- **Bug Fixes**: 2 hours

**Grand Total**: **24 hours**

### **Time Distribution**
- **Backend/Logic**: 40% (10 hours)
- **UI Development**: 20% (5 hours)
- **Testing**: 10% (2.5 hours)
- **Documentation**: 6% (1.5 hours)
- **Bug Fixes**: 8% (2 hours)
- **Setup/Planning**: 16% (4 hours)

### **Key Learning Points**
1. **SQLite Integration**: More complex than expected, required careful transaction management
2. **State Management**: Provider pattern worked well for this scope
3. **Testing**: Database tests require device/emulator, not just unit tests
4. **Business Logic**: Stock management timing was critical for assignment compliance
5. **Offline-First**: Required careful consideration of sync strategies and conflict resolution

## 🚀 Deployment

### Building APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

### APK Location
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

## 📝 Assignment Compliance

### ✅ Requirements Met
- [x] **3 Required Screens**: Stock View, Pre-Order Form, My Orders
- [x] **Offline-First**: SQLite local database with offline functionality
- [x] **Sample Products**: 5+ products seeded in database
- [x] **Delivery Slots**: Morning (8-11), Afternoon (12-3), Evening (4-7)
- [x] **Cut-off Rule**: Orders after 6 PM go to +2 days
- [x] **Stock Updates**: Morning/evening updates by ops managers
- [x] **Clean Code**: Modular, well-structured, documented
- [x] **Testing**: Unit tests, integration tests, widget tests
- [x] **Linting**: flutter_lints configured and enforced
- [x] **No External Infra**: All local development
- [x] **Open Source**: All dependencies are open-source
- [x] **Business Logic**: Stock-driven orders, order cancellation, stock restoration

### 📋 Example Scenarios Covered
1. ✅ Place order within stock (success)
2. ✅ Place order exceeding stock (rejected)
3. ✅ Place order after cut-off (pushed to +2 days)
4. ✅ Cancel order (restores stock)
5. ✅ Ops updates stock (reflected in availability)

## 🤝 Contributing

This is a technical assignment project. For production use, consider:
- Adding comprehensive error handling
- Implementing proper authentication
- Adding unit test coverage
- Setting up CI/CD pipeline
- Adding performance monitoring

## 📄 License

This project is created for technical assessment purposes.

---

**Built with ❤️ for EA Foods Flutter Engineer Position**
