class @HeaderView extends Backbone.View

  el: '[data-view=header]'

  events:
    'click [data-action=schema]'   : 'showSchema'
    'click [data-action=content]'  : 'showContent'
    'click [data-action=console]'  : 'showConsole'


  initialize: ->
    @cacheSelectors()
    @bind()


  bind: ->
  

  cacheSelectors: ->
    @$schema = @$("[data-action=next-page]")
    @$content = @$("[data-action=prev-page]")


  showSchema: (e) ->
    app.showSchema()


  showContent: (e) ->
    app.showContent()


  showConsole: (e) ->
    app.showConsole()
