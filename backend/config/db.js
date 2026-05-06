const { Pool } = require('pg');
require('dotenv').config();

// Create a new PostgreSQL connection pool
const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

// Test the database connection as soon as the file is loaded
const connectDB = async () => {
    try {
        const client = await pool.connect();
        console.log(`✅ PostgreSQL Connected successfully to database: ${process.env.DB_NAME}`);
        client.release();
    } catch (err) {
        console.error('❌ PostgreSQL Connection Error:', err.message);
        process.exit(1);
    }
};

connectDB();

module.exports = pool;
