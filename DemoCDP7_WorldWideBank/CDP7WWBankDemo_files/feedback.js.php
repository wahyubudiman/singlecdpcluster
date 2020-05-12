var JSON;
if (!JSON) {
    JSON = {};
}
(function () {
    'use strict';
    function f(n) {
        // Format integers to have at least two digits.
        return n < 10 ? '0' + n : n;
    }
    if (typeof Date.prototype.toJSON !== 'function') {
        Date.prototype.toJSON = function (key) {
            return isFinite(this.valueOf())
                ? this.getUTCFullYear()     + '-' +
                    f(this.getUTCMonth() + 1) + '-' +
                    f(this.getUTCDate())      + 'T' +
                    f(this.getUTCHours())     + ':' +
                    f(this.getUTCMinutes())   + ':' +
                    f(this.getUTCSeconds())   + 'Z'
                : null;
        };
        String.prototype.toJSON      =
            Number.prototype.toJSON  =
            Boolean.prototype.toJSON = function (key) {
                return this.valueOf();
            };
    }
    var cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        gap,
        indent,
        meta = {    // table of character substitutions
            '\b': '\\b',
            '\t': '\\t',
            '\n': '\\n',
            '\f': '\\f',
            '\r': '\\r',
            '"' : '\\"',
            '\\': '\\\\'
        },
        rep;


    function quote(string) {
        escapable.lastIndex = 0;
        return escapable.test(string) ? '"' + string.replace(escapable, function (a) {
            var c = meta[a];
            return typeof c === 'string'
                ? c
                : '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
        }) + '"' : '"' + string + '"';
    }


    function str(key, holder) {
        var i,          // The loop counter.
            k,          // The member key.
            v,          // The member value.
            length,
            mind = gap,
            partial,
            value = holder[key];
        if (value && typeof value === 'object' &&
                typeof value.toJSON === 'function') {
            value = value.toJSON(key);
        }
        if (typeof rep === 'function') {
            value = rep.call(holder, key, value);
        }
        switch (typeof value) {
        case 'string':
            return quote(value);

        case 'number':
            return isFinite(value) ? String(value) : 'null';

        case 'boolean':
        case 'null':
            return String(value);
        case 'object':

// Due to a specification blunder in ECMAScript, typeof null is 'object',
// so watch out for that case.

            if (!value) {
                return 'null';
            }

// Make an array to hold the partial results of stringifying this object value.

            gap += indent;
            partial = [];

// Is the value an array?

            if (Object.prototype.toString.apply(value) === '[object Array]') {

// The value is an array. Stringify every element. Use null as a placeholder
// for non-JSON values.

                length = value.length;
                for (i = 0; i < length; i += 1) {
                    partial[i] = str(i, value) || 'null';
                }

// Join all of the elements together, separated with commas, and wrap them in
// brackets.

                v = partial.length === 0
                    ? '[]'
                    : gap
                    ? '[\n' + gap + partial.join(',\n' + gap) + '\n' + mind + ']'
                    : '[' + partial.join(',') + ']';
                gap = mind;
                return v;
            }

// If the replacer is an array, use it to select the members to be stringified.

            if (rep && typeof rep === 'object') {
                length = rep.length;
                for (i = 0; i < length; i += 1) {
                    if (typeof rep[i] === 'string') {
                        k = rep[i];
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            } else {

// Otherwise, iterate through all of the keys in the object.

                for (k in value) {
                    if (Object.prototype.hasOwnProperty.call(value, k)) {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            }

// Join all of the member texts together, separated with commas,
// and wrap them in braces.

            v = partial.length === 0
                ? '{}'
                : gap
                ? '{\n' + gap + partial.join(',\n' + gap) + '\n' + mind + '}'
                : '{' + partial.join(',') + '}';
            gap = mind;
            return v;
        }
    }

// If the JSON object does not yet have a stringify method, give it one.

    if (typeof JSON.stringify !== 'function') {
        JSON.stringify = function (value, replacer, space) {

// The stringify method takes a value and an optional replacer, and an optional
// space parameter, and returns a JSON text. The replacer can be a function
// that can replace values, or an array of strings that will select the keys.
// A default replacer method can be provided. Use of the space parameter can
// produce text that is more easily readable.

            var i;
            gap = '';
            indent = '';

// If the space parameter is a number, make an indent string containing that
// many spaces.

            if (typeof space === 'number') {
                for (i = 0; i < space; i += 1) {
                    indent += ' ';
                }

// If the space parameter is a string, it will be used as the indent string.

            } else if (typeof space === 'string') {
                indent = space;
            }

// If there is a replacer, it must be a function or an array.
// Otherwise, throw an error.

            rep = replacer;
            if (replacer && typeof replacer !== 'function' &&
                    (typeof replacer !== 'object' ||
                    typeof replacer.length !== 'number')) {
                throw new Error('JSON.stringify');
            }

// Make a fake root object containing our value under the key of ''.
// Return the result of stringifying the value.

            return str('', {'': value});
        };
    }


// If the JSON object does not yet have a parse method, give it one.

    if (typeof JSON.parse !== 'function') {
        JSON.parse = function (text, reviver) {

// The parse method takes a text and an optional reviver function, and returns
// a JavaScript value if the text is a valid JSON text.

            var j;

            function walk(holder, key) {

// The walk method is used to recursively walk the resulting structure so
// that modifications can be made.

                var k, v, value = holder[key];
                if (value && typeof value === 'object') {
                    for (k in value) {
                        if (Object.prototype.hasOwnProperty.call(value, k)) {
                            v = walk(value, k);
                            if (v !== undefined) {
                                value[k] = v;
                            } else {
                                delete value[k];
                            }
                        }
                    }
                }
                return reviver.call(holder, key, value);
            }


// Parsing happens in four stages. In the first stage, we replace certain
// Unicode characters with escape sequences. JavaScript handles many characters
// incorrectly, either silently deleting them, or treating them as line endings.

            text = String(text);
            cx.lastIndex = 0;
            if (cx.test(text)) {
                text = text.replace(cx, function (a) {
                    return '\\u' +
                        ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
                });
            }
            if (/^[\],:{}\s]*$/
                    .test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@')
                        .replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']')
                        .replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                j = eval('(' + text + ')');
                return typeof reviver === 'function'
                    ? walk({'': j}, '')
                    : j;
            }

// If the text is not JSON parseable, then a SyntaxError is thrown.

            throw new SyntaxError('JSON.parse');
        };
    }
}());


if(true || self == top) {//top level window
	var frame_src = null;
	var FeedParams = new Object();
	FeedParams.msg = "";
	FeedParams.game = "";
	FeedParams.sender = "";
	FeedParams.errors = [];
	FeedParams.load_time = new Date().toLocaleString();
	FeedParams.numAutoSentMails = 0;
	FeedParams.loaded = [];
	if(typeof captureErrors === "function") captureErrors(FeedParams.errors);
	else window.onerror = function(err,url,line){
		FeedParams.errors.push({"err":err,"url":url,"line":line});
	}
	setInterval(function(){//auto send max 3 emails for errors
	if(FeedParams.errors.length > 0 && FeedParams.numAutoSentMails < 3) {
		for(var i=0;i<FeedParams.errors.length;i++) {
			if(FeedParams.errors[i].err.indexOf("socket.io.js") > 0) continue;
			FeedParams.numAutoSentMails++;
			/*send_feedback("Script mail due to error in js.","Script","script-user");*/
			break;
		}
	}
	},300000);
/*	if(typeof jQuery === 'function') {
		var dLoaded = function(){
			FeedParams.loaded.push(this.nodeName+',src='+jQuery(this).attr('src')+" ,href="+jQuery(this).attr('href'));
		};
		setInterval(function(){
			jQuery('img,script,iframe,link').unbind('load',dLoaded).load(dLoaded);
		},250);
		jQuery('img,script,iframe,link').load(dLoaded);
	}*/
function handleEvent(e) {
	if(frame_src == null) {
		return;
	}
	try {
		var data = JSON.parse(e.data);
	} catch(err) {var data = {src:""};console.log(err,e);}
	if(typeof data.idx == 'undefined') return;
	frame_src[data.idx] = data.src.replace("/script", "/scriptt");
	//console.log('got child data', frame_src);
}
if(window.addEventListener) window.addEventListener("message", handleEvent, false);
else if(window.attachEvent) window.attachEvent("onmessage", handleEvent);
function send_feedback(msg, game, user, xtra_data, showConfirmation) {
	if(user == undefined) user = "";
	FeedParams.msg = msg;
	FeedParams.game = game;
	FeedParams.sender = user;
	FeedParams.showConfirm = true;
	if(typeof xtra_data == 'undefined') xtra_data = "{none}";
	FeedParams.xtra = xtra_data;
	if(showConfirmation === false || showConfirmation === 0) FeedParams.showConfirm = false;

	frame_src = new Array();
	var frames = document.getElementsByTagName('iframe');
	for(var idx=0;idx<window.frames.length;idx++) {
		if(jQuery.isFunction(window.frames[idx].postMessage)) window.frames[idx].postMessage(JSON.stringify({idx:idx, msg:"getSrc"}), "*");
	}
	setTimeout(function(){send_feedback_helper(FeedParams.msg, FeedParams.game, FeedParams.sender, FeedParams.xtra);}, 100);
	//console.log("sent msg to iframes to get src");
}
function send_feedback_helper(msg, game, user, xtra) {
	jQuery('#saveFeedback').remove();
	var browser_info = "<br><b>browser: </b>";
	//jQuery.each(jQuery.browser, function(i, val) {
   //   browser_info += i+":"+val+",";
	//});
	browser_info += navigator.userAgent;
	   browser_info += "<br><b>FlashPlayer:</b>";
	   if(swfobject) browser_info += JSON.stringify(swfobject.getFlashPlayerVersion());
	   else browser_info += "No flash player installed or flash blcoked";
	browser_info += "<br><b>Page url:</b>"+location.href+"<br><b>visible window size:</b>"+jQuery(window).width()+"x"+jQuery(window).height()
		+"<br><b>screen resolution:</b>"+screen.width+"x"+screen.height;
	browser_info += "<br><b>Game Load Time:</b>"+FeedParams.load_time+"<br><b>Feedback report time:</b>"+(new Date().toLocaleString());
	browser_info += "<br><br><b>user agent: </b>"+navigator.userAgent;
	if(typeof xtra !== 'undefined') browser_info += xtra;
	var jsErrors = "<br><br><b>Javascript Errors:</b>"+JSON.stringify(FeedParams.errors)
	jsErrors += "<br><br>Load calls:"+FeedParams.loaded.join("<br>");
	FeedParams.loaded = [];
	FeedParams.errors = [];
	var script = "var loaded_frames = 0;"+
							"function childLoaded(e) {"+
							"	if(e.data != 'ready') return;"+
							"	loaded_frames++;"+
							"	if(loaded_frames >= window.frames.length) AllFramesLoaded();"+
							"}"+
							"if(window.addEventListener) window.addEventListener('message', childLoaded, false);"+
							"else if(window.attachEvent) window.attachEvent('onmessage', childLoaded);"+
							"function AllFramesLoaded() {"+
								"for(var i=0;i<window.frames.length;i++) {"+
									"window.frames[i].postMessage(JSON.stringify({type:'setSrc', src:iframe_src[i]}), '*');"+
								"}"+
							"}"+
							"alert("+JSON.stringify(browser_info+jsErrors)+");";
	for(var idx=window.frames.length - 1;idx>=0;idx--) {
		script = "iframe_src[" + idx + "] = " + JSON.stringify(frame_src[idx]) + ";"+script;
	}
	frame_src = null;
	script = "var iframe_src = new Array();"+script;
	var src = jQuery('html').eq(0).html();
/*	jQuery('script', src).remove();
	jQuery('[href]', src).each(function() {
		jQuery(this).attr("href", toAbs(this.href));
	});
	jQuery('[src]', src).each(function() {
		jQuery(this).attr("src", toAbs(this.src));
	});
	jQuery('frame,iframe', src).each(function() {
		//this.src = "/feedback/iframe.html";
	});
	//jQuery('head', src).append(script);
	jQuery('style', src).each(function() {
		jQuery(this).html('');
	});*/
	var style = "";
	jQuery('style').each(function() {
		style += jQuery(this).html();
	});
	if(user == undefined) user = '';
	jQuery('body').append("<iframe id='saveFeedback' name='saveFeedback' style='display:none;'></iframe>");
	var feedback_form = jQuery('<form action="//feedback.mindtickle.com/feedback.js.php" method="POST" target="saveFeedback"></form>')
		.append('<input type="hidden" name="user" value="'+user+'">');
	var ip_src = jQuery('<input type="hidden" name="main">').val(src);
	var ip_script = jQuery('<input type="hidden" name="script">').val(script);
	var ip_style = jQuery('<input type="hidden" name="style">').val(style);
	var ip_msg = jQuery('<input type="hidden" name="msg">').val(msg);
	var ip_game = jQuery('<input type="hidden" name="game">').val(game);
	var ip_url = jQuery('<input type="hidden" name="url">').val(location.href);
	var log_msg = jQuery('<input type="hidden" name="log_msg">').val(browser_info+jsErrors);
	var ip_confirm = jQuery('<input type="hidden" name="showConfirm">').val(FeedParams.showConfirm);
	if(typeof MSG_SUPPORT_THANKS == "undefined") MSG_SUPPORT_THANKS = "Thanks for contacting us. We will get back to you shortly.";
	var ip_thanks = jQuery('<input type="hidden" name="thanks">').val(MSG_SUPPORT_THANKS);
	feedback_form.append(ip_src).append(ip_script).append(ip_msg).append(ip_game).append(ip_style).append(log_msg).append(ip_url).append(ip_confirm).append(ip_thanks);
	jQuery('body').append(feedback_form);
	feedback_form.submit();
	feedback_form.remove();
}
}
else {//inside iframe
function getSrc() {
	var html = jQuery('html').clone();
	jQuery('script', html).remove();
	return html.html();
}
function handleEventIframe(e) {
//	alert("received Event! sending back source.");
	//console.log('received event! sending back source', e);
	try {
		var data = JSON.parse(e.data);
	} catch(err) {var data = {idx:0};console.log(err,e);}
	e.source.postMessage(JSON.stringify({idx:data.idx, src:getSrc()}), "*");
}
if(window.addEventListener) window.addEventListener("message", handleEventIframe, false);
else if(window.attachEvent) window.attachEvent("onmessage", handleEventIframe);
}

//IE7: converts relative links to absolute. source http://www.phpied.com/relative-to-absolute-links-with-javascript/
function toAbs(link) {
  if(link == null) link = 'null';
  var lparts = link.split('/');
  if (/http:|https:|ftp:/.test(lparts[0])) {
    // already abs, return
    return link;
	}
	var host = self.location.href;
  var i, hparts = host.split('/');
  if (hparts.length > 3) {
    hparts.pop(); // strip trailing thingie, either scriptname or blank 
  }
  if (lparts[0] === '') { // like "/here/dude.png"
    host = hparts[0] + '//' + hparts[2];
    hparts = host.split('/'); // re-split host parts from scheme and domain only
    delete lparts[0];
  }
  for(i = 0; i < lparts.length; i++) {
    if (lparts[i] === '..') {
      // remove the previous dir level, if exists
      if (typeof lparts[i - 1] !== 'undefined') {
        delete lparts[i - 1];
      } else if (hparts.length > 3) { // at least leave scheme and domain
        hparts.pop(); // stip one dir off the host for each /../
      }
      delete lparts[i];
    }
    if(lparts[i] === '.') {
      delete lparts[i];
    }
  }
  // remove deleted
  var newlinkparts = [];
  for (i = 0; i < lparts.length; i++) {
    if (typeof lparts[i] !== 'undefined') {
      newlinkparts[newlinkparts.length] = lparts[i];
    }
  }
  return hparts.join('/') + '/' + newlinkparts.join('/');
}
if(typeof console === "undefined" || typeof console.log === "undefined") {
	window.mtlog = "";
	window.console = {
		log	:	function(a) {window.mtlog += a;},
		debug	:	function(a) {window.mtlog += a;},
		info	:	function(a) {window.mtlog += a;},
		error	:	function(a) {window.mtlog += a;}
	};
}
function mtReload() {
	location.href = location.protocol+"//"+location.host+location.port+location.pathname;
}
