class @ConsoleView extends Backbone.View
  
  el: "#console"

  events:
    'click .go': 'send_command'
    'keyup input': 'sendOnEnter'


  sendOnEnter: (e) =>
    if (e.keyCode == 75 and e.ctrlKey)
      @clear_history()
    else if (e.keyCode != 13)
      return
    else
      @send_command(e)


  initialize: (attributes = {}) ->
    @$prompt = @$el.find(".prompt")
    @$prompt.css(color: "red")


  send_command: (e) ->
    @$cmdline = @$el.find(".cmdline")
    val = @$cmdline.val()
    @$cmdline.val('')
    @$output = @$el.find(".output")
    @$output.append("<div>$> #{val}</div>")

  clear_history: ->
    @$el.find(".output").html('')
    @$el.find(".cmdline").val('')


class @History extends Backbone.Collection
