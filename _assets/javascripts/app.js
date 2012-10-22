(function () {
  function getByTag(tag) {
    return document.getElementsByName(tag);
  }


  function injectScript(src) {
    var el = document.createElement('script');

    el.type   = 'text/javascript';
    el.async  = true;
    el.src    = src;

    (getByTag('head')[0] || getByTag('body')[0]).appendChild(el);
  }


  setTimeout(function initGoogleAnalytics() {
    var prefix  = 'https:' == document.location.protocol ?
                  'https://ssl' : 'http://www';

    window._gaq = [ ['_setAccount', 'UA-35573678-1'], ['_trackPageview'] ];
    injectScript(prefix + '.google-analytics.com/ga.js');
  }, 0);


  setTimeout(function initDisqus() {
    if (!document.getElementById('disqus_thread')) {
      // do nothing if page has no disqus container
      return;
    }

    window.disqus_shortname = 'ixti';
    injectScript('http://' + disqus_shortname + '.disqus.com/embed.js');
  }, 0);
}());
