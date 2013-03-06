class @ConsoleView extends Backbone.View

  initialize: (attributes) ->
    @render()

  render: =>
    console.log @el
    @$el.html('YOLO')