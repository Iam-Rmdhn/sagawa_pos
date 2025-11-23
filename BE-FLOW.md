┌─────────────────────────────────────────────────────────────┐
│                    VPS Backend (Go)                         │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐    ┌──────────────────────────────┐  │
│  │ Web Dashboard    │    │  REST API                    │  │
│  │ Admin            │───▶│  - Auth (JWT)                │  │
│  │ (React/Vue)      │    │  - Accounts Management       │  │
│  │                  │    │  - Menu Management           │  │
│  │ - Create Account │    │  - Orders                    │  │
│  │ - Set Menu Type  │    │  - Products                  │  │
│  │ - Manage Menu    │    │  - Reports                   │  │
│  └──────────────────┘    └──────────────────────────────┘  │
│                                    │                         │
│  ┌─────────────────────────────────▼──────────────────────┐ │
│  │          Database (PostgreSQL/Cassandra)               │ │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  │ │
│  │  │  accounts   │  │  products    │  │   orders     │  │ │
│  │  ├─────────────┤  ├──────────────┤  ├──────────────┤  │ │
│  │  │ id          │  │ id           │  │ id           │  │ │
│  │  │ user_id     │  │ account_id   │  │ account_id   │  │ │
│  │  │ name        │  │ name         │  │ total        │  │ │
│  │  │ partner_type│  │ category     │  │ items        │  │ │
│  │  │ menu_type   │  │ price        │  │ created_at   │  │ │
│  │  │ status      │  │ menu_type    │  │              │  │ │
│  │  └─────────────┘  └──────────────┘  └──────────────┘  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS API
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Flutter POS App (Mobile/Tablet)                │
├─────────────────────────────────────────────────────────────┤
│  Login (User ID: 12345 / 09876)                             │
│         │                                                    │
│         ▼                                                    │
│  POST /api/auth/login                                        │
│  Response: { token, account_id, menu_type, partner_type }   │
│         │                                                    │
│         ▼                                                    │
│  Store: SharedPreferences (token, account_info)             │
│         │                                                    │
│         ▼                                                    │
│  GET /api/products?account_id=12345&menu_type=warteg        │
│  Response: [ { id, name, price, category, image } ]         │
│         │                                                    │
│         ▼                                                    │
│  Display Menu (Warteg / Japanese) sesuai menu_type          │
│         │                                                    │
│         ▼                                                    │
│  POST /api/orders (with account_id in header/body)          │
│  Response: { order_id, total, status }                      │
└─────────────────────────────────────────────────────────────┘