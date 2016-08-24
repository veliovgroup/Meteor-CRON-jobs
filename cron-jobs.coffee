NoOp =-> return

class CRONjob
  constructor: (prefix = '', resetOnInit = false, @zombieTime = 900000) ->
    check prefix, String
    check resetOnInit, Boolean
    check @zombieTime, Number

    @collection = new Mongo.Collection "__CRONjobs__#{prefix}"
    @collection._ensureIndex {uid: 1}, {background: true, unique: true}
    @collection._ensureIndex {executeAt: 1, inProgress: 1}, {background: true}

    if resetOnInit
      @collection.update {}, {$set: inProgress: false}, NoOp
      @collection.remove {isInterval: false}, NoOp
    
    @tasks = {}
    @__poll()

  __poll: ->
    self = @
    Meteor.setTimeout ->
      cursor = self.collection.find
        $or: [{
          executeAt: $lte: new Date()
          inProgress: false
        }, {
          executeAt: $lte: new Date((+new Date) - self.zombieTime)
          inProgress: true
        }]

      count  = cursor.count()
      if count > 0
        i = 0

        cursor.forEach (task) ->
          ++i
          if self.tasks?[task.uid]
            self.__execute task
          if i is count
            self.__poll()
          return
      else
        self.__poll()
      return
    , Math.random() * (2500 - 1500) + 1500

  setInterval: (func, delay) ->
    check func,  Function
    check delay, Number

    throw new Meteor.Error 500, '[ostrio:cron-jobs] [setInterval] delay must be positive Number!' if delay < 0
    uid = SHA256 'setInterval' + func
    @tasks[uid] = func
    @__addTask uid, true, delay
    return uid

  setTimeout: (func, delay) ->
    check func,  Function
    check delay, Number

    throw new Meteor.Error 500, '[ostrio:cron-jobs] [setTimeout] delay must be positive Number!' if delay < 0
    uid = SHA256 'setTimeout' + func
    @tasks[uid] = func
    @__addTask uid, false, delay
    return uid

  setImmediate: (func) -> 
    check func, Function
    uid = SHA256 'setImmediate' + func
    @tasks[uid] = func
    @__addTask uid, false, 0
    return uid

  clearInterval: -> 
    @__clear.apply @, arguments

  clearTimeout: -> 
    @__clear.apply @, arguments

  __clear: (uid) ->
    check uid, String
    self = @
    @collection.update {uid},
      $unset: 
        executeAt: ''
        inProgress: ''
    , ->
      self.collection.remove {uid}, NoOp
      return
    delete @tasks[uid] if @tasks?[uid]
    return true

  __addTask: (uid, isInterval, delay) ->
    check uid,        String
    check delay,      Number
    check isInterval, Boolean

    task = @collection.findOne {uid}
    unless task
      @collection.insert
        uid:        uid
        delay:      delay
        executeAt:  new Date((+new Date) + delay)
        isInterval: isInterval
        inProgress: false
      , NoOp
    else
      update = null
      if task.delay isnt delay
        update ?= {}
        update.delay = delay

      if +task.executeAt > +new Date() + delay
        update ?= {}
        update.executeAt = new Date((+new Date) + delay)
      
      if update
        @collection.update {uid}, {$set: update}, NoOp
    return

  __execute: (task) ->
    self = @
    @collection.update {uid: task.uid}, {$set: inProgress: true}, ->
      if self.tasks?[task.uid]
        ready = ->
          if task.isInterval is true
            self.collection.update {uid: task.uid}, 
              $set: 
                executeAt:  new Date((+new Date) + task.delay)
                inProgress: false
            , NoOp
          else
            self.__clear task.uid
          return

        self.tasks[task.uid](ready)
      else
        console.warn 'Something went wrong with one of your tasks - it\'s is missing. Try to use different instances.'
        console.trace()
      return
    return