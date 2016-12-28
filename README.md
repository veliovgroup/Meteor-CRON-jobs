CRON Jobs for meteor
========
Simple package with similar API to native `setTimeout` and `setInterval` methods, but synced between all running Meteor (NodeJS) instances.

Multi-instance task manager for Node.js. This package has support of cluster or multi-thread NodeJS instances. This package will help you to make sure only one process of each task is running.

__This is server-only package.__

- [Install](https://github.com/VeliovGroup/Meteor-CRON-jobs#install)
- [API](https://github.com/VeliovGroup/Meteor-CRON-jobs#api)
- [Constructor](https://github.com/VeliovGroup/Meteor-CRON-jobs#initialization)
- [setInterval](https://github.com/VeliovGroup/Meteor-CRON-jobs#setintervalfunc-delay)
- [setTimeout](https://github.com/VeliovGroup/Meteor-CRON-jobs#settimeoutfunc-delay)
- [setImmidiate](https://github.com/VeliovGroup/Meteor-CRON-jobs#setimmidiatefunc)
- [clearInterval](https://github.com/VeliovGroup/Meteor-CRON-jobs#clearintervaltimer)
- [clearTimeout](https://github.com/VeliovGroup/Meteor-CRON-jobs#cleartimeouttimer)

Install:
========
```shell
meteor add ostrio:cron-jobs
```
Looking for NPM version? - Go to [JoSk package](https://github.com/VeliovGroup/josk)

Import:
======
```jsx
import { CRONjob } from 'meteor/ostrio:cron-jobs';
```

Known Issues:
========
```
Error: Can't wait without a fiber
```
Can be easily solved via "bounding to Fiber":
```js
const bound = Meteor.bindEnvironment((callback) => {
  callback();
});

var db   = Collection.rawDatabase();
var CRON = new CRONjob({db: db});

var task = (ready) => {
  bound(() => {
    ready();
  });
};

CRON.setInterval(task, 60*60*1000, 'task');
```

API:
========
`new CRONjob({opts})`:
 - `opts.db` {*Object*} - [Required] Connection to MongoDB
 - `opts.prefix` {*String*} - [Optional] use to create multiple named instances
 - `opts.resetOnInit` {*Boolean*} - [Optional] make sure all old tasks is completed before set new one. Useful when you run only one instance of app, or multiple app instances on one machine, in case machine was reloaded during running task and task is unfinished
 - `opts.zombieTime` {*Number*} - [Optional] time in milliseconds, after this time - task will be interpreted as "*zombie*". This parameter allows to rescue task from "*zombie* mode" in case when `ready()` wasn't called, exception during runtime was thrown, or caused by bad logic. Where `resetOnInit` makes sure task is done on startup, but `zombieTime` doing the same function but during runtime. Default value is `900000` (*15 minutes*)

#### Initialization:
```javascript
// Meteor.users.rawDatabase() is available in most Meteor setups
// If this is not your case, you can use `rawDatabase` form any other collection
var db   = Meteor.users.rawDatabase();
var CRON = new CRONjob({db: db});
```

Note: This library relies on job ID, so you can not pass same job (with same ID). Always use different `uid`, even for same task:
```javascript
var task = function (ready) {
  //...some code here
  ready();
};

CRON.setInterval(task, 60*60*1000, 'task-1000');
CRON.setInterval(task, 60*60*2000, 'task-2000');
```

Passing arguments (*not really fancy solution, sorry*):
```javascript
var CRON      = new CRONjob({db: db});
var globalVar = 'Some top level or env.variable (can be changed over time)';

var task = function (arg1, arg2, ready) {
  //...some code here
  ready();
};

var taskB = function (ready) {
  task(globalVar, 'b', ready);
};

var task1 = function (ready) {
  task(1, globalVar, ready);
};

CRON.setInterval(taskB, 60*60*1000, 'taskB');
CRON.setInterval(task1, 60*60*1000, 'task1');
```

Note: To cleanup old tasks via MongoDB use next query pattern:
```js
// Run directly in MongoDB console:
db.getCollection('__JobTasks__').remove({});
// If you're using multiple CRONjob instances with prefix:
db.getCollection('__JobTasks__PrefixHere').remove({});
```


#### `setInterval(func, delay, uid)`

 - `func`  {*Function*} - Function to call on schedule
 - `delay` {*Number*}   - Delay for first run and interval between further executions in milliseconds
 - `uid`   {*String*}   - Unique app-wide task id

*Set task into interval execution loop.* `ready()` *is passed as third argument into function.*

In this example, next task will not be scheduled until current is ready:
```javascript
var syncTask = function (ready) {
  //...run sync code
  ready();
};
var asyncTask = function (ready) {
  asyncCall(function () {
    //...run more async code
    ready();
  });
};

CRON.setInterval(syncTask, 60*60*1000, 'syncTask');
CRON.setInterval(asyncTask, 60*60*1000, 'asyncTask');
```

In this example, next task will not wait for current task to finish:
```javascript
var syncTask = function (ready) {
  ready();
  //...run sync code
};
var asyncTask = function (ready) {
  ready();
  asyncCall(function () {
    //...run more async code
  });
};

CRON.setInterval(syncTask, 60*60*1000, 'syncTask');
CRON.setInterval(asyncTask, 60*60*1000, 'asyncTask');
```

In this example, we're assuming to have long running task, executed in a loop without delay, but after full execution:
```javascript
var longRunningAsyncTask = function (ready) {
  asyncCall(function (error, result) {
    if(error){
      ready(); // <-- Always run `ready()`, even if call was unsuccessful
    } else {
      anotherCall(result.data, ['param'], function (error, response) {
        waitForSomethingElse(response, function () {
          ready(); // <-- End of full execution
        });
      });
    }
  });
};

CRON.setInterval(longRunningAsyncTask, 0, 'longRunningAsyncTask');
```

#### `setTimeout(func, delay, uid)`

 - `func`  {*Function*} - Function to call on schedule
 - `delay` {*Number*}   - Delay in milliseconds
 - `uid`   {*String*}   - Unique app-wide task id

*Set task into timeout execution.* `setTimeout` *is useful for cluster - when you need to make sure task was executed only once.*
`ready()` *is passed as third argument into function.*

```javascript
var syncTask = function (ready) {
  //...run sync code
  ready();
};
var asyncTask = function (ready) {
  asyncCall(function () {
    //...run more async code
    ready();
  });
};

CRON.setTimeout(syncTask, 60*60*1000, 'syncTask');
CRON.setTimeout(asyncTask, 60*60*1000, 'asyncTask');
```

#### `setImmidiate(func, uid)`

 - `func` {*Function*} - Function to execute
 - `uid`  {*String*}   - Unique app-wide task id

*Immediate execute function, and only once.* `setImmidiate` *is useful for cluster - when you need to execute function immediately and only once across all servers.* `ready()` *is passed as third argument into function.*

```javascript
var syncTask = function (ready) {
  //...run sync code
  ready();
};
var asyncTask = function (ready) {
  asyncCall(function () {
    //...run more async code
    ready();
  });
};

CRON.setImmidiate(syncTask, 'syncTask');
CRON.setImmidiate(asyncTask, 'asyncTask');
```

#### `clearInterval(timer)`
*Cancel (abort) current interval timer.*

```javascript
var timer = CRON.setInterval(func, 34789, 'unique-taskid');
CRON.clearInterval(timer);
```

#### `clearTimeout(timer)`
*Cancel (abort) current timeout timer.*

```javascript
var timer = CRON.setTimeout(func, 34789, 'unique-taskid');
CRON.clearTimeout(timer);
```