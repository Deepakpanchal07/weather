require('dotenv').config();

const express = require('express');
const cors = require('cors');
const app  = express();

const PORT = process.env.PORT || 3000;
const API_KEY = process.env.WEATHER_API_KEY;

app.use(cors());
app.use(express.json());

app.get('/',(req,res) =>{
    res.json({
        message: 'wheather backend is running'
    });

});
app.get('/api/weather',async (req,res) => {
    const city = String(req.query.city || '').trim();
    
    if(!API_KEY) {
        return res.status(500).json({
            error: 'weather API KEY is missing in .env',
        });
    }
    try{
        const url = new URL(
            'https://api.weatherapi.com/v1/forecast.json'
        );
        url.searchParams.set('key',API_KEY);
        url.searchParams.set('q',city);
        url.searchParams.set('days',3);

        const response = await fetch(url);
        const data = await response.json();

        if(!response.ok){
            return res.status(502).json({
        error: data.error?.message || 'weather API request failed'});
    }
    res.json({
        location: data.location,
        current: data.current,
        forecast: data.forecast.forecastday,
    });
} catch (error) {
  console.error('Weather API error:', error);

  res.status(500).json({
    error: 'Unable to retrieve weather data.',
    details: error.message,
  });
}

    });
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Weather backend running on port ${PORT}`);
}); 
    