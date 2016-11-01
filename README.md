CRON Jobs for meteor
========
Simple package with similar API to native `setTimeout` and `setInterval` methods, but synced between all running NodeJS (Meteor) instances.

Multi-instance task manager for Meteor. This package has support of cluster or multi-thread NodeJS instances. This package will help you to make sure only one process of each task is running.

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

ES6 Import:
======
```jsx
import { CRONjob } from 'meteor/ostrio:cron-jobs';
```

API:
========
`new CRONjob([prefix, resetOnInit])`:

 - `prefix` {*String*} - [Optional] use to create multiple named instances
 - `resetOnInit` {*Boolean*} - [Optional] make sure all old tasks is completed before set new one. Useful when you run only one instance of app, or multiple app instances on one machine, in case machine was reloaded during running task and task is unfinished
 - `zombieTime` {*Number*} - [Optional] time in milliseconds, after this time - task will be interpreted as "*zombie*". This parameter allows to rescue task from "*zombie* mode" in case when `ready()` wasn't called, exception during runtime was thrown, or caused by bad logic. Where `resetOnInit` makes sure task is done on startup, but `zombieTime` doing the same function but during runtime. Default value is `900000` (*15 minutes*)

#### Initialization:
```javascript
var CRON = new CRONjob();

// Alternatively pass an unique id {String} to constructor, to have multiple CRONs:
var CRON1 = new CRONjob('1');
var CRON2 = new CRONjob('2');
```

Note: This library relies on function names, so you can not pass same function (with same name) into its methods. To use lib's methods on same function use different instances. Like:

```javascript
var CRON1 = new CRONjob('1');
var CRON2 = new CRONjob('2');

var task = function (ready) {
  //...some code here
  ready();
};

CRON1.setInterval(task, 60*60*1000, 'task-1000');
CRON2.setInterval(task, 60*60*2000, 'task-2000');
```

Passing arguments (*not really fancy solution, sorry*):
```javascript
var CRON = new CRONjob();
var globalVar = 'Some top level or env variable (can be changed over time)';

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

Note: This library uses on function names and its contents, so after deploying new version of your application to server, you need to clean up old tasks:
```js
// Run directly in MongoDB console:
db.getCollection('__CRONjobs__').remove({});
// If you're using multiple CRONjob instances with prefix:
db.getCollection('__CRONjobs__PrefixHere').remove({});
```


#### `setInterval(func, delay, uid)`

 - `func`  {*Function*} - Function to call on schedule
 - `delay` {*Number*}   - Delay for first run and interval between further executions in milliseconds
 - `uid`   {*String*}   - [Optional] recommended to set. Unique app-wide task id

*Set task into interval execution loop. You can not set same function multiple times into interval.*
`ready()` *is passed as argument into function, and must be called in all tasks.*

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

In this example, next task will not wait for current task is ready:
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

In this example, we're assuming to have long running task, and execute it in a loop without delay, but after full execution:
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
 - `uid`   {*String*}   - [Optional] recommended to set. Unique app-wide task id

*Set task into timeout execution. You can not set same function multiple times into timeout.*
*`setTimeout` is useful for cluster - when you need to make sure task was executed only once.*
`ready()` *is passed as argument into function, and must be called in all tasks.*

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
 - `uid`  {*String*}   - [Optional] recommended to set. Unique app-wide task id

*Immediate execute function, and only once. You can not set same function multiple times into immediate execution.*
`setImmidiate` *is useful for cluster - when you need to execute function immediately and only once.*
`ready()` *is passed as argument into function, and must be called in all tasks.*

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
var timer = CRON.setInterval(func, 34789);
CRON.clearInterval(timer);
```

#### `clearTimeout(timer)`
*Cancel (abort) current timeout timer.*

```javascript
var timer = CRON.setTimeout(func, 34789);
CRON.clearTimeout(timer);
```