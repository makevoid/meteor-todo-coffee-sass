Lists = new Meteor.Collection("lists")
Todos = new Meteor.Collection("todos")
Session.set "list_id", null
Session.set "tag_filter", null
Session.set "editing_addtag", null
Session.set "editing_listname", null
Session.set "editing_itemname", null

Meteor.subscribe "lists", ->
  unless Session.get("list_id")
    list = Lists.findOne({},
      sort:
        name: 1
    )
    Router.setList list._id  if list

Meteor.autosubscribe ->
  list_id = Session.get("list_id")
  Meteor.subscribe "todos", list_id  if list_id

okcancel_events = (selector) ->
  "keyup " + selector + ", keydown " + selector + ", focusout " + selector

make_okcancel_handler = (options) ->
  ok = options.ok or ->

  cancel = options.cancel or ->

  (evt) ->
    if evt.type is "keydown" and evt.which is 27
      cancel.call this, evt
    else if evt.type is "keyup" and evt.which is 13 or evt.type is "focusout"
      value = String(evt.target.value or "")
      if value
        ok.call this, value, evt
      else
        cancel.call this, evt

focus_field_by_id = (id) ->
  input = document.getElementById(id)
  if input
    input.focus()
    input.select()

Template.lists.lists = ->
  Lists.find {},
    sort:
      name: 1

Template.lists.events =
  "mousedown .list": (evt) ->
    Router.setList @_id

  "dblclick .list": (evt) ->
    Session.set "editing_listname", @_id
    Meteor.flush()
    focus_field_by_id "list-name-input"

Template.lists.events[okcancel_events("#list-name-input")] = make_okcancel_handler(
  ok: (value) ->
    Lists.update @_id,
      $set:
        name: value

    Session.set "editing_listname", null

  cancel: ->
    Session.set "editing_listname", null
)
Template.lists.events[okcancel_events("#new-list")] = make_okcancel_handler(ok: (text, evt) ->
  id = Lists.insert(name: text)
  Router.setList id
  evt.target.value = ""
)
Template.lists.selected = ->
  (if Session.equals("list_id", @_id) then "selected" else "")

Template.lists.name_class = ->
  (if @name then "" else "empty")

Template.lists.editing = ->
  Session.equals "editing_listname", @_id

Template.todos.any_list_selected = ->
  not Session.equals("list_id", null)

Template.todos.events = {}
Template.todos.events[okcancel_events("#new-todo")] = make_okcancel_handler(ok: (text, evt) ->
  tag = Session.get("tag_filter")
  Todos.insert
    text: text
    list_id: Session.get("list_id")
    done: false
    timestamp: (new Date()).getTime()
    tags: (if tag then [ tag ] else [])

  evt.target.value = ""
)
Template.todos.todos = ->
  list_id = Session.get("list_id")
  return {}  unless list_id
  sel = list_id: list_id
  tag_filter = Session.get("tag_filter")
  sel.tags = tag_filter  if tag_filter
  Todos.find sel,
    sort:
      timestamp: 1

Template.todo_item.tag_objs = ->
  todo_id = @_id
  _.map @tags or [], (tag) ->
    todo_id: todo_id
    tag: tag

Template.todo_item.done_class = ->
  (if @done then "done" else "")

Template.todo_item.done_checkbox = ->
  (if @done then "checked=\"checked\"" else "")

Template.todo_item.editing = ->
  Session.equals "editing_itemname", @_id

Template.todo_item.adding_tag = ->
  Session.equals "editing_addtag", @_id

Template.todo_item.events =
  "click .check": ->
    Todos.update @_id,
      $set:
        done: not @done

  "click .destroy": ->
    Todos.remove @_id

  "click .addtag": (evt) ->
    Session.set "editing_addtag", @_id
    Meteor.flush()
    focus_field_by_id "edittag-input"

  "dblclick .display .todo-text": (evt) ->
    Session.set "editing_itemname", @_id
    Meteor.flush()
    focus_field_by_id "todo-input"

  "click .remove": (evt) ->
    tag = @tag
    id = @todo_id
    evt.target.parentNode.style.opacity = 0
    Meteor.setTimeout (->
      Todos.update
        _id: id
      ,
        $pull:
          tags: tag
    ), 300

Template.todo_item.events[okcancel_events("#todo-input")] = make_okcancel_handler(
  ok: (value) ->
    Todos.update @_id,
      $set:
        text: value

    Session.set "editing_itemname", null

  cancel: ->
    Session.set "editing_itemname", null
)
Template.todo_item.events[okcancel_events("#edittag-input")] = make_okcancel_handler(
  ok: (value) ->
    Todos.update @_id,
      $addToSet:
        tags: value

    Session.set "editing_addtag", null

  cancel: ->
    Session.set "editing_addtag", null
)
Template.tag_filter.tags = ->
  tag_infos = []
  total_count = 0
  Todos.find(list_id: Session.get("list_id")).forEach (todo) ->
    _.each todo.tags, (tag) ->
      tag_info = _.find(tag_infos, (x) ->
        x.tag is tag
      )
      unless tag_info
        tag_infos.push
          tag: tag
          count: 1
      else
        tag_info.count++

    total_count++

  tag_infos = _.sortBy(tag_infos, (x) ->
    x.tag
  )
  tag_infos.unshift
    tag: null
    count: total_count

  tag_infos

Template.tag_filter.tag_text = ->
  @tag or "All items"

Template.tag_filter.selected = ->
  (if Session.equals("tag_filter", @tag) then "selected" else "")

Template.tag_filter.events = "mousedown .tag": ->
  if Session.equals("tag_filter", @tag)
    Session.set "tag_filter", null
  else
    Session.set "tag_filter", @tag

TodosRouter = Backbone.Router.extend(
  routes:
    ":list_id": "main"

  main: (list_id) ->
    Session.set "list_id", list_id
    Session.set "tag_filter", null

  setList: (list_id) ->
    @navigate list_id, true
)

Router = new TodosRouter
Meteor.startup ->
  Backbone.history.start pushState: true