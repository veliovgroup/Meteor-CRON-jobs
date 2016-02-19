class CRONjob
  constructor: (prefix = '') ->
    check prefix, String

    @collection = new Mongo.Collection "__CRONjobs__#{prefix}"
    @collection._ensureIndex {uid: 1}, {background: true, unique: true}
    @collection.remove {}
    
    self   = @
    @tasks = {}
    cursor = @collection.find {}

    cursor.observe
      added: (doc) -> 
        Meteor.setTimeout ->
          currentTask = self.collection.findOne {uid: doc.uid}
          if currentTask and currentTask?.inProgress is false
            ready = -> 
              if doc.interval is true
                self.collection.update {uid: doc.uid}, 
                  $set: 
                    executedAt: new Date()
                    inProgress: false
              else
                self.__clear doc.uid

            self.collection.update {uid: doc.uid}, $set: inProgress: true

            Meteor.setTimeout ->
              if self.tasks?[doc.uid]
                self.tasks[doc.uid](ready)
              else
                console.warn 'Something went wrong with one of your tasks - it\'s is missing. Try to use different instances.'
                console.trace()
            , doc.delay
        , Math.random() * (150 - 1) + 1

      changed: (newDocument) -> 
        if newDocument.interval is true and newDocument.inProgress is false
          Meteor.setTimeout ->
            currentTask = self.collection.findOne {uid: newDocument.uid}
            if currentTask and currentTask?.inProgress is false
              ready = -> 
                self.collection.update {uid: newDocument.uid}, 
                  $set: 
                    executedAt: new Date()
                    inProgress: false

              self.collection.update {uid: newDocument.uid}, $set: inProgress: true

              Meteor.setTimeout ->
                if self.tasks?[newDocument.uid]
                  self.tasks[newDocument.uid](ready)
                else
                  console.warn 'Something went wrong with one of your tasks - it\'s is missing. Try to use different instances.'
                  console.trace()
              , newDocument.delay
          , Math.random() * (150 - 1) + 1

      removed: (doc) -> 
        delete self.tasks[doc.uid] if self.tasks?[doc.uid]

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
    @collection.remove {uid}, () -> return true
    return true

  __addTask: (uid, interval, delay) ->
    check uid,      String
    check delay,    Number
    check interval, Boolean
    Meteor.setTimeout =>
      currentTask = @collection.findOne {uid}
      unless currentTask
        _id = @collection.insert
          uid:        uid
          delay:      delay
          interval:   interval
          executedAt: new Date 0
          inProgress: false
    , Math.random() * (150 - 1) + 1