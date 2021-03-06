$(function(){
  var form = $("#timeframe-form");

  function updateDateRange(from, to) {
    from = from.format("YYYY-MM-DD HH:00");
    to = to.format("YYYY-MM-DD HH:00")
    form.find("input[name=from]").val(from);
    form.find("input[name=to]").val(to);
    $("#daterangepicker .display").text(from + " - " + to);
  };

  $("#daterangepicker").daterangepicker({
    timePicker: true,
    timePicker24Hour: true,
    minDate: "2011-07-01",
    opens: "center",
    locale: {
      format: "YYYY-MM-DD HH:00"
    },
    startDate: form.find("input[name=from]").val(),
    endDate: form.find("input[name=to]").val(),
    ranges: {
      "24 hours": [moment().subtract(1, "day").minutes(0), moment().minutes(0)],
      "1 week": [moment().subtract(1, "week").minutes(0), moment().minutes(0)],
      "1 month": [moment().subtract(1, "month").minutes(0), moment().minutes(0)],
      "year to date": [moment().startOf("year").minutes(0).hour(0), moment().minutes(0).hour(0)],
      "max range": ["2011-07-01 00:00", moment().minutes(0).hour(0)]
    }
  }, function(from, to) {
    updateDateRange(from, to);
    from = form.find("input[name=from]").val();
    to = form.find("input[name=to]").val();
    var queryString = "?from=" + encodeURIComponent(from) + "&to=" + encodeURIComponent(to);
    if (history.pushState) {
      var newurl = window.location.protocol + "//" + window.location.host + window.location.pathname + queryString;
      window.history.pushState({path: newurl}, "", newurl);
    }
    ppiChart.refetchData(queryString).done(function() { ppiChart.render(); });
    volatilityChart.refetchData(queryString).done(function() { volatilityChart.render(); });
  });

  $(window).resize(function() {
    if (this.timer) clearTimeout(this.timer);
    this.timer = setTimeout(function() {
      $(window).trigger("resize-end");
    }, 100);
  });

  $(window).on("resize-end", function() {
    ppiChart.resizeChart();
    volatilityChart.resizeChart();
  });

  form.on("click", "#download-csv", function(event) {
    event.preventDefault();
    from = form.find("input[name=from]").val();
    to = form.find("input[name=to]").val();
    var queryString = "?from=" + encodeURIComponent(from) + "&to=" + encodeURIComponent(to);
    var url = "/v1.1/global_ppi.csv" + queryString;
    window.location.href = url;
  });
});
