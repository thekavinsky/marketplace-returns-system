# Модель данных

SQL-скрипт находится в [database/schema.sql](../database/schema.sql).

## Основные таблицы

### `return_request`

Основная информация о заявке: покупатель, заказ, статус, способ передачи и сумма возврата.

### `return_item`

Позиции, которые покупатель хочет вернуть. Цена сохраняется в заявке, чтобы потом правильно рассчитать сумму.

### `return_status_history`

История смены статусов. Нужна для поддержки и разбора проблем.

### `inspection_item`

Результат проверки каждой позиции на складе: сколько получили, сколько приняли и почему могли отказать.

### `refund`

Информация о запросе на возврат денег и ответе Payment Service.

## Связи

```mermaid
erDiagram
    RETURN_REQUEST ||--|{ RETURN_ITEM : contains
    RETURN_REQUEST ||--|{ RETURN_STATUS_HISTORY : has
    RETURN_REQUEST ||--o{ INSPECTION_ITEM : checked
    RETURN_REQUEST ||--o| REFUND : creates
    RETURN_ITEM ||--o| INSPECTION_ITEM : result

    RETURN_REQUEST {
        uuid id PK
        uuid customer_id
        uuid order_id
        string status
        decimal refund_amount
    }
    RETURN_ITEM {
        uuid id PK
        uuid return_request_id FK
        uuid order_item_id
        int quantity
        decimal unit_price
    }
    RETURN_STATUS_HISTORY {
        uuid id PK
        uuid return_request_id FK
        string status
        datetime changed_at
    }
    INSPECTION_ITEM {
        uuid id PK
        uuid return_item_id FK
        int accepted_quantity
        string result
    }
    REFUND {
        uuid id PK
        uuid return_request_id FK
        decimal amount
        string status
    }
```

Деньги хранятся в `numeric(12,2)`, потому что тип `float` может давать неточность при расчётах.

