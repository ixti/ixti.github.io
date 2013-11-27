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

      @active = do =>
        id = store.get("theme") || $("body").data("default-theme")
        $.grep(@themes, (o) -> o.id == id)[0] || @themes[0]

      @reset()


    inactive: () ->
      $.grep @themes, (o) => o.id != @active.id


    nextTheme: () ->
      @inactive().shift()


    toggle: () ->
      @themes = @inactive().concat [@active]
      @activate @themes[0]


    reset: () ->
      @ids ||= $.map @themes, (o) -> o.id
      $("body").removeClass(@ids.join " ").addClass @active.id


    activate: (@active) ->
      @overlay.css({ backgroundColor: @active.overlayColor })
      @overlay.fadeIn "normal", () =>
        store.set "theme", @active.id
        @reset()
        @onActivate() if @onActivate
        @overlay.fadeOut "slow"


  ThemeSwitch.init = (toggler, themes) ->
    $toggler = $ toggler
    switcher = new ThemeSwitch themes

    switcher.onActivate = () ->
      $toggler.text switcher.nextTheme().title
      window.DISQUS.reset({ reload: true }) if window.DISQUS

    $toggler.on "click", (event) ->
      switcher.toggle()
      false

    $toggler.text switcher.nextTheme().title


  $ ->
    # Google Analytics
    window._gaq = [ ["_setAccount", "UA-35573678-1"], ["_trackPageview"] ]
    injectScript "http://www.google-analytics.com/ga.js"

    # Disqus
    if 0 < $("#disqus_thread").length
      window.disqus_shortname = "ixti"
      injectScript "http://#{window.disqus_shortname}.disqus.com/embed.js"

    # Light/Dark theme switcher
    ThemeSwitch.init "#js-theme-switcher > a", [
      { id: "light", title: "Light Theme", overlayColor: "#222" },
      { id: "dark",  title: "Dark Theme",  overlayColor: "#fff" }
    ]

    # Notify that user has JS
    $("html").addClass("js").removeClass("nojs")
