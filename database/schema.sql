-- Упрощённая схема БД для учебного проекта ReturnFlow

CREATE TABLE return_request (
    id                    uuid PRIMARY KEY,
    customer_id           uuid NOT NULL,
    order_id              uuid NOT NULL,
    status                varchar(40) NOT NULL,
    handover_method       varchar(20) NOT NULL,
    handover_location_id  uuid NOT NULL,
    refund_amount         numeric(12,2) NOT NULL DEFAULT 0,
    currency              char(3) NOT NULL DEFAULT 'RUB',
    rejection_reason      varchar(500),
    created_at            timestamptz NOT NULL DEFAULT now(),
    updated_at            timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT check_return_status CHECK (status IN (
        'CREATED', 'APPROVED', 'REJECTED', 'WAITING_FOR_ITEM',
        'IN_TRANSIT', 'RECEIVED', 'CHECKED', 'REFUND_IN_PROGRESS',
        'COMPLETED', 'COMPLETED_WITHOUT_REFUND', 'CANCELLED'
    )),
    CONSTRAINT check_handover_method CHECK (
        handover_method IN ('COURIER', 'PICKUP_POINT')
    ),
    CONSTRAINT check_refund_amount CHECK (refund_amount >= 0),
    CONSTRAINT check_currency CHECK (currency = 'RUB')
);

CREATE TABLE return_item (
    id                  uuid PRIMARY KEY,
    return_request_id   uuid NOT NULL REFERENCES return_request(id),
    order_item_id       uuid NOT NULL,
    item_name           varchar(300) NOT NULL,
    quantity            integer NOT NULL,
    reason_code         varchar(30) NOT NULL,
    comment             varchar(500),
    photo_url           varchar(1000),
    unit_price          numeric(12,2) NOT NULL,

    CONSTRAINT unique_return_item UNIQUE (return_request_id, order_item_id),
    CONSTRAINT check_item_quantity CHECK (quantity > 0),
    CONSTRAINT check_item_price CHECK (unit_price >= 0),
    CONSTRAINT check_reason_code CHECK (
        reason_code IN ('DEFECT', 'DAMAGED', 'WRONG_ITEM', 'NOT_FIT', 'OTHER')
    )
);

CREATE TABLE return_status_history (
    id                  uuid PRIMARY KEY,
    return_request_id   uuid NOT NULL REFERENCES return_request(id),
    status              varchar(40) NOT NULL,
    changed_by          varchar(100) NOT NULL,
    changed_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE inspection_item (
    id                  uuid PRIMARY KEY,
    return_request_id   uuid NOT NULL REFERENCES return_request(id),
    return_item_id      uuid NOT NULL UNIQUE REFERENCES return_item(id),
    received_quantity   integer NOT NULL,
    accepted_quantity   integer NOT NULL,
    result              varchar(20) NOT NULL,
    rejection_reason    varchar(500),
    checked_at          timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT check_inspection_result CHECK (
        result IN ('ACCEPTED', 'PARTIAL', 'REJECTED')
    ),
    CONSTRAINT check_inspection_quantity CHECK (
        received_quantity >= 0
        AND accepted_quantity >= 0
        AND accepted_quantity <= received_quantity
    )
);

CREATE TABLE refund (
    id                  uuid PRIMARY KEY,
    return_request_id   uuid NOT NULL UNIQUE REFERENCES return_request(id),
    payment_refund_id   varchar(100),
    amount              numeric(12,2) NOT NULL,
    status              varchar(20) NOT NULL,
    error_message       varchar(500),
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT check_refund_status CHECK (
        status IN ('CREATED', 'SUCCESS', 'FAILED')
    ),
    CONSTRAINT check_refund_sum CHECK (amount > 0)
);

CREATE INDEX index_return_by_customer
    ON return_request(customer_id, created_at DESC);

CREATE INDEX index_return_by_order
    ON return_request(order_id);

CREATE INDEX index_status_history
    ON return_status_history(return_request_id, changed_at);

