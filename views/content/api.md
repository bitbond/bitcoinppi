<div class="page-header">
  <h1>API Documentation</h1>
</div>

There are multiple public endpoints that return JSON data from this site.
In general the data is updated every 15 minutes. Caching rules are set to store responses up to 15 minutes.

### Versions

The current version must be prepended to all API requests.
A request `/spot` should be made as `/v1.1/spot`.

Additional features will be added to the current version. But breaking features or bugfixes will increment the version.
This ensures (for a certain grace period) that older clients can continue to work with the API as expected.

* `/v1.1` Current release.
* `/v1.0` The initial release. **no longer accessible**

### JSON

The API defaults to JSON responses.

### CSV

All endpoints except for `/spot` allow for csv responses. A csv response can be initiated by appending `.csv` to the request path.
The csv is **utf-8** encoded and has a `,` **comma as field separator**. Each line is separated with a **unix newline character** `\n`.

### GET parameters

All endpoints except for `/spot` accept these optional parameters that let you define the timeframe and resolution.

All times are expected in UTC, and **to** is expected to be later than **from**.
For calculting the resolution, the given times will be truncated to their unit of resolution (e.g. '2015-10-14 12:47' will become '2015-10-14 12:00' when using '1 hour').
The param **tick** must not be given, and by default the lowest resolution available will be chosen.

<dl class="dl-horizontal">
  <dt>from</dt>
  <dd>
    default: 1 year ago<br>
    format: YYYY-mm-dd or YYYY-mm-dd HH:00
  </dd>
  <dt>to</dt>
  <dd>
    default: now<br>
    format: YYYY-mm-dd or YYYY-mm-dd HH:00
  </dd>
  <dt>tick</dt>
  <dd>
    default: lowest available for given timeframe<br>
    allowed: 7 days, 1 day, 12 hours, 1 hour, 15 minutes
  </dd>
</dl>

### GET /spot

This endpoint returns data within the last 24 hours. **GET parameters** are ignored.

**Example:**

    curl http://bitcoinppi.com/v1.1/spot

**Response:**

    HTTP/1.1 200 OK
    Content-Type: application/json
    Cache-Control: public, max-age=900
    Content-Length: 9572
    
    
    {
      "spot": {
        "tick": "2015-10-15T10:30:00.000+02:00",
        "global_ppi": "51.110243502525189243",
        "avg_24h_global_ppi": "50.9007122538474498736044"
      },
      "countries": {
        "CN": {
          "time": "2015-10-15T10:44:12.000+02:00",
          "tick": "2015-10-15T10:30:00.000+02:00",
          "country": "CN",
          "currency": "CNY",
          "bitcoin_price": "1652.15",
          "bigmac_price": "17.0",
          "weight": "0.1",
          "local_ppi": "97.1852941176470588",
          "avg_24h_local_ppi": "96.2611118293471235"
        },
        ...
        "US": {
          "time": "2015-10-15T10:44:12.000+02:00",
          "tick": "2015-10-15T10:30:00.000+02:00",
          "country": "US",
          "currency": "USD",
          "bitcoin_price": "255.06",
          "bigmac_price": "4.79",
          "weight": "0.05",
          "local_ppi": "53.2484342379958246",
          "avg_24h_local_ppi": "53.2046387850145679"
        }
      }   
    }

### GET /global_ppi

This endpoint returns all global_ppi values over a defined time series.
The timeframe can be adjusted using the **GET parameters** declared above.
By default it returns data from the last year at a resolution of 1 day.

The default response type is **JSON**. To receive a **CSV** response, append `.csv` to the request path.

**Examples:**

    curl http://bitcoinppi.com/v1.1/global_ppi

    curl 'http://bitcoinppi.com/v1.1/global_ppi?from=2011-07-01&to=2013-04-30'

    curl 'http://bitcoinppi.com/v1.1/global_ppi?from=2011-07-01&to=2013-04-30&tick=7+days'

**Response:**

    HTTP/1.1 200 OK
    Content-Type: application/json
    Cache-Control: public, max-age=900
    Content-Length: 28515

    
    {
      "global_ppi": [
        {
          "tick": "2014-10-15T00:00:00.000+02:00",
          "global_ppi": "71.724394968569117126"
        },
        ...
        {
          "tick": "2015-10-15T00:00:00.000+02:00",
          "global_ppi": "51.110243502525189243"
        }
      ]
    }

### GET /countries

This endpoint returns all ppi values of all countries, over a defined time series.
The timeframe can be adjusted using the **GET parameters** declared above.
By default it returns data from the last year at a resolution of 1 day.

The default response type is **JSON**. To receive a **CSV** response, append `.csv` to the request path.

**Examples:**

    curl http://bitcoinppi.com/v1.1/countries

    curl 'http://bitcoinppi.com/v1.1/countries?from=2014-07-01&to=2015-04-30'

    curl 'http://bitcoinppi.com/v1.1/countries?from=2014-07-01&to=2015-04-30&tick=7+days'

**Response:**

    HTTP/1.1 200 OK
    Content-Type: application/json
    Cache-Control: public, max-age=900
    Content-Length: 3402397

    
    {
      "countries": [
        {
          "time": "2015-10-15T10:44:12.000+02:00",
          "tick": "2015-10-15T00:00:00.000+02:00",
          "country": "DE",
          "currency": "EUR",
          "bitcoin_price": "221.75",
          "bigmac_price": "3.59",
          "weight": "0.03",
          "local_ppi": "61.7688022284122563",
          "avg_24h_local_ppi": "65.0716961723251063"
        },
        ...
        {
          "time": "2014-10-15T02:00:00.000+02:00",
          "tick": "2014-10-15T00:00:00.000+02:00",
          "country": "US",
          "currency": "USD",
          "bitcoin_price": "394.45",
          "bigmac_price": "4.8",
          "weight": "0.05",
          "local_ppi": "82.1770833333333333",
          "avg_24h_local_ppi": "56.7332445521559411"
        }
      ]
    }

### GET /countries/:country

This endpoint returns all ppi values by country, over a defined time series. The part **:country** should be set as an **uppercase ISO3166 alpha2** country code.
The timeframe can be adjusted using the **GET parameters** declared above.
By default it returns data from the last year at a resolution of 1 day.

The default response type is **JSON**. To receive a **CSV** response, append `.csv` to the request path.

**Examples:**

    curl http://bitcoinppi.com/v1.1/countries/DE

    curl 'http://bitcoinppi.com/v1.1/countries/DE?from=2014-07-01&to=2015-04-30'

    curl 'http://bitcoinppi.com/v1.1/countries/DE?from=2014-07-01&to=2015-04-30&tick=7+days'

**Response:**

    HTTP/1.1 200 OK
    Content-Type: application/json
    Cache-Control: public, max-age=900
    Content-Length: 121359

    
    {
      "DE": [
        {
          "time": "2015-10-15T10:44:12.000+02:00",
          "country": "DE",
          "currency": "EUR",
          "bitcoin_price": "221.75",
          "bigmac_price": "3.59",
          "weight": "0.03",
          "local_ppi": "61.7688022284122563",
          "tick": "2015-10-15T00:00:00.000+02:00",
          "avg_24h_local_ppi": "65.0716961723251063"
        },
        ...
        {
          "time": "2014-10-15T02:00:00.000+02:00",
          "country": "DE",
          "currency": "EUR",
          "bitcoin_price": "312.1",
          "bigmac_price": "3.67",
          "weight": "0.03",
          "local_ppi": "85.0408719346049046",
          "tick": "2014-10-15T00:00:00.000+02:00",
          "avg_24h_local_ppi": "65.0716961723251063"
        }
      ]
    }

