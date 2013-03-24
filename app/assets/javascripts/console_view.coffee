class @ConsoleView extends Backbone.View
  
  el: "#console"

  initialize: (attributes = {}) ->
    @$prompt = @$el.find(".prompt")
    @$prompt.css(color: "red")

