## API

There are multiple public endpoints that return JSON data from this site.
In general the data is updated every 15 minutes. Caching rules are set to store responses up to 15 minutes.

#### Versions

* `/v1.0` The initial release.

#### GET parameters

All endpoints except for `spot` accept these parameters that let you define the timeframe and resolution.

All times are expected in UTC, and `to` is expected to be later than `from`. For calculting the resolution, the given times will be truncated to their unit of resolution (e.g. '2015-10-14 12:47' will become '2015-10-14 12:00' when using '1 hour').

* `from`  
    default: 1 year ago  
    format: YYYY-mm-dd or YYYY-mm-dd HH:00
* `to`  
    default: now  
    format: YYYY-mm-dd or YYYY-mm-dd HH:00
* `tick`  
    default: 1 day  
    allowed: 7 days, 1 day, 12 hours, 6 hours, 1 hour, 30 minutes, 15 minutes

### `GET /v1.0/spot`

This endpoint returns data within the last 24 hours. **GET parameters** are ignored.

**Response:**


    HTTP/1.1 200 OK
    Content-Type: application/json
    Cache-Control: public, max-age=900
    Content-Length: 7292
    
    
    {
      "spot": {
        "tick": "2015-10-06T15:42:09.140+02:00",
        "avg_global_ppi": "68.7226854718793516",
        "global_ppi": "25.5837868120114838"
      },
      "countries" {
        "Australia": {
            "bigmac_price_close": "5.3",
            "bitcoin_price_close": "348.95",
            "country": "Australia",
            "currency": "AUD",
            "tick": "2015-10-06T15:27:09.172+02:00",
            "weight": "1.0",
            "avg_country_ppi": "65.8591194968553459",
            "country_ppi": "65.839622641509434"
        },
        ...
        "United States": {
            "bigmac_price_close": "10.0",
            "bitcoin_price_close": "245.22",
            "country": "United States",
            "currency": "USD",
            "tick": "2015-10-06T15:27:09.172+02:00",
            "weight": "1.0",
            "avg_country_ppi": "24.4983333333333333",
            "country_ppi": "24.522"
        }
      }
    }

### `GET /v1.0/global_ppi`

This endpoint returns all global_ppi values over a defined time series. The timeframe can be adjusted using the **GET parameters** declared above.

### `GET /v1.0/countries`

This endpoint returns all ppi values over all countries, over a defined time series. The timeframe can be adjusted using the **GET parameters** declared above.

### `GET /v1.0/countries/:country`

This endpoint returns all ppi values by country, over a defined time series. The timeframe can be adjusted using the **GET parameters** declared above.

