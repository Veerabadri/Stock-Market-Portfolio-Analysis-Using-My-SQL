CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stocks (
    stock_id INT AUTO_INCREMENT PRIMARY KEY,
    ticker_symbol VARCHAR(15) UNIQUE NOT NULL,
    company_name VARCHAR(150) NOT NULL,
    sector VARCHAR(50),
    exchange VARCHAR(20)
);

CREATE TABLE portfolios (
    portfolio_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    portfolio_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    portfolio_id INT NOT NULL,
    stock_id INT NOT NULL,
    transaction_type ENUM('BUY','SELL') NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price_per_share DECIMAL(10,2) NOT NULL,
    transaction_date DATE NOT NULL,
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id) ON DELETE CASCADE,
    FOREIGN KEY (stock_id) REFERENCES stocks(stock_id)
);

CREATE TABLE stock_prices (
    price_id INT AUTO_INCREMENT PRIMARY KEY,
    stock_id INT NOT NULL,
    price_date DATE NOT NULL,
    open_price DECIMAL(10,2),
    close_price DECIMAL(10,2),
    high_price DECIMAL(10,2),
    low_price DECIMAL(10,2),
    volume BIGINT,
    FOREIGN KEY (stock_id) REFERENCES stocks(stock_id),
    UNIQUE KEY unique_stock_date (stock_id, price_date)
);

CREATE TABLE dividends (
    dividend_id INT AUTO_INCREMENT PRIMARY KEY,
    stock_id INT NOT NULL,
    dividend_date DATE NOT NULL,
    amount_per_share DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (stock_id) REFERENCES stocks(stock_id)
);

CREATE TABLE watchlist (
    watchlist_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    stock_id INT NOT NULL,
    added_date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (stock_id) REFERENCES stocks(stock_id)
);


CREATE INDEX idx_transactions_portfolio ON transactions(portfolio_id);
CREATE INDEX idx_transactions_stock ON transactions(stock_id);
CREATE INDEX idx_prices_stock_date ON stock_prices(stock_id, price_date);


INSERT INTO users (name, email) VALUES
('Veera', 'veera@example.com');

INSERT INTO stocks (ticker_symbol, company_name, sector, exchange) VALUES
('TCS', 'Tata Consultancy Services', 'IT', 'NSE'),
('INFY', 'Infosys', 'IT', 'NSE'),
('RELIANCE', 'Reliance Industries', 'Energy', 'NSE'),
('HDFCBANK', 'HDFC Bank', 'Banking', 'NSE');

INSERT INTO portfolios (user_id, portfolio_name) VALUES
(1, 'My First Portfolio');

INSERT INTO transactions (portfolio_id, stock_id, transaction_type, quantity, price_per_share, transaction_date) VALUES
(1, 1, 'BUY', 10, 3500.00, '2024-01-15'),
(1, 2, 'BUY', 20, 1450.00, '2024-02-10'),
(1, 1, 'SELL', 4, 3700.00, '2024-06-01');

INSERT INTO stock_prices (stock_id, price_date, open_price, close_price, high_price, low_price, volume) VALUES
(1, '2024-01-10', 3480.00, 3500.00, 3510.00, 3470.00, 1200000),
(1, '2024-02-10', 3550.00, 3580.00, 3600.00, 3540.00, 1350000),
(1, '2024-03-10', 3600.00, 3650.00, 3670.00, 3590.00, 1420000),
(2, '2024-01-10', 1430.00, 1450.00, 1460.00, 1420.00, 980000),
(2, '2024-02-10', 1460.00, 1490.00, 1500.00, 1450.00, 1050000),
(2, '2024-03-10', 1500.00, 1530.00, 1545.00, 1495.00, 1100000),
(3, '2024-01-10', 2400.00, 2450.00, 2470.00, 2390.00, 2000000),
(3, '2024-02-10', 2460.00, 2500.00, 2520.00, 2440.00, 2100000),
(4, '2024-01-10', 1600.00, 1620.00, 1630.00, 1590.00, 1500000),
(4, '2024-02-10', 1625.00, 1650.00, 1665.00, 1610.00, 1600000),
(1, '2026-09-10', 2260.00, 2255.50, 2270.00, 2245.00, 1500000),
(2, '2026-09-10', 1055.00, 1046.80, 1060.00, 1035.00, 1800000),
(3, '2026-09-10', 1290.00, 1284.40, 1295.00, 1277.00, 2500000),
(4, '2026-09-10', 710.00, 703.00, 715.00, 698.00, 1600000);


SELECT * FROM stocks;
SELECT * FROM stock_prices ORDER BY stock_id, price_date;

CREATE VIEW holdings_view AS
SELECT
    t.portfolio_id,
    t.stock_id,
    s.ticker_symbol,
    SUM(CASE WHEN t.transaction_type = 'BUY' THEN t.quantity ELSE -t.quantity END) AS total_quantity,
    ROUND(SUM(CASE WHEN t.transaction_type = 'BUY' THEN t.quantity * t.price_per_share ELSE 0 END) /
          NULLIF(SUM(CASE WHEN t.transaction_type = 'BUY' THEN t.quantity ELSE 0 END), 0), 2) AS avg_buy_price
FROM transactions t
JOIN stocks s ON t.stock_id = s.stock_id
GROUP BY t.portfolio_id, t.stock_id, s.ticker_symbol
HAVING total_quantity > 0;


SELECT
    p.portfolio_name,
    s.ticker_symbol,
    h.total_quantity,
    h.avg_buy_price,
    latest.close_price AS current_price,
    ROUND(h.total_quantity * latest.close_price, 2) AS current_value
FROM holdings_view h
JOIN portfolios p ON h.portfolio_id = p.portfolio_id
JOIN stocks s ON h.stock_id = s.stock_id
JOIN (
    SELECT sp1.stock_id, sp1.close_price
    FROM stock_prices sp1
    INNER JOIN (
        SELECT stock_id, MAX(price_date) AS max_date
        FROM stock_prices
        GROUP BY stock_id
    ) sp2 ON sp1.stock_id = sp2.stock_id AND sp1.price_date = sp2.max_date
) latest ON h.stock_id = latest.stock_id;


SELECT
    s.ticker_symbol,
    h.total_quantity,
    h.avg_buy_price,
    latest.close_price AS current_price,
    ROUND((latest.close_price - h.avg_buy_price) * h.total_quantity, 2) AS unrealized_pl
FROM holdings_view h
JOIN stocks s ON h.stock_id = s.stock_id
JOIN (
    SELECT sp1.stock_id, sp1.close_price
    FROM stock_prices sp1
    INNER JOIN (SELECT stock_id, MAX(price_date) AS max_date FROM stock_prices GROUP BY stock_id) sp2
    ON sp1.stock_id = sp2.stock_id AND sp1.price_date = sp2.max_date
) latest ON h.stock_id = latest.stock_id;

SELECT
    ticker_symbol,
    unrealized_pl,
    RANK() OVER (ORDER BY unrealized_pl DESC) AS performance_rank
FROM (
    SELECT
        s.ticker_symbol,
        ROUND((latest.close_price - h.avg_buy_price) * h.total_quantity, 2) AS unrealized_pl
    FROM holdings_view h
    JOIN stocks s ON h.stock_id = s.stock_id
    JOIN (
        SELECT sp1.stock_id, sp1.close_price
        FROM stock_prices sp1
        INNER JOIN (SELECT stock_id, MAX(price_date) AS max_date FROM stock_prices GROUP BY stock_id) sp2
        ON sp1.stock_id = sp2.stock_id AND sp1.price_date = sp2.max_date
    ) latest ON h.stock_id = latest.stock_id
) ranked;


SELECT
    s.sector,
    ROUND(SUM(h.total_quantity * latest.close_price), 2) AS sector_value,
    ROUND(100.0 * SUM(h.total_quantity * latest.close_price) /
        (SELECT SUM(h2.total_quantity * lp.close_price)
         FROM holdings_view h2
         JOIN (SELECT sp1.stock_id, sp1.close_price FROM stock_prices sp1
               INNER JOIN (SELECT stock_id, MAX(price_date) md FROM stock_prices GROUP BY stock_id) sp2
               ON sp1.stock_id=sp2.stock_id AND sp1.price_date=sp2.md) lp ON h2.stock_id = lp.stock_id
        ), 2) AS allocation_pct
FROM holdings_view h
JOIN stocks s ON h.stock_id = s.stock_id
JOIN (
    SELECT sp1.stock_id, sp1.close_price FROM stock_prices sp1
    INNER JOIN (SELECT stock_id, MAX(price_date) md FROM stock_prices GROUP BY stock_id) sp2
    ON sp1.stock_id=sp2.stock_id AND sp1.price_date=sp2.md
) latest ON h.stock_id = latest.stock_id
GROUP BY s.sector;


SELECT
    stock_id,
    price_date,
    close_price,
    ROUND(((close_price - LAG(close_price) OVER (PARTITION BY stock_id ORDER BY price_date)) /
           LAG(close_price) OVER (PARTITION BY stock_id ORDER BY price_date)) * 100, 2) AS pct_return
FROM stock_prices
ORDER BY stock_id, price_date;


CREATE TABLE transaction_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id INT,
    action VARCHAR(10),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO transaction_audit (transaction_id, action)
    VALUES (NEW.transaction_id, 'INSERT');
END$$
DELIMITER ;