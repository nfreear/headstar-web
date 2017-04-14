/**
 * Title: Javascript Style-sheet switcher using the DOM.
 * URL:   http://www.headstar.com/eab/includes/styleswitcher.js
 * Refer: Nick 2004-07-01, http://www.bunburyIS.com .
 * Copyright © 2004-2016 Nick Freear.
 *
 * Src: http://alistapart.com/stories/alternate, Sowden & Koch, 126/2001-11 (2003-07-21).
 */

(function (window) {

  'use strict';

  var EAB = window.EAB = {}
    , document = window.document
    , console = window.console;

window.setActiveStyleSheet =
EAB.setActiveStyleSheet = function (title, ev) {
  var i, a, main;
  for(i = 0; (a = document.getElementsByTagName("link")[ i ]); i++) {
    if(a.getAttribute("rel").indexOf("style") !== -1 && a.getAttribute("title")) {
      a.disabled = true;
      if(a.getAttribute("title") === title) { a.disabled = false; }
    }
  }

  if (ev && ev.preventDefault) {
    ev.preventDefault();
  }
  if (console) {
    console.info('Switch sheet:', title, ev);
  }
}

EAB.getActiveStyleSheet = function () {
  var i, a;
  for(i = 0; (a = document.getElementsByTagName("link")[ i ]); i++) {
    if(a.getAttribute("rel").indexOf("style") !== -1 && a.getAttribute("title") && ! a.disabled)
      { return a.getAttribute("title"); }
  }
  return null;
}

EAB.getPreferredStyleSheet = function () {
  // Return a constant - style sheet 'title'
  return "Graphic";

  /*var i, a;
  for(i = 0; (a = document.getElementsByTagName("link")[ i ]); i++) {
    if(a.getAttribute("rel").indexOf("style") !== -1
       && a.getAttribute("rel").indexOf("alt") === -1
       && a.getAttribute("title")
       ) return a.getAttribute("title");
  }
  return null;*/
}

EAB.createCookie = function (name, value, days) {
  var expires;
  if (days) {
    var date = new Date();
    date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
    expires = "; expires=" + date.toGMTString();
  }
  else { expires = ""; }
  document.cookie = name + "=" + value + expires + "; path=/";
}

EAB.readCookie = function (name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i = 0; i < ca.length; i++) {
    var c = ca[ i ];
    while (c.charAt(0) === ' ') { c = c.substring(1, c.length); }
    if (c.indexOf(nameEQ) === 0) { return c.substring(nameEQ.length, c.length); }
  }
  return null;
}

window.onload = function (ev) {
  var cookie = EAB.readCookie("style");
  var title = cookie ? cookie : EAB.getPreferredStyleSheet();
  EAB.setActiveStyleSheet(title);
}

window.onunload = function (ev) {
  var title = EAB.getActiveStyleSheet();
  EAB.createCookie("style", title, 365);
}

var cookie = EAB.readCookie("style");
var title = cookie ? cookie : EAB.getPreferredStyleSheet();
EAB.setActiveStyleSheet(title);

}(window));
