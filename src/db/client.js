const { Client } = require('pg'); // Import the PostgreSQL client

const client = new Client({
    user: 'your_username', // Replace with your database username
    host: 'your_database_host', // Replace with your database host
    database: 'your_database_name', // Replace with your database name
    password: 'your_password', // Replace with your database password
    port: 5432, // Default PostgreSQL port
});

client.connect() // Connect to the database
    .then(() => console.log('Connected to the database'))
    .catch(err => console.error('Connection error', err.stack));

module.exports = client; // Export the database client for use in other modules