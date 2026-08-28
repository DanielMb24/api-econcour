const cors = require('cors');

const corsOptions = {
    origin: [
        'https://gabonconcours.vercel.app',
        'http://localhost:5173',
        'http://localhost:3002',
        'http://localhost:8001',
        'http://127.0.0.1:8001',
         'http://localhost:8080',
        'http://127.0.0.1:8080',
         'http://localhost:3000',
        'http://127.0.0.1:3000',
        'http://localhost:8080',
        'http://127.0.0.1:8080',
        'http://localhost:8082',
        'http://127.0.0.1:8082',
        'http://econcour.vercel.app', 'http://localhost:8081',
        
        'http://localhost:8084',
        'http://127.0.0.1:8084',
        'http://localhost:8083',
        'http://127.0.0.1:8083',
        'http://localhost:8085',
        'http://127.0.0.1:8085', 'http://localhost:8088',
        'http://localhost:8086', 'http://127.0.0.1:8089',
        'http://127.0.0.1:8086', 'http://localhost:8089',
        'http://localhost:8087', 'http://127.0.0.1:8090',
        'http://127.0.0.1:8087', 'http://localhost:8090','http://localhost:8097',
        'http://127.0.0.1:8088','http://127.0.0.1:8097',
    ],
    credentials: true,
    optionsSuccessStatus: 200,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
};

module.exports = cors(corsOptions);
