--PART 3
--TASK 3.1

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob',   500.00),
    ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke',  2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);

--TASK 3.2

BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';

UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
COMMIT;

/*
    a)
    Alice: 1000.00 − 100.00 = 900.00
    Bob: 500.00 + 100.00 = 600.00

    b)
    Because they logically represent one operation: a money transfer. If they are inside one transaction, then:
	Either both updates are applied,
	Or none are applied (if there is an error → ROLLBACK).

    c)
    If there is no transaction, each UPDATE is independent.
    Possible situation:
	The first UPDATE runs: Alice’s balance becomes 900.00.
	Before the second UPDATE runs, the system crashes.
    Alice: 900.00 (money already taken)
	Bob: 500.00 (money not received)
 */

 --Task 3.3

BEGIN;
UPDATE accounts SET balance = balance - 500.00
WHERE name = 'Alice';

SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;

SELECT * FROM accounts WHERE name = 'Alice';

/*
 a)
 Initial balance: 1000.00
 900.00 − 500.00 = 400.00

 b)
 ROLLBACK cancels all changes made in the current transaction.
 So Alice’s balance: 900

 c)
 You use ROLLBACK whenever you detect that the transaction should not be saved, for example:
	You discover a wrong amount or wrong account
	One of several operations in the transaction fails
	A business rule is not satisfied
	The user cancels the operation before it finishes.
 */

 --TASK 3.4

BEGIN;
UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
SAVEPOINT my_savepoint;

UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Bob';
-- Oops, should transfer to Wally instead
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Wally';
COMMIT;

/*
 a) After COMMIT, what are the balances of Alice, Bob, and Wally?
	Alice: 800.00
	Bob: 600.00
	Wally: 850.00

 b) Yes, Bob was temporarily credited to 700.
	Final committed state: no, because ROLLBACK TO my_savepoint undid the update that added 100 to Bob.
    So after commit Bob is back to 600.00.

 c) A SAVEPOINT lets you:
	Roll back only part of the work inside a transaction.
	Keep earlier correct changes (like Alice −100) and only undo the mistaken steps.
	Avoid restarting the whole transaction and repeating all previous operations.
 */

 --TASK 3.5

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
/*
    a)
    Before:
		Coke – 2.50
	    Pepsi – 3.00
    After:
        Fanta – 3.50

    b)
    Both SELECTs in Terminal 1 return the same original data, even after Terminal 2 commits:
		Coke – 2.50
		Pepsi – 3.00
    Terminal 1 does not see Fanta inside this transaction.

    c)
    READ COMMITTED: each query sees the latest committed data, so results can change inside one transaction.
	SERIALIZABLE: the whole transaction works on one consistent snapshot,
     so repeated queries see the same data and it behaves as if transactions run one after another.
 */

 --TASK 3.6

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products
  WHERE shop = 'Joe''s Shop';
-- wait for Terminal 2
SELECT MAX(price), MIN(price) FROM products
  WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;

/*
    a)
    No. Under REPEATABLE READ, Terminal 1 uses the same snapshot of data for both SELECTs,
    so it does not see the row with Sprite, 4.00. The first and second MAX/MIN results are the same.

    b)
    A phantom read happens when, inside one transaction, you run the same query twice and:
	    another committed transaction inserts or deletes rows that match the condition,
	    so the set of rows changes between the two reads

    c)
    The isolation level that (theoretically) prevents phantom reads is SERIALIZABLE.
 */

 --TASK 3.7

BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
UPDATE products SET price = 99.99
WHERE product = 'Fanta';
-- Wait here (don't commit yet)
-- Then:
ROLLBACK;

/*
    a) This is problematic because any decisions, reports, or calculations based on 99.99 are wrong and inconsistent.
    b) A dirty read is when a transaction reads data that was written by another transaction that has not committed yet.
    c) Because READ UNCOMMITTED allows dirty reads, so:
		queries can return incorrect, unstable data,
		logic and reports may be based on values that will later be rolled back,
		it becomes hard to trust the data and reason about correctness.
 */

--PART 4
--TASK 4.1

BEGIN;
UPDATE accounts
SET balance = balance - 200
WHERE name = 'Bob'
  AND balance >= 200;
UPDATE accounts
SET balance = balance + 200
WHERE name = 'Wally';

COMMIT;

--TASK 4.2

BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Water', 2.00);

SAVEPOINT sp1;

UPDATE products
SET price = 2.50
WHERE shop = 'Joe''s Shop' AND product = 'Water';

SAVEPOINT sp2;

DELETE FROM products
WHERE shop = 'Joe''s Shop' AND product = 'Water';

ROLLBACK TO sp1;

COMMIT;

--TASK 4.3

UPDATE accounts
SET balance = 300
WHERE name = 'Alice';

SELECT * FROM accounts WHERE name = 'Alice';


--Scenario 1

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Check balance
SELECT balance FROM accounts WHERE name = 'Alice';
-- sees 300

-- Decide to withdraw 200
UPDATE accounts
SET balance = balance - 200
WHERE name = 'Alice';

COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Check balance (still 300, because T1 hasn’t committed yet or just did)
SELECT balance FROM accounts WHERE name = 'Alice';
-- sees 300

-- Also withdraws 200
UPDATE accounts
SET balance = balance - 200
WHERE name = 'Alice';

COMMIT;

SELECT balance FROM accounts WHERE name = 'Alice';
-- balance = -100


--READ COMMITTED does not protect from this business-logic problem.

--Scenario 2

UPDATE accounts
SET balance = 300
WHERE name = 'Alice';

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts
SET balance = balance - 200
WHERE name = 'Alice';

COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts
SET balance = balance - 200
WHERE name = 'Alice';
-- here PostgreSQL will usually raise an error like:
-- ERROR: could not serialize access due to concurrent update

ROLLBACK;

SELECT balance FROM accounts WHERE name = 'Alice';
-- balance = 100

/*
 Two users try to withdraw $200 from the same account (starting balance $300).
Under READ COMMITTED, both transactions succeed and the final balance becomes −$100.
Under SERIALIZABLE, one transaction commits and the other gets a serialization error, so the final balance is $100 and no overdraft occurs.
 */

--TASK 4.4
CREATE TABLE sells (
    shop    VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price   DECIMAL(10,2) NOT NULL
);

INSERT INTO sells (shop, product, price) VALUES
('Shop1', 'A', 10),
('Shop1', 'B', 20);


--Without proper transactions (bad case)

SELECT MAX(price) AS max_price
FROM Sells
WHERE shop = 'Shop1';

-- Joe increases all prices
UPDATE Sells
SET price = price + 20
WHERE shop = 'Shop1';
-- prices become 30 and 40

SELECT MIN(price) AS min_price
FROM Sells
WHERE shop = 'Shop1';
-- returns 30
/*
 Sally’s notes:
		MAX = 20
		MIN = 30
 */

--With transactions (fixed)

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT MAX(price) AS max_price
FROM Sells
WHERE shop = 'Shop1';   -- sees 20

-- Joe can update in another terminal here ...

SELECT MIN(price) AS min_price
FROM Sells
WHERE shop = 'Shop1';   -- still sees 10 in the same snapshot

COMMIT;

UPDATE Sells
SET price = price + 20
WHERE shop = 'Shop1';
COMMIT;

/*
    during Sally’s transaction, her second query still uses the same snapshot:
		MAX = 20
		MIN = 10

 */

 --PART 5

/*
 1. Explain each ACID property with a practical example.
	Atomicity – “all or nothing”.
Example: transfer 100 from Alice to Bob (two UPDATEs). Either both balances change or none change.
	Consistency – database moves from one valid state to another (constraints stay true).
Example: a transfer never creates or destroys money; total balance of all accounts stays the same.
	Isolation – concurrent transactions don’t interfere logically.
Example: two people buying the same ticket don’t both see it as “free” at the same time.
	Durability – once committed, changes survive crashes.
Example: after COMMIT of a transfer, the new balances are still there after server restart.

2. What is the difference between COMMIT and ROLLBACK?
	COMMIT: permanently saves all changes in the current transaction.
	ROLLBACK: cancels the transaction and undoes all its changes as if it never happened.

3. When would you use a SAVEPOINT instead of a full ROLLBACK?
When part of a transaction is wrong but earlier work is correct.
Example: you already debited Alice, then accidentally credited Bob instead of Wally.
You set a SAVEPOINT after debiting Alice → rollback to that savepoint → only redo the credit part, not the whole transaction.

4. Compare and contrast the four SQL isolation levels.
	READ UNCOMMITTED – can see uncommitted changes from other transactions (dirty reads allowed).
	READ COMMITTED – each statement sees only committed data, but repeated queries can see different results.
	REPEATABLE READ – within one transaction, the same row read twice will not change (no dirty or non-repeatable reads; phantoms may still appear depending on DB).
	SERIALIZABLE – strongest; transactions behave as if executed one by one in some order (no dirty reads, non-repeatable reads, or phantoms).

5. What is a dirty read and which isolation level allows it?
	Dirty read: reading data that another transaction has written but not committed yet.
If that other transaction rolls back, the read value was never “real”.
	Allowed by READ UNCOMMITTED.

6. What is a non-repeatable read? Give an example scenario.
	Non-repeatable read: in one transaction you read the same row twice and get different values because another committed transaction updated it in between.
	Example:
T1: SELECT balance FROM accounts WHERE name = 'Alice'; → 900
T2: updates Alice to 800 and commits
T1: same SELECT again → 800
So the read is not repeatable.

7. What is a phantom read? Which isolation levels prevent it?
	Phantom read: re-running a query that selects a set of rows and getting a different set
	Prevented (in theory / by definition) by SERIALIZABLE.
Weaker levels may allow it.

8. Why might you choose READ COMMITTED over SERIALIZABLE in a high-traffic application?
Because READ COMMITTED:
	uses fewer locks / less conflict,
	allows more concurrency and higher throughput,
	reduces risk of serialization failures that force transactions to retry.
So it’s often a good balance between correctness and performance.

9. Explain how transactions help maintain database consistency during concurrent access.
Transactions:
	group multiple operations into one atomic unit,
	ensure constraints are checked on the final state,
	isolate concurrent operations so that partial updates are not visible,
	allow you to roll back if something goes wrong.
Together this prevents inconsistent states (like money disappearing when two users transfer at the same time).

10. What happens to uncommitted changes if the database system crashes?
All uncommitted changes are rolled back automatically.
After restart, only committed transactions are kept; any in-progress transactions are discarded so the database returns to a consistent state.
 */