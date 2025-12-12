SET client_min_messages = WARNING;

CREATE TABLE IF NOT EXISTS customers (
  customer_id SERIAL PRIMARY KEY,
  iin CHAR(12) UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  status TEXT NOT NULL CHECK (status IN ('active','blocked','frozen')),
  created_at TIMESTAMPTZ DEFAULT now(),
  daily_limit_kzt NUMERIC(18,2) NOT NULL DEFAULT 1000000.00
);

CREATE TABLE IF NOT EXISTS accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number VARCHAR(34) UNIQUE NOT NULL,
    currency TEXT NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    balance DECIMAL(20, 2) DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount DECIMAL(20, 2) NOT NULL,
    currency TEXT NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    exchange_rate DECIMAL(18, 8),
    amount_kzt DECIMAL(20, 2),
    type TEXT NOT NULL CHECK (type IN ('transfer','deposit','withdrawal','salary')),
    status TEXT NOT NULL CHECK (status IN ('pending','completed','failed','reversed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    description TEXT
);

CREATE TABLE IF NOT EXISTS exchange_rates (
  rate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_currency TEXT NOT NULL CHECK (from_currency IN ('KZT','USD','EUR','RUB')),
  to_currency TEXT NOT NULL CHECK (to_currency IN ('KZT','USD','EUR','RUB')),
  rate NUMERIC(18,8) NOT NULL, -- multiplier: amount_in_from * rate => amount_in_to
  valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
  valid_to TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS audit_log (
  log_id BIGSERIAL PRIMARY KEY,
  table_name TEXT,
  record_id TEXT,
  action TEXT CHECK (action IN ('INSERT','UPDATE','DELETE','PROC')) NOT NULL,
  old_values JSONB,
  new_values JSONB,
  changed_by TEXT,
  changed_at TIMESTAMPTZ DEFAULT now(),
  ip_address TEXT
);

INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt)
VALUES
 ('010101010101', 'Number one', '+7-701-111-11-11', 'one@email.com','active', 1000000),
 ('020202020202', 'Number two', '+7-702-222-22-22', 'two@email.com', 'active', 2000000),
 ('030303030303', 'Number three', '+7-703-333-33-33', 'three@email.com', 'frozen', 1500000),
 ('040404040404', 'Number four', '+7-704-444-44-44', 'four@email.com', 'active', 2900000),
 ('050505050505', 'Number five', '+7-705-555-55-55', 'five@email.com', 'active', 2000000),
 ('060606060606', 'Number six', '+7-706-666-66-66', 'six@email.com', 'blocked', 2500000),
 ('070707070707', 'Number seven', '+7-707-777-77-77', 'seven@email.com', 'active', 1900000),
 ('080808080808', 'Number eight', '+7-708-888-88-88', 'eight@email.com', 'blocked', 4000000),
 ('090909090909', 'Number nine', '+7-709-999-99-99', 'nine@email.com', 'frozen', 7000000),
 ('101010101010', 'Number ten', '+7-710-000-00-00', 'ten@email.com', 'active', 2000000);


INSERT INTO accounts (customer_id, account_number, currency, balance, is_active)
SELECT customer_id,
       'KZ' || right(md5(iin || now()::text), 18),
       CASE (row_number() OVER (ORDER BY customer_id) % 4)
            WHEN 0 THEN 'USD'
            WHEN 1 THEN 'KZT'
            WHEN 2 THEN 'EUR'
            ELSE 'RUB'
       END,
       100000 + (row_number() OVER (ORDER BY customer_id) * 5000),
       true
FROM customers;

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from)
VALUES
('USD','KZT', 470.00, now() - interval '1 day'),
('EUR','KZT', 500.00, now() - interval '1 day'),
('RUB','KZT', 6.00, now() - interval '1 day'),
('KZT','KZT', 1.0, now() - interval '10 year'),
('USD','EUR', 0.94, now() - interval '1 day'),
('EUR','USD', 1.06, now() - interval '1 day');

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, completed_at, description)
SELECT a1.account_id, a2.account_id, 1000 + (i*500), a1.currency,
  (SELECT rate FROM exchange_rates r WHERE r.from_currency = a1.currency AND r.to_currency = 'KZT' ORDER BY valid_from DESC LIMIT 1),
  ((1000 + i*500) * (SELECT rate FROM exchange_rates r WHERE r.from_currency = a1.currency AND r.to_currency = 'KZT' ORDER BY valid_from DESC LIMIT 1))::numeric(20,2),
  'transfer', 'completed',
  now() - (i || ' hours')::interval, now() - ((i-1) || ' hours')::interval, 'test transfer'
FROM (SELECT row_number() OVER () as i FROM generate_series(1,12)) g
CROSS JOIN LATERAL (
  SELECT a1.account_id, a1.currency
  FROM accounts a1
  ORDER BY random() LIMIT 1
) a1
CROSS JOIN LATERAL (
  SELECT a2.account_id FROM accounts a2 WHERE a2.account_id <> a1.account_id ORDER BY random() LIMIT 1
) a2;


--TASK 1
CREATE OR REPLACE PROCEDURE process_transfer(
    p_from_account TEXT,
    p_to_account   TEXT,
    p_amount       NUMERIC,
    p_currency     TEXT,
    p_description  TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_id      INT;
    v_to_id        INT;
    v_from_balance NUMERIC;
    v_to_balance   NUMERIC;
    v_from_currency TEXT;
    v_to_currency   TEXT;
    v_rate NUMERIC := 1;
    v_amount_kzt NUMERIC;
    v_daily_limit NUMERIC;
    v_today_total NUMERIC;
    v_customer_status TEXT;
BEGIN

    SELECT account_id, currency, balance
    INTO v_from_id, v_from_currency, v_from_balance
    FROM accounts
    WHERE account_number = p_from_account AND is_active = TRUE
    FOR UPDATE;

    IF v_from_id IS NULL THEN
        RAISE EXCEPTION 'Sender account not found or inactive'
            USING ERRCODE = 'P0001';
    END IF;

    SELECT account_id, currency, balance
    INTO v_to_id, v_to_currency, v_to_balance
    FROM accounts
    WHERE account_number = p_to_account AND is_active = TRUE
    FOR UPDATE;

    IF v_to_id IS NULL THEN
        RAISE EXCEPTION 'Receiver account not found or inactive'
            USING ERRCODE = 'P0002';
    END IF;

    SELECT status, daily_limit_kzt
    INTO v_customer_status, v_daily_limit
    FROM customers c
    JOIN accounts a ON a.customer_id = c.customer_id
    WHERE a.account_id = v_from_id;

    IF v_customer_status <> 'active' THEN
        RAISE EXCEPTION 'Customer is blocked/frozen'
            USING ERRCODE = 'P0003';
    END IF;

    SELECT COALESCE(SUM(amount_kzt), 0)
    INTO v_today_total
    FROM transactions
    WHERE from_account_id = v_from_id
      AND created_at::date = CURRENT_DATE;

    IF p_currency <> 'KZT' THEN
        SELECT rate INTO v_rate
        FROM exchange_rates
        WHERE from_currency = p_currency
          AND to_currency = 'KZT'
        ORDER BY valid_from DESC
        LIMIT 1;
    END IF;

    v_amount_kzt := p_amount * v_rate;

    IF v_today_total + v_amount_kzt > v_daily_limit THEN
        RAISE EXCEPTION 'Daily limit exceeded'
            USING ERRCODE = 'P0004';
    END IF;

    IF v_from_currency <> p_currency THEN
        SELECT rate INTO v_rate
        FROM exchange_rates
        WHERE from_currency = p_currency
          AND to_currency = v_from_currency
        LIMIT 1;

        p_amount := p_amount * v_rate;
    END IF;

    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds'
            USING ERRCODE = 'P0005';
    END IF;

    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = v_from_id;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = v_to_id;

    INSERT INTO transactions(from_account_id, to_account_id, amount, currency, amount_kzt, status, description, created_at)
    VALUES
    (v_from_id, v_to_id, p_amount, p_currency,v_amount_kzt, 'completed', p_description, NOW());

    INSERT INTO audit_log(
        table_name, record_id, action,
        old_values, new_values, changed_at, ip_address
    )
    VALUES (
        'transactions', currval('transactions_transaction_id_seq'),
        'INSERT', NULL, jsonb_build_object(
            'from', p_from_account,
            'to', p_to_account,
            'amount', p_amount
        ),
        NOW(), '127.0.0.1'
    );

END;
$$;

--TASK 2

CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
  c.customer_id,
  c.full_name,
  c.iin,
  c.status,
  jsonb_agg(jsonb_build_object('account_number', a.account_number, 'currency', a.currency, 'balance', a.balance) ORDER BY a.account_number) FILTER (WHERE a.account_id IS NOT NULL) AS accounts,
  SUM( (a.balance * COALESCE((SELECT rate FROM exchange_rates r WHERE r.from_currency = a.currency AND r.to_currency = 'KZT' ORDER BY valid_from DESC LIMIT 1),1.0)) ) AS total_balance_kzt,
  (COALESCE( (SELECT SUM(t.amount_kzt) FROM transactions t JOIN accounts a2 ON a2.account_id = t.from_account_id WHERE a2.customer_id = c.customer_id AND t.created_at::date = now()::date AND t.status='completed'),0)
    / NULLIF(c.daily_limit_kzt,0))::NUMERIC(5,4) AS daily_limit_utilization,
  RANK() OVER (ORDER BY SUM( (a.balance * COALESCE((SELECT rate FROM exchange_rates r WHERE r.from_currency = a.currency AND r.to_currency = 'KZT' ORDER BY valid_from DESC LIMIT 1),1.0)) ) DESC) AS balance_rank
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.iin, c.status, c.daily_limit_kzt;

CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
    date_trunc('day', created_at) AS day,
    type,
    COUNT(*) AS transaction_count,
    SUM(amount_kzt) AS total_amount_kzt,
    AVG(amount_kzt) AS average_amount_kzt,
    SUM(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)) AS running_total_kzt,
    (SUM(amount_kzt) -
        LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)))
        / NULLIF(LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)), 0)
        * 100 AS daily_growth_percent
FROM transactions
GROUP BY date_trunc('day', created_at), type;

CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
SELECT t.transaction_id, t.from_account_id, t.to_account_id, t.amount, t.currency, t.amount_kzt, t.created_at, t.status,
  (t.amount_kzt > 5000000) AS large_tx_flag,
  (SELECT COUNT(*) FROM transactions t2 WHERE t2.from_account_id = t.from_account_id AND t2.created_at >= t.created_at - interval '1 hour' AND t2.created_at <= t.created_at) AS txs_last_hour,
  EXISTS (
    SELECT 1 FROM transactions t3
    WHERE t3.from_account_id = t.from_account_id
      AND t3.transaction_id <> t.transaction_id
      AND abs(EXTRACT(EPOCH FROM (t3.created_at - t.created_at))) < 60
  ) AS rapid_sequence_flag
FROM transactions t
WHERE t.status = 'completed';

-- TASK 3

CREATE INDEX IF NOT EXISTS idx_accounts_account_number_hash ON accounts USING HASH (account_number);

CREATE INDEX IF NOT EXISTS idx_accounts_active_by_customer ON accounts (customer_id) WHERE is_active;

CREATE INDEX IF NOT EXISTS idx_tx_from_date ON transactions (from_account_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_auditlog_newvalues_gin ON audit_log USING GIN (new_values);

CREATE INDEX IF NOT EXISTS idx_customers_email_lower ON customers (lower(email));

CREATE INDEX IF NOT EXISTS idx_accounts_acctnum_cover ON accounts (account_number) INCLUDE (balance);

CREATE INDEX IF NOT EXISTS idx_tx_amount_kzt_large ON transactions (amount_kzt) WHERE amount_kzt > 5000000;

CREATE OR REPLACE PROCEDURE process_salary_batch(
    p_company_account_number TEXT,
    p_payments JSONB
)

LANGUAGE plpgsql
AS $$
DECLARE
    v_company_balance NUMERIC;
    v_payment RECORD;
    v_from_account_id INT;
    v_to_account_id INT;
    v_iin TEXT;
    v_amount NUMERIC;
    v_description TEXT;
    v_successful_count INT := 0;
    v_failed_count INT := 0;
    v_failed_details JSONB := '[]'::JSONB;
    v_total_batch_amount NUMERIC := 0;
    v_payment_amount NUMERIC;
BEGIN
    SELECT account_id, balance INTO v_from_account_id, v_company_balance
    FROM accounts
    WHERE account_number = p_company_account_number AND is_active = TRUE
    FOR UPDATE;

    IF v_from_account_id IS NULL THEN
        RAISE EXCEPTION 'Company account not found or inactive';
    END IF;

    FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments) AS payment
    LOOP
        v_total_batch_amount := v_total_batch_amount + (v_payment->>'amount')::NUMERIC;
    END LOOP;

    IF v_total_batch_amount > v_company_balance THEN
        RAISE EXCEPTION 'Insufficient funds in company account';
    END IF;

    FOREACH v_payment IN ARRAY p_payments
    LOOP
        SAVEPOINT process_payment;

        BEGIN
            v_iin := v_payment->>'iin';
            v_amount := (v_payment->>'amount')::NUMERIC;
            v_description := v_payment->>'description';
]
            SELECT a.account_id INTO v_to_account_id
            FROM accounts a
            JOIN customers c ON a.customer_id = c.customer_id
            WHERE c.iin = v_iin AND a.is_active = TRUE
            FOR UPDATE;

            IF v_to_account_id IS NULL THEN
                v_failed_count := v_failed_count + 1;
                v_failed_details := v_failed_details || jsonb_build_object('iin', v_iin, 'error', 'Employee account not found or inactive');
                CONTINUE; 
            END IF;

            UPDATE accounts SET balance = balance - v_amount
            WHERE account_id = v_from_account_id;

            UPDATE accounts SET balance = balance + v_amount
            WHERE account_id = v_to_account_id;

            INSERT INTO transactions (from_account_id, to_account_id, amount, currency, amount_kzt, status, description, created_at)
            VALUES (v_from_account_id, v_to_account_id, v_amount, 'KZT', v_amount, 'completed', v_description, NOW());

            v_successful_count := v_successful_count + 1;

            RELEASE SAVEPOINT process_payment;

        EXCEPTION WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT process_payment;
            v_failed_count := v_failed_count + 1;
            v_failed_details := v_failed_details || jsonb_build_object('iin', v_iin, 'error', SQLERRM);
        END;
    END LOOP;

    UPDATE accounts SET balance = balance - v_total_batch_amount
    WHERE account_id = v_from_account_id;

    RAISE NOTICE 'Batch Processing Complete: % Successful, % Failed', v_successful_count, v_failed_count;
    RETURN QUERY SELECT v_successful_count, v_failed_count, v_failed_details;

END;
$$;

CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT
    company_account_number,
    COUNT(*) AS successful_count,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed_count,
    jsonb_agg(failed_details) AS failed_details
FROM salary_batch_log
GROUP BY company_account_number;

