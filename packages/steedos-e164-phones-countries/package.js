Package.describe({
	name: 'steedos:e164-phones-countries',
	summary: 'Small lib that contains various information of a country',
	version: '1.0.3',
	git: 'https://github.com/geneh/e164-phones-countries.git'
});

Package.onUse(function(api) {
	api.versionsFrom('METEOR@1.3');

	api.use('blaze');
	api.use('templating');

	api.addFiles([
		'e164-phones-countries.js'
	]);
	api.addFiles([
		'phone-prefixes-ui.html',
		'phone-prefixes-ui.js'
	], 'client');

	api.export('E164');
});

Package.onTest(function(api) {

});