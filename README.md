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

API:
========
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

CRON1.setInterval(task, 60*60*1000);
CRON2.setInterval(task, 60*60*2000);
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

CRON.setInterval(taskB, 60*60*1000);
CRON.setInterval(task1, 60*60*1000);
```


#### `setInterval(func, delay)`
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

CRON.setInterval(syncTask, 60*60*1000);
CRON.setInterval(asyncTask, 60*60*1000);
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

CRON.setInterval(syncTask, 60*60*1000);
CRON.setInterval(asyncTask, 60*60*1000);
```

In this example, we're assuming to have long running task, and execute it in a loop without delay, but after full execution:
```javascript
var longRunningAsyncTask = function (ready) {
  ready();
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

CRON.setInterval(longRunningAsyncTask, 0);
```

#### `setTimeout(func, delay)`
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

CRON.setTimeout(syncTask, 60*60*1000);
CRON.setTimeout(asyncTask, 60*60*1000);
```

#### `setImmidiate(func)`
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

CRON.setImmidiate(syncTask);
CRON.setImmidiate(asyncTask);
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