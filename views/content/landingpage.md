---

# Bitcoin purchasing power index
#### _Make the value of bitcoin digestible_ 🍔

The bitcoin purchasing power index (bitcoinppi) tells you **how many Big Mac hamburgers you can buy
with one bitcoin.** This is helpful when you want to know the everyday _value_ of bitcoin.

So far the value of bitcoin has only been quoted in fiat currencies like the US dollar, European euro or others.
This measure is strained by increases in the overall level of consumer prices (aka inflation).

It might happen for instance that the value of bitcoin in US dollars goes up from 300 USD to 305 USD but the products
that one bitcoin buys you ([purchasing power](https://en.wikipedia.org/wiki/Purchasing_power)) remains the same.
**Inflation is influenced by monetary policy** and should not get
in the way of measuring the value of a central bank independent currency.

The bitcoinppi measures the value of bitcoin by its purchasing power of a worldwide available and uniform
item - the Big Mac hamburger. This makes the bitcoin purchasing power index agnostic to monetary policy.
The bitcoinppi hence lets you **express bitcoin's value in a central bank independent way.**
Much similar to how bitcoin operates technologically as a currency and payment network.

### Local bitcoinppi 🚩
In order to buy a Big Mac with one bitcoin you will need to convert it to a local currency like the pound, peso etc.
The **local bitcoinppi** does exactly that. It tells you
**how many Big Macs you can buy with one bitcoin in a specific country**.

This is because bitcoin **exchange rates and Big Mac prices differ** from one country to another.
When you want to buy Big Macs with a bitcoin in the UK, a different exchange rate applies and the Big Mac price
is not the same as in Mexico for example.

The calculation of the local bitcoinppi only **uses real local Big Mac prices** as recorded by the Big Max index and **only local
exchange rates** as they were available if you wanted to buy or sell bitcoins in that specific country. The bitcoinppi does not use cross-rates
to derive exchange rates from cross-currency pairs because these rates are in most cases not accessible to consumers.

### Global bitcoinppi 🌏
The global bitcoinppi is a weighted average of local bitcoin purchasing power indices. It tells how many Big Mac burgers you can buy
with one bitcoin _**on average globally**_. Each available local bitcoinppi is considered in the global bitcoinppi.
The weights are calculated based on a country's population and the GDP per capita in purchasing power parity.

### Use cases of the bitcoinppi 🔩
Besides just expressing the value in a central bank independent way, there are multiple other use cases for the bitcoinppi.
Note that the [bitcoinppi API](http://bitcoinppi.com/pages/api) provides all the raw data you need to use this index in
every imaginable way. If you use it for something cool, we would love to hear about it in the comments! Here are a few use case ideas

* Measure bitcoin's actual purchasing power instead of its price
* Analyze bitcoin's purchasing power volatility instead of bitcoins price volatility
* Use the index as a fair value measure in [bitcoin lending](https://www.bitbond.com)
* Quote prices in your online shop in Big Macs instead of USD or other fiat currencies and accept bitcoins with ease

---

## Volatility of the global bitcoinppi 📈

[insert volatility chart here]

The bitcoinppi volatility measures the average return volatility of the last 30 days of daily index changes.
The volatility data is not provided by our API but you can easily calculate it yourself with daily index information.
This is the formula we use to calculate the bitcoinppi volatility

`STDEV(SUM(ln(bitcoinppi(d) / bitcoinppi(d-1)) / 30) * SQRT(365) with d = 1..30`

---

### How is the bitcoinppi calculated 💻
The bitcoinppi is updated every 15 minutes and is calculated as follows

`bitcoinppi_local(country_i) = (btc_price(currency_country_i) / big_mac_price(currency_country_i))`

`bitcoinppi_global = SUM(bitcoinppi_local(country_i) * weight(country_i)) with i = i..I`

where

`weight(country_i) = (population(country_i) / SUM(population(country_i..I))) * 1/3 + (GDPperCapPPP(country_i) / SUM(GDPperCapPPP(country_i..I))) * 2/3`

### bitcoinppi data sources 💽
To calculate the bitcoinppi we need Big Mac prices for local bitcoinppi calculations. To arrive at the global bitcoinppi
we additionally need the population of each country that goes in the index plus the GDP per capita expressed in purchasing power parity
for each index country.

#### The Big Mac index of The Economist 🍔
Big Mac prices are taken from the [Big Mac index](http://www.economist.com/content/big-mac-index) as published by The Economist.
The Big Mac index is updated every six months. Whenever there are new prices available they will be imported into the bitcoinppi.

#### Bitcoin price data sources ฿
Bitcoin price data is sourced from [BitcoinAverage](https://bitcoinaverage.com) and [bitcoincharts](http://www.bitcoincharts.com/).

#### Population and GDP per capita for weights 🏢
Data is sourced from [Trading Economics](http://www.tradingeconomics.com). Historical values for population and GDPper capita
are not yet pulled in. Will need to be done at a later point.

---

<div class="fb-comments" data-href="http://bitcoinppi.com" data-width="600" data-numposts="10"></div>
