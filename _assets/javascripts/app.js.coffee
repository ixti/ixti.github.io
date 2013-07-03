#= require vendor/json2
#= require vendor/store
#= require vendor/jquery

do ($ = jQuery, window) ->
  injectScript = (src) ->
    $("<script>").attr({
      type:   "text/javascript"
      async:  true
      src:    src
    }).appendTo("head")


  class ThemeSwitch
    constructor: (@themes) ->
      @overlay  = $("<div>").appendTo("body").hide().css
        position:         "absolute"
        width:            "100%"
        height:           "100%"
        top:              "0px"
        bottom:           "0px"
        left:             "0px"
        right:            "0px"
        backgroundColor:  "white"

      @active = do (id = store.get "theme") =>
        if 0 <= $.inArray(id, @themes) then id else @themes[0]

      @reset()

    inactive: () ->
      $.grep @themes, (id) => id != @active

    nextTheme: () ->
      @inactive()[0]

    toggle: () ->
      @themes = @inactive().concat [@active]
      @activate @themes[0]

    reset: () ->
      $("body").removeClass(@themes.join " ").addClass @active

    activate: (@active) ->
      @overlay.fadeIn "normal", () =>
        @reset()
        store.set "theme", @active
        @onActivate() if @onActivate
        @overlay.fadeOut "slow"


  ThemeSwitch.init = (options) ->
    $toggler  = $ options.toggler
    themeIds  = $.map options.themes, (_, id) -> id
    switcher  = new ThemeSwitch themeIds, options.overlayClass

    switcher.onActivate = () ->
      $toggler.text options.themes[switcher.nextTheme()]

      # disqus is enabled for posts only
      window.DISQUS.reset({ reload: true }) if window.disqus_shortname

    $toggler.on "click", (event) ->
      switcher.toggle()
      false

    $toggler.text options.themes[switcher.nextTheme()]


  $ ->
    # Google Analytics
    window._gaq = [ ["_setAccount", "UA-35573678-1"], ["_trackPageview"] ];
    injectScript "http://www.google-analytics.com/ga.js"

    # Disqus
    if 0 < $("#disqus_thread").length
      window.disqus_shortname = "ixti";
      injectScript "http://#{window.disqus_shortname}.disqus.com/embed.js"

    # Light/Dark theme switcher
    ThemeSwitch.init
      themes:
        light: "Light Theme"
        dark:  "Dark Theme"
      toggler: $("#js-theme-switcher > a")

    # Notify that user has JS
    $("html").addClass("js").removeClass("nojs");
