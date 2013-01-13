// adapted from http://stackoverflow.com/questions/950087/include-javascript-file-inside-javascript-file

var required = [];
function require(script) {
    if($.inArray(script, required) != -1) return;
    required.push(script);

    $.ajax({
        url: script,
        dataType: "script",
        async: false,           // <-- this is the key
        success: function () {
            // all good...
        },
        error: function () {
            throw new Error("Could not load script " + script);
        }
    });
}
