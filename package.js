Package.describe({
  name: 'ostrio:cron-jobs',
  version: '1.0.1',
  summary: 'Dead simple task scheduler. With support of cluster or multiple NodeJS instances.',
  git: 'https://github.com/VeliovGroup/Meteor-CRON-jobs',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2.1');
  api.use(['coffeescript', 'mongo', 'check', 'sha'], 'server');
  api.addFiles('cron-jobs.coffee', 'server');
  api.export('CRONjob');
});