CRON Jobs for meteor
========
Simple package with similar API to native `setTimeout` and `setInterval` methods, but synced between all running Meteor (NodeJS) instances.

Multi-instance task manager for Node.js. This package has the support of cluster or multi-thread NodeJS instances. This package will help you to make sure only one process of each task is running.

__This is a server-only package.__

- [__NPM__ version](https://github.com/VeliovGroup/josk)
- [Install](https://github.com/VeliovGroup/Meteor-CRON-jobs#install)
- [API](https://github.com/VeliovGroup/Meteor-CRON-jobs#api)
- [Constructor](https://github.com/VeliovGroup/Meteor-CRON-jobs#initialization)
- [setInterval](https://github.com/VeliovGroup/Meteor-CRON-jobs#setintervalfunc-delay)
- [setTimeout](https://github.com/VeliovGroup/Meteor-CRON-jobs#settimeoutfunc-delay)
- [setImmediate](https://github.com/VeliovGroup/Meteor-CRON-jobs#setImmediatefunc)
- [clearInterval](https://github.com/VeliovGroup/Meteor-CRON-jobs#clearintervaltimer)
- [clearTimeout](https://github.com/VeliovGroup/Meteor-CRON-jobs#cleartimeouttimer)
- [~90% tests coverage](https://github.com/VeliovGroup/Meteor-CRON-jobs#testing)

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

const db   = Collection.rawDatabase();
const cron = new CRONjob({db: db});

const task = (ready) => {
  bound(() => {
    ready();
  });
};

cron.setInterval(task, 60*60*1000, 'task');
```

API:
========
`new CRONjob({opts})`:
 - `opts.db` {*Object*} - [Required] Connection to MongoDB, like returned as argument from `Meteor.users.rawDatabase()`
 - `opts.prefix` {*String*} - [Optional] use to create multiple named instances
 - `opts.autoClear` {*Boolean*} - [Optional] Remove (*Clear*) obsolete tasks (*any tasks which are not found in the instance memory (runtime), but exists in the database*). Obsolete tasks may appear in cases when it wasn't cleared from the database on process shutdown, and/or was removed/renamed in the app. Obsolete tasks may appear if multiple app instances running different codebase within the same database, and the task may not exist on one of the instances. Default: `false`
 - `opts.resetOnInit` {*Boolean*} - [Optional] make sure all old tasks is completed before set new one. Useful when you run only one instance of app, or multiple app instances on one machine, in case machine was reloaded during running task and task is unfinished
 - `opts.zombieTime` {*Number*} - [Optional] time in milliseconds, after this time - task will be interpreted as "*zombie*". This parameter allows to rescue task from "*zombie* mode" in case when: `ready()` wasn't called, exception during runtime was thrown, or caused by bad logic. While `resetOnInit` option helps to make sure tasks are `done` on startup, `zombieTime` option helps to solve same issue, but during runtime. Default value is `900000` (*15 minutes*). It's not recommended to set this value to less than a minute (*60000ms*)
 - `opts.onError` {*Function*} - [Optional] Informational hook, called instead of throwing exceptions. Default: `false`. Called with two arguments:
     * `title` {*String*}
     * `details` {*Object*}
     * `details.description` {*String*}
     * `details.error` {*Mix*}
     * `details.uid` {*String*} - Internal `uid`, suitable for `.clearInterval()` and `.clearTimeout()`
 - `opts.onExecuted` {*Function*} - [Optional] Informational hook, called when task is finished. Default: `false`. Called with two arguments:
     * `uid` {*String*} - `uid` passed into `.setImmediate()`, `.setTimeout()`, or `setInterval()` methods
     * `details` {*Object*}
     * `details.uid` {*String*} - Internal `uid`, suitable for `.clearInterval()` and `.clearTimeout()`
     * `details.date` {*Date*} - Execution timestamp as JS *Date*
     * `details.timestamp` {*Number*} - Execution timestamp as unix *Number*

#### Initialization:
```javascript
// Meteor.users.rawDatabase() is available in most Meteor setups
// If this is not your case, you can use `rawDatabase` form any other collection
const db   = Meteor.users.rawDatabase();
const cron = new CRONjob({db: db});
```

Note: This library relies on job ID, so you can not pass the same job (with same ID). Always use different `uid`, even for the same task:
```javascript
const task = function (ready) {
  //...some code here
  ready();
};

cron.setInterval(task, 60*60*1000, 'task-1000');
cron.setInterval(task, 60*60*2000, 'task-2000');
```

Passing arguments (*not really fancy solution, sorry*):
```javascript
const cron    = new CRONjob({db: db});
let globalVar = 'Some top level or env.variable (can be changed over time)';

const task = function (arg1, arg2, ready) {
  //...some code here
  ready();
};

const taskB = function (ready) {
  task(globalVar, 'b', ready);
};

const task1 = function (ready) {
  task(1, globalVar, ready);
};

cron.setInterval(taskB, 60*60*1000, 'taskB');
cron.setInterval(task1, 60*60*1000, 'task1');
```

Note: To clean up old tasks via MongoDB use next query pattern:
```js
// Run directly in MongoDB console:
db.getCollection('__JobTasks__').remove({});
// If you're using multiple CRONjob instances with prefix:
db.getCollection('__JobTasks__PrefixHere').remove({});
```


#### `setInterval(func, delay, uid)`

 - `func`  {*Function*} - Function to call by schedule
 - `delay` {*Number*}   - Delay for first run and interval between further executions in milliseconds
 - `uid`   {*String*}   - Unique app-wide task id

*Set task into interval execution loop.* `ready()` *is passed as third argument into function.*

In this example, next task will not be scheduled until the current is ready:
```javascript
const syncTask = function (ready) {
  //...run sync code
  ready();
};

const asyncTask = function (ready) {
  asyncCall(function () {
    //...run more async code
    ready();
  });
};

cron.setInterval(syncTask, 60*60*1000, 'syncTask');
cron.setInterval(asyncTask, 60*60*1000, 'asyncTask');
```

In this example, next task will not wait for the current task to finish:
```javascript
const syncTask = function (ready) {
  ready();
  //...run sync code
};

const asyncTask = function (ready) {
  ready();
  asyncCall(function () {
    //...run more async code
  });
};

cron.setInterval(syncTask, 60*60*1000, 'syncTask');
cron.setInterval(asyncTask, 60*60*1000, 'asyncTask');
```

In this example, we're assuming to have long running task, executed in a loop without delay, but after full execution:
```javascript
const longRunningAsyncTask = function (ready) {
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

cron.setInterval(longRunningAsyncTask, 0, 'longRunningAsyncTask');
```

#### `setTimeout(func, delay, uid)`

 - `func`  {*Function*} - Function to call on schedule
 - `delay` {*Number*}   - Delay in milliseconds
 - `uid`   {*String*}   - Unique app-wide task id

*Set task into timeout execution.* `setTimeout` *is useful for cluster - when you need to make sure task was executed only once.*
`ready()` *is passed as third argument into function.*

```javascript
const syncTask = function (ready) {
  //...run sync code
  ready();
};

const asyncTask = function (ready) {
  asyncCall(function () {
    //...run more async code
    ready();
  });
};

cron.setTimeout(syncTask, 60*60*1000, 'syncTask');
cron.setTimeout(asyncTask, 60*60*1000, 'asyncTask');
```

#### `setImmediate(func, uid)`

 - `func` {*Function*} - Function to execute
 - `uid`  {*String*}   - Unique app-wide task id

*Immediate execute the function, and only once.* `setImmediate` *is useful for cluster - when you need to execute function immediately and only once across all servers.* `ready()` *is passed as the third argument into the function.*

```javascript
const syncTask = function (ready) {
  //...run sync code
  ready();
};

const asyncTask = function (ready) {
  asyncCall(function () {
    //...run more async code
    ready();
  });
};

cron.setImmediate(syncTask, 'syncTask');
cron.setImmediate(asyncTask, 'asyncTask');
```

#### `clearInterval(timer)`
*Cancel (abort) current interval timer.*

```javascript
const timer = cron.setInterval(func, 34789, 'unique-taskid');
cron.clearInterval(timer);
```

#### `clearTimeout(timer)`
*Cancel (abort) current timeout timer.*

```javascript
const timer = cron.setTimeout(func, 34789, 'unique-taskid');
cron.clearTimeout(timer);
```

Testing
======
```shell
meteor test-packages ./ --driver-package=meteortesting:mocha
# Be patient, tests are taking around 2 mins
```

Support this project:
======
This project wouldn't be possible without [ostr.io](https://ostr.io).

Using [ostr.io](https://ostr.io) you are not only [protecting domain names](https://ostr.io/info/domain-names-protection), [monitoring websites and servers](https://ostr.io/info/monitoring), using [Prerendering for better SEO](https://ostr.io/info/prerendering) of your JavaScript website, but support our Open Source activity, and great packages like this one could be available for free.