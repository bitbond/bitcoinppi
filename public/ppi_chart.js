var ppiChart = (function() {
  var margin = {top: 10, right: 15, bottom: 20, left: 30},
      width = $("#chart").width() - margin.left - margin.right,
      height = $("#chart").height() - margin.top - margin.bottom;

  var x = d3.time.scale().range([0, width]);
  var y = d3.scale.linear().range([height, 0]);

  var xAxis = d3.svg.axis()
      .scale(x)
      .orient("bottom")
      .innerTickSize(-height)
      .outerTickSize(0)
      .ticks(d3.time.month, 3)
      .tickFormat(d3.time.format("%b %Y"));

  var yAxis = d3.svg.axis()
      .scale(y)
      .orient("left")
      .innerTickSize(-width)
      .ticks(5)
      .outerTickSize(0);

  var svg = d3.select("#chart").append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var line = d3.svg.line()
    .x(function(d) { return x(d.tick); })
    .y(function(d) { return y(d.value); });
  var color = d3.scale.category20();
  var data = [];
  var xDomain;
  var currentQueryString = window.location.search;

  function maintainXDomain() {
    xDomain = [];
    data.forEach(function(d) {
      if (d.values.length > xDomain.length) {
        xDomain = d.values
          .map(function(d) { return {tick: d.tick}; })
          .sort(function(a, b) { return a.tick - b.tick; });
      }
    });
  };

  function setData(key, label, values) {
    var datum = data.find(function(d) { return d.key == key; });
    var index = data.indexOf(datum);
    if (index != -1) {
      data.splice(index, 1);
    }
    values.forEach(function(d) {
      d.tick = new Date(d.tick);
      d.value = parseFloat(key == "global_ppi" ? d.global_ppi : d.local_ppi);
    });
    values.sort(function(a, b) { return a.tick - b.tick; });
    var d = {key: key, label: label, values: values};
    d.min = d3.min(values, function(d) { return d.value; });
    d.max = d3.max(values, function(d) { return d.value; });
    data = data.concat(d);
    maintainXDomain();
  };

  function removeData(key) {
    var datum = data.find(function(d) { return d.key == key; });
    data.splice(data.indexOf(datum), 1);
    selectionList.push({key: key, label: datum.label});
  };

  function fetchData(key, queryString) {
    queryString = queryString || currentQueryString;
    var deferred = $.Deferred();
    var path = key == "global_ppi" ? "/global_ppi" : "/countries/" + key;
    $.getJSON("/v1.1" + path + queryString, function(response) {
      var label = labels.find(function(d) { return d.key == key; });
      setData(key, label.label, response[key]);
      deferred.resolve();
    });
    return deferred;
  };

  function refetchData(queryString) {
    currentQueryString = queryString;
    var deferreds = data.map(function(d) {
      return fetchData(d.key, queryString);
    });
    return $.when.apply($, deferreds);
  };

  var globalPPI = JSON.parse(document.getElementById("data").innerHTML);
  setData("global_ppi", "Global bitcoinppi", globalPPI);

  var selectionList = JSON.parse(document.getElementById("countryNames").innerHTML);
  var labels = [{key: "global_ppi", label: "Global bitcoinppi"}].concat(selectionList);

  // Other elements
  var xAxisGroup = svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")");

  var yAxisGroup = svg.append("g")
      .attr("class", "y axis");
  yAxisGroup
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("");

  var legendDate = d3.select("#legend").append("p")
    .attr("class", "highlight")
    .html("&nbsp;");
  var legend = d3.select("#legend").append("ul");
  var countrySelect = d3.select("#legend").append("select");
  countrySelect.on("change", function() {
    var select = this;
    select.disabled = "disabled";
    var deferred = fetchData(select.value);
    deferred.done(function() {
      selection = selectionList.find(function(d) { return d.key == select.value });
      selectionList.splice(selectionList.indexOf(selection), 1);
      select.disabled = null;
      render();
    });
  });
  var tickBisector = d3.bisector(function(d) {
    return d.tick;
  });
  var highlight = svg.append("g")
    .attr("class", "highlight");
  highlight.append("line");

  function render() {
    // Setup domains
    x.domain(d3.extent(xDomain, function(d) { return d.tick; }));
    var min = d3.min(data, function(d) { return d.min; });
    var max = d3.max(data, function(d) { return d.max; });
    y.domain([min - min * 0.15, max + max * 0.05]);

    var lineNames = data.map(function(d) { return d.key; });
    color.domain(labels.map(function(d) { return d.key; }));

    // Update Axes
    xAxis.ticks(5);
    xAxisGroup.call(xAxis);
    yAxisGroup.call(yAxis);

    // Lines
    var path = svg.selectAll("path.line").data(data, function(d) { return d.key; });

    path.enter()
      .append("path")
      .attr("class", "line");

    path
      .style("stroke", function(d) { return color(d.key) })
      .attr("d", function(d) { return line(d.values); });

    path.exit()
      .remove();

    // Labels
    var legendLabel = legend.selectAll("li").data(data, function(d) { return d.key; });

    var legendListElement = legendLabel.enter().append("li")
      .text(function(d) { return d.label; });
    legendListElement
      .append("span")
        .attr("class", "current-value highlight");
    legendListElement
      .insert("a")
        .on("click", function() {
          removeData(this.__data__.key);
          render();
        })
        .attr("class", "remove")
        .append("i")
          .attr("class", "glyphicon glyphicon-remove");

    legendLabel
      .style("color", function(d) { return color(d.key); });

    legendLabel.exit()
      .remove();

    // Country select
    var countriesForSelect = [{key: "none", label: "Add local bitcoinppi"}].concat(selectionList);
    var countryOption = countrySelect.selectAll("option").data(countriesForSelect, function(d) { return d.key; });

    countryOption.enter()
      .append("option")
      .attr("value", function(d) { return d.key; })
      .text(function(d) { return d.label; });

    countryOption.sort(function(a, b) {
      if (a.key == "none") { return -1; }
      return a.label.localeCompare(b.label);
    });

    countryOption.exit()
      .remove();

    // Highlight
    var circle = highlight.selectAll("circle").data(data, function(d) { return d.key; });
    circle.enter()
      .append("circle")
      .attr("class", "highlight")
      .attr("r", 3);

    circle.exit()
      .remove();

  }; // function render()

  function updateHighlight() {
    var mouseX = d3.mouse(this)[0];
    var time = x.invert(mouseX);
    var index = tickBisector.left(xDomain, time, 1);
    var d = xDomain[index];
    if (!d) { return; }
    highlight.select("line")
      .attr("x1", x(d.tick))
      .attr("x2", x(d.tick))
      .attr("y1", 0)
      .attr("y2", height)
      .attr("stroke", "black");

    highlight.selectAll("circle")
      .style("fill", function(d) { return color(d.key); })
      .attr("transform", function(d) {
        var index = tickBisector.left(d.values, time, 1);
        var v = d.values[index];
        return "translate(" + (v ? x(v.tick) : 0) + "," + (v ? y(v.value) : 0) + ")";
      })
      .style("display", function(d) {
        var index = tickBisector.left(d.values, time, 1);
        var v = d.values[index];
        return v ? null : "none";
      });

    legendDate.text(moment(d.tick).format("MMM D, YYYY HH:mm UTC"));
    legend.selectAll("li").select("span.current-value")
      .text(function(d) {
        var index = tickBisector.left(d.values, time, 1);
        var v = d.values[index];
        return v ? " " + v.value.toFixed(2) : "";
      });
  };

  svg.append("rect")
    .attr("class", "overlay")
    .attr("width", width)
    .attr("height", height)
    .on("mouseover", function() { d3.selectAll(".highlight").style("visibility", "visible"); })
    .on("mouseout", function() { d3.selectAll(".highlight").style("visibility", "hidden"); })
    .on("mousemove", updateHighlight);

  // initial render
  render();

  // resize
  function resizeChart() {
    width = $("#chart").width() - margin.left - margin.right;

    x.range([0, width]);

    yAxis.innerTickSize(-width);

    d3.select("#chart").select("svg").attr("width", width + margin.left + margin.right);
    svg.select(".overlay").attr("width", width);

    render();
  };

  return {
    refetchData: refetchData,
    render: render,
    resizeChart: resizeChart
  };

})();

