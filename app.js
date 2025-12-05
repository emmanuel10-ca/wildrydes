const express = require('express');
const app = express();
const port = process.env.APP_PORT || 8080;

// Middleware
app.use(express.static('public'));
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API endpoint
app.get('/api/rides', (req, res) => {
  res.json({
    rides: [
      {
        id: 1,
        unicorn: 'Rocinante',
        distance: 25.5,
        price: '$42.50',
        status: 'Available'
      },
      {
        id: 2,
        unicorn: 'Bucephalus',
        distance: 18.3,
        price: '$28.75',
        status: 'Available'
      },
      {
        id: 3,
        unicorn: 'Shadowfax',
        distance: 32.1,
        price: '$51.20',
        status: 'In Transit'
      }
    ]
  });
});

// Home page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Wild Rydes - Unicorn Rides</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          min-height: 100vh;
          display: flex;
          justify-content: center;
          align-items: center;
        }
        
        .container {
          text-align: center;
          background: white;
          padding: 60px 40px;
          border-radius: 10px;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
          max-width: 600px;
          width: 90%;
        }
        
        h1 {
          color: #667eea;
          margin-bottom: 20px;
          font-size: 3em;
          text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .tagline {
          color: #666;
          margin-bottom: 40px;
          font-size: 1.2em;
        }
        
        .info-section {
          background: #f8f9fa;
          padding: 30px;
          border-radius: 8px;
          margin-bottom: 30px;
          border-left: 4px solid #667eea;
        }
        
        .info-section h2 {
          color: #667eea;
          margin-bottom: 15px;
          font-size: 1.5em;
        }
        
        .info-section p {
          color: #666;
          line-height: 1.6;
          margin-bottom: 10px;
        }
        
        .button-group {
          display: flex;
          gap: 15px;
          justify-content: center;
          flex-wrap: wrap;
          margin-top: 30px;
        }
        
        .btn {
          padding: 12px 30px;
          font-size: 1em;
          border: none;
          border-radius: 5px;
          cursor: pointer;
          transition: all 0.3s ease;
          text-decoration: none;
          display: inline-block;
        }
        
        .btn-primary {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
        }
        
        .btn-primary:hover {
          transform: translateY(-2px);
          box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }
        
        .btn-secondary {
          background: #f0f0f0;
          color: #667eea;
          border: 2px solid #667eea;
        }
        
        .btn-secondary:hover {
          background: #667eea;
          color: white;
          transform: translateY(-2px);
        }
        
        .status {
          background: #e8f5e9;
          border: 2px solid #4caf50;
          color: #2e7d32;
          padding: 15px;
          border-radius: 5px;
          margin-top: 20px;
          font-weight: bold;
        }
        
        .emoji {
          font-size: 4em;
          margin-bottom: 20px;
        }
        
        .features {
          text-align: left;
          display: inline-block;
          margin-top: 30px;
        }
        
        .features li {
          list-style: none;
          padding: 10px 0;
          color: #666;
          font-size: 1.1em;
        }
        
        .features li:before {
          content: "✓ ";
          color: #4caf50;
          font-weight: bold;
          margin-right: 10px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="emoji">🦄</div>
        <h1>Wild Rydes</h1>
        <p class="tagline">Your Magical Unicorn Ride Awaits</p>
        
        <div class="info-section">
          <h2>Infrastructure Status</h2>
          <p><strong>✓ Application deployed successfully!</strong></p>
          <p>This application is running on AWS ECS Fargate with:</p>
          <ul class="features">
            <li>Load Balanced across multiple subnets</li>
            <li>Auto-scaling based on CPU utilization</li>
            <li>CI/CD Pipeline Integration</li>
            <li>CloudWatch Monitoring & Alarms</li>
          </ul>
        </div>
        
        <div class="info-section">
          <h2>Available APIs</h2>
          <p><code>/health</code> - Service health check</p>
          <p><code>/api/rides</code> - Available unicorn rides</p>
        </div>
        
        <div class="button-group">
          <a href="/api/rides" class="btn btn-primary">View Available Rides</a>
          <a href="/health" class="btn btn-secondary">Check Health</a>
        </div>
        
        <div class="status">
          🟢 All systems operational
        </div>
      </div>
    </body>
    </html>
  `);
});

// Catch-all for 404
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource does not exist',
    path: req.path
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: 'An unexpected error occurred'
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Wild Rydes application listening on port ${port}`);
  console.log(`Health check available at http://0.0.0.0:${port}/health`);
  console.log(`Rides API available at http://0.0.0.0:${port}/api/rides`);
});
