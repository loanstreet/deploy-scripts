var page = require('webpage').create();
page.open('http://localhost:37568', function (status) {
	console.log("Status: " + status);
	if (status === "success") {
		console.log(page.content);
	}
	phantom.exit();
});