/*!
  Headstar Javascripts | © 2015-2017 Nick Freear.
*/

var _gaq = window._gaq || [];
_gaq.push(['_setAccount', 'UA-7941798-1']);
_gaq.push(['_trackPageview']);

(function (document) {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = 'https://www.google-analytics.com/ga.js'; // ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})(window.document);

(function (W, D) {
  var page = W.location.pathname.replace(/.+\//, '').replace(/\..+/, '');
  var el = D.querySelector('#foot .y');
  var year = 1900 + (new Date()).getYear();

  el.innerHTML = year;
  D.body.className += ' pg-' + page;

  if (W.location.href.match(/[&?]embed=(1|true)/)) {
    D.body.className += ' pg-embed';
  }
})(window, window.document);
