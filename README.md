# CRON Jobs for meteor

__301: This package is moved to the main repository of [NPM version](https://github.com/VeliovGroup/josk), but still can be installed via Atmosphere as Meteor package!__

## Install:

```shell
meteor add ostrio:cron-jobs
```

Looking for NPM version? - Go to [JoSk package](https://github.com/VeliovGroup/josk)

## Import:

```js
import { CRONjob } from 'meteor/ostrio:cron-jobs';
```

## Known Issues:

```log
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

cron.setInterval(task, 60 * 60 * 1000, 'task');
```
