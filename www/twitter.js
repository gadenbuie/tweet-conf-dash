window.twttr = (function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0],
    t = window.twttr || {};
  if (d.getElementById(id)) return t;
  js = d.createElement(s);
  js.id = id;
  js.src = "https://platform.twitter.com/widgets.js";
  fjs.parentNode.insertBefore(js, fjs);

  t._e = [];
  t.ready = function(f) {
    t._e.push(f);
  };

  return t;
}(document, "script", "twitter-wjs"));

// Add event listeners to load tweets when UI is updated
// https://shiny.rstudio.com/articles/js-events.html#output-events
$('#tweet_wall_tweets').on('shiny:value', function(event) {
  setTimeout(function() {
    twttr.widgets.load(document.getElementById("tweet_wall_tweets"));
  }, 1000);
});

$('#pic_tweets_wall').on('shiny:value', function(event) {
  setTimeout(function() {
    twttr.widgets.load(document.getElementById("pic_tweets_wall"));
  }, 1000);
});

$('#dash_most_recent').on('shiny:value', function(event) {
  setTimeout(function() {
    twttr.widgets.load(document.getElementById("dash_most_recent"));
  }, 1000);
});

$('#dash_most_rt').on('shiny:value', function(event) {
  setTimeout(function() {
    twttr.widgets.load(document.getElementById("dash_most_rt"));
  }, 1000);
});

$('#dash_most_liked').on('shiny:value', function(event) {
  setTimeout(function() {
    twttr.widgets.load(document.getElementById("dash_most_liked"));
  }, 1000);
});

$('#tweetExplorer-tweet').on('shiny:value', function(event) {
  setTimeout(function() {
    twttr.widgets.load(document.getElementById("tweetExplorer-tweet"));
  }, 1000);
});
