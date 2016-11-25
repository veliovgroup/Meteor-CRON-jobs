Package.describe({
  name: 'ostrio:cron-jobs',
  version: '1.0.8',
  summary: 'Task scheduler. With support of cluster or multiple NodeJS instances.',
  git: 'https://github.com/VeliovGroup/Meteor-CRON-jobs',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.4');
  api.use(['coffeescript', `ecmascript`, 'mongo', 'check', 'sha'], 'server');
  api.mainModule('cron-jobs.coffee', 'server');
  api.export('CRONjob');
});
