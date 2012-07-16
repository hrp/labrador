class @TableView extends Backbone.View
  
  maxChars: 120
  $selectedRow: null

  initialize: (attributes) ->
    @model.on 'change:data', => @render(@model.get('data').fields, @model.get('data').items)
    @model.on 'before:send', => 
      @emptyBody()
      @showLoading(5)


  truncate: (str, limit, endWith = "...") ->
    str = str.toString()
    return str if str.length <= limit + endWith.length
    str.substring(0, limit) + endWith


  setTableHeaderWidth: ->
    $headers = ($(h) for h in @$el.find("thead tr th"))
    for td, i in @$el.find("tbody tr:first td")
      width = $(td).width() - 1
      $headers[i].css('min-width': width, 'max-width': width)


  bind: ->
    @$el.unbind()
    $tbody = @$el.find("tbody")
    $tableContainer = @$el.parent(".fixed-table-container")
    $row = $tableContainer.find("thead tr")
    $tableContainer[0].removeEventListener('scroll', this)
    $tableContainer[0].addEventListener 'scroll', (=>
      $row.css(top: $tableContainer.scrollTop())
      @trigger('scroll')
    ), capture = true

    $tbody.off('click', 'tr').on 'click', 'tr', (e) =>
      e.preventDefault()
      $target = $(e.currentTarget)
      @$selectedRow?.removeAttr("data-active")
      $target.attr("data-active", true)
      @$selectedRow = $target
     

    @$el.find("thead").off('click', 'th').on 'click', 'th', (e) =>
      e.preventDefault()
      $target = $(e.currentTarget)
      field = $target.attr("data-field")
      direction = $target.attr('data-direction')
      @$el
        .removeAttr("data-direction")
        .find("th [data-action=asc], [data-action=desc]").hide()
      if direction is 'asc'
        $target.attr('data-direction', 'desc')
        $target.find("[data-action='desc']").show()
        @model.filterPrevious(order_by: field, direction: 'desc')
      else
        $target.attr('data-direction', 'asc')
        $target.find("[data-action='asc']").show()
        @model.filterPrevious(order_by: field, direction: 'asc')
 
    @$el.find("thead th [data-action='expand']").off('click').on 'click', (e) =>
      e.stopPropagation()
      $parent = $(e.target).parents("th")
      field = $parent.attr("data-field")
      @$el.find("[data-field='#{field}']").attr("data-expanded", true)
      @setTableHeaderWidth()


    @$el.find("thead th [data-action='contract']").off('click').on 'click', (e) =>
      e.stopPropagation()
      $parent = $(e.target).parents("th")
      field = $parent.attr("data-field")
      @$el.find("[data-field='#{field}']").removeAttr("data-expanded")
      @setTableHeaderWidth()


    onDoubleClick = (e) =>
      @$el[0].removeEventListener('dblclick', onDoubleClick, true)
      console.log 'dblclick'
      $tbody.off('dblclick', 'td').on 'dblclick', 'td', (e) => 
        e.preventDefault()
        console.log 'td dblclick'
        app.hideTooltips()
        $pop = $(e.currentTarget)
        field = $pop.attr("data-field")
        item = new Item(primaryKeyName: @model.primaryKey(), data: @serializeRow($pop.parent("tr")))
        $pop.attr("data-content", @editTemplate(item, field))
        app.popover($pop, placement: 'bottom', trigger: 'manual', title: $pop.attr('data-field'))
        app.popover($pop, 'show')
        @bindEditItem($pop, item, field)

    @$el[0].removeEventListener('dblclick', onDoubleClick, true)
    @$el[0].addEventListener 'dblclick', onDoubleClick, capture = true


  # Bind edit tooltip close/save events
  #
  # params - The hash of params
  #   $td - The jQuery DOM object to update when saving
  #   item - The Item model
  #   field - The field name of the cell being bound
  #
  bindEditItem: ($td, item, field) ->
    $pop = $("body > .popover:last")
    $input = $pop.find("input, textarea")
    $input.focus()
    $pop.find("[data-action=close]").on 'click', (e) => 
      e.preventDefault()
      app.hideTooltips()
    onSave = =>
      app.hideTooltips()
      data = {}
      value = $input.val()
      data[field] = value
      @model.update @model.collection(), item.get('primaryKeyValue'), data, (error) =>         
        @updateRowCell(item.get('primaryKeyValue'), field, value) unless error

    $pop.find("[data-action=save]").on 'click', (e) => 
      e.preventDefault()
      onSave()
    $input.on 'keypress', (e) =>
      if e.keyCode is 13
        e.preventDefault()
        onSave()


  # Update DOM of table cell with field name at given row id
  #
  # rowId - The primary key value of the row
  # field - The String field name of the row's cell to update
  # value - The updated value of the field
  #
  updateRowCell: (rowId, field, value) ->
    $td = @$el.find("tbody tr[data-id='#{rowId}'] td[data-field='#{field}']")
    $newTd = $("<td/>")    
    type = $td.attr('data-type')
    expanded = $td.attr('data-expanded')
    $td.attr('data-value', _.escape(value))
    $td.html( $(@cellTemplate(type, field, expanded, value)).html() )


  # Returns the selected Item model from table
  selectedItem: ->
    $item = $("tr[data-active=true]")
    return if $item.length is 0
    $item = $($item[0])
    item = new Item(primaryKeyName: @model.primaryKey(), data: @serializeRow($item))

    item
    

  # Serialize table dom object into hash
  serializeRow: ($row) ->
    $row = $($row)
    attributes = {}
    for td in $row.find("td")
      $td = $(td)
      attributes[$td.attr('data-field')] = $td.attr('data-value')

    attributes


  anyFieldChanged: (newFields) ->
    (newFields.some (field) => @$el.find("th[data-field='#{field}']").length is 0)

  
  # Returns array of all expanded fields
  expandedFields: ->
    ($(th).attr('data-field') for th in @$el.find("th[data-expanded=true]"))
    
  
  # Render table header template
  # 
  # fields - The array of String field names
  # 
  # Returns String of rendered table head HTML
  headerTemplate: (fields) ->
    thead = ""
    for field in fields        
      thead += """
        <th data-field='#{field}'>
          <span class='pull-left'>
            <i class='icon-chevron-up' data-action='asc'></i>
            <i class='icon-chevron-down' data-action='desc'></i>
          </span>
          <span class='pull-left'>#{field}</span>
          <span class='pull-right'>
            <i class='icon-arrow-right' data-action='expand'></i>
            <i class='icon-arrow-left' data-action='contract'></i>
          </span>
        </th>
      """

    thead


  # Render template for edit tooltip
  #
  # data - The hash of data
  #   item - The Item to edit
  #   field - The field of the item being edited
  #
  # Returns the rendered HTML template for the tooltip 
  editTemplate: (item, field) ->
    id = item.get('primaryKeyValue')
    value = item.val(field)
    if value.search("\n") >= 0 or value.search(/\W/) >= 0
      """
        <div class="edit">
          <textarea data-id="#{id}" data-field="#{field}">#{value}</textarea>
          <div class="pull-right">
            <a class="btn" href="#" data-action="close">close</a>
            <a class="btn btn-primary" href="#" data-action="save">save</a>
          </div>
        </div>
      """
    else
      """
        <div class="edit">
          <input type="text" data-field="#{field}" value="#{_.escape(value)}" />
          <div class="pull-right">
            <a class="btn" href="#" data-action="close">close</a>
            <a class="btn btn-primary" href="#" data-action="save">save</a>
          </div>
        </div>
      """

 
  # Renders table cell to HTML
  # 
  # type - The String type of cell, one of "string", "number", "json"
  # field - The String name of the field being rendered
  # expanded - The boolean expanded option to expand cell
  # val - The value of the field
  #
  # Returns the rendered HTML
  cellTemplate: (type, field, expanded, val) ->
    """
      <td data-type='#{type}' data-field='#{field}' data-expanded='#{expanded}' rel='popover' data-value='#{_.escape(val)}'>
        <div class='value'>#{_.escape(@truncate(val, @maxChars))}</div>
        <div class='truncated'>#{_.escape(@truncate(val, 16))}</div>
      </td>
    """

  # Renders table body
  #
  # fields - The array of String field names
  # items - The array of items with fields as key names and values of each field
  # callback - The callback when finished processing all items. 
  #            Callback receives rendered output
  #
  bodyTemplate: (fields, items, callback) ->
    rows = []
    count = 0
    expandedFields = @expandedFields()
    primaryKeyField = (field for field in fields when field is @model.primaryKey())[0]
    processRows = (item, done) =>
      id = item[primaryKeyField]
      rows.push "<tr data-id='#{id}' class='#{if count % 2 is 0 then '' else 'odd'}'>"
      for field in fields
        val = item[field] ? ""
        if $.isNumeric(val)
          type = 'number'
        else if typeof(val) is 'object'
          type = 'json'
          val = JSON.stringify(val)
        else
          type = 'string'
        expanded = if expandedFields.indexOf(field) >= 0 then 'true' else 'false'
        rows.push @cellTemplate(type, field, expanded, val)
      rows .push "</tr>"
      count += 1
      if Math.round((count / items.length) * 100) % 5 is 0
        @showLoading(Math.round((count / items.length) * 100))
      setTimeout(done, 20)

    q = async.queue(processRows, concurrency = 25)
    q.push(items)
    q.drain = -> callback(rows.join(''))
    

  emptyBody: ->
    @$el.find("tbody").empty()


  # Renders table
  #
  # fields - The array of String field names
  # items - The hash of key values with field names as keys
  #
  render: (fields, items) ->
    app.hideTooltips()
    @emptyBody()
    return @zeroState() if fields.length is 0 or items.length is 0

    if @anyFieldChanged(fields)
      @$el.find("thead tr").html(@headerTemplate(fields))

    @bodyTemplate fields, items, (body) =>
      @$el.find("tbody").append(body)
      @setTableHeaderWidth()
      @bind()
      @hideLoading()
      @trigger('render')


  showLoading: (percentage) ->
    app.progressView.show(percentage)

  
  hideLoading: ->
    app.progressView.hide()


  zeroState: ->
    @hideLoading()
    @trigger('render')


