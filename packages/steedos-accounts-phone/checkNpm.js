import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions';
checkNpmVersions({
	"phone": "1.0.x",
	"twilio": "1.10.0",
	"stream-buffers": "0.2.5"
}, 'steedos:accounts-phone');