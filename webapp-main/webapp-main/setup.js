const { Client } = require('pg');
const dbConfig = require("./config/config");

const DATABASE_NAME = dbConfig.DB;

async function createDatabaseIfNotExists() {
 
    const client = new Client({
        user: dbConfig.USER,
        password: dbConfig.PASSWORD,
        host: dbConfig.HOST,
        port: 5432,
        database: 'postgres', // Default database for PostgreSQL
    });

    try {
        await client.connect();
        const res = await client.query(`SELECT 1 FROM pg_database WHERE datname = $1`, [DATABASE_NAME]);

        if (res.rows.length === 0) {
            // The database does not exist, create it
            await client.query(`CREATE DATABASE "${DATABASE_NAME}"`);
            console.log(`Database ${DATABASE_NAME} created.`);
        } else {
            // The database already exists
            console.log(`Database ${DATABASE_NAME} already exists.`);
        }
    } catch (error) {
        console.error('Error creating database:', error);
    } finally {
        console.error('Before executing finally:');
        await client.end();
        console.error('After executing finally');
    }

}

createDatabaseIfNotExists();