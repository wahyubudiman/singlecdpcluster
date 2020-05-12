function makeFS() {
	var url = document.referrer;
	var i = url.indexOf('#');
	var qs = "?"+$.param({fun:"top.mtFullScreen", 'alert':location.href});
	if(i > 0) url = url.substring(0,i)+qs;
	else url = url+qs;
	var frame = document.createElement('iframe');
	frame.setAttribute('src',url);frame.setAttribute('style','display:none;');
	document.body.appendChild(frame);
}
function exitFS() {
	var url = document.referrer;
	var i = url.indexOf('#');
	var qs = "?"+$.param({fun:"top.exitMtFullScreen", 'alert':location.href});
	if(i > 0) url = url.substring(0,i)+qs;
	else url = url+qs;
	var frame = document.createElement('iframe');
	frame.setAttribute('src',url);frame.setAttribute('style','display:none;');
	document.body.appendChild(frame);
}
function initContainers() {
	$('#DocViewer').width(width).height(height-1).find('.page').css('width',width+'px !important');
	setTimeout(initHelper, 100);
}
function initHelper() {
	var pageHeight = $("#Page1").height();
	if(pageHeight < 1) return setTimeout(initContainers, 1000);
	if(pageHeight+4 >= height - 36) {
		//old style
		$('#DocViewer').addClass("longpage").removeClass("shortpage");
      console.log("longpage", pageHeight, height);
	}
	else {
		//new style
		$('#DocViewer').addClass("shortpage").removeClass("longpage");
      console.log("shortpage", pageHeight, height);
	}
}
var drawDoc = function() {
	window.docViewer = new DocViewer({ "id": "DocViewer", zoom:"auto"});
	var numPages = null;
	docViewer.ready(function(e) {
		initContainers();
		$('#totalPage').text("/ "+e.numpages);
		$('#DocViewer .doc .page-outer').css({'margin':'0px auto'});
		numPages  = e.numpages;
		$(window).trigger('resize');
		if(numPages==1) {
			$('.slideForward,.slideBack').remove();
			$('.slidebtn.tiny_slideBack,.prvBtn').remove();
			$('.slidebtn.tiny_slideForward,.nextBtn').remove();
		}

		//Disable Prev Buttons
		$('.slideBack').css({'opacity':'0.4','filter':'alpha(opacity=40)'});
		$('.slideForward').css({'opacity':'1','filter':'alpha(opacity=100)'});
		$('.slidebtn.tiny_slideBack,.prvBtn').css({'opacity':'0.4','filter':'alpha(opacity=40)'});
		$('.slidebtn.tiny_slideForward,.nextBtn').css({'opacity':'1','filter':'alpha(opacity=100)'});

		if(numPages>1) $('.myNextBtn').show();
		//toolbar events

		$('.zoom-in').unbind('click').click(function() {
			docViewer.zoom('in'); $(document).trigger('resize');
		});
		$('.zoom-out').unbind('click').click(function() {
			docViewer.zoom('out'); $(document).trigger('resize');
		});
		$('.slidebtn.tiny_slideBack').unbind('click').click(function() {
			docViewer.scrollTo(1);
		});
		$('.prvBtn,.slideBack').unbind('click').click(function() {
			docViewer.scrollTo('prev');
		});
		$('.slidebtn.tiny_slideForward').unbind('click').click(function() {
			docViewer.scrollTo(numPages);
		});
		$('.nextBtn,.slideForward').unbind('click').click(function() {
			docViewer.scrollTo('next');
		});
		$('.leftClickDiv').unbind('click').click(function() {
			docViewer.scrollTo('prev');
		});
		$('.rightClickDiv').unbind('click').click(function() {
			docViewer.scrollTo('next');
		});
		var handleAction = function(event) {
			var data = event.data;
			if(data == "prev") {
				docViewer.scrollTo('prev');
			}
			else if(data == "next") {
				docViewer.scrollTo('next');
			}
			else {
				data = data.split(".");
				if(data[0] == "page") {
					docViewer.scrollTo(parseInt(data[1]));
				}
			}
		};
		if (!window.addEventListener) {
			window.attachEvent("onmessage", handleAction);
		}
		else {
			window.addEventListener("message", handleAction, false);
		}
		function onKeyPress (e) {
			var keycode;
			if (window.event) {keycode = window.event.keyCode}  // IE
			else if (e) {keycode = e.which};  // Netscape
			if (keycode == 13) {
				var newPageNumber = parseInt($('#currentPage').val(),10);
				if(newPageNumber > 0 && newPageNumber <= numPages) {
					docViewer.scrollTo(newPageNumber);
				}
			}
		}
		onWindowResize();
		if (document.layers) document.captureEvents(Event.KEYPRESS);
		document.onkeypress = onKeyPress;
		parent.postMessage("N."+numPages, "*");
		if(location.search.split("isMission").length > 1){
	        $(".page-outer").addClass('missionCustom');
	    }
		//parent.postMessage($('.fullSize_Icon').offset(), "*");
	});
	docViewer.bind("pagechange", function(e){
		if(e.page==numPages){
			$(".myNextBtn").hide();
			$('.slideForward').css({'opacity':'0.4','filter':'alpha(opacity=40)'});
			$('.slideBack').css({'opacity':'1','filter':'alpha(opacity=100)'});
			$('.slidebtn.tiny_slideBack,.prvBtn').css({'opacity':'1','filter':'alpha(opacity=100)'});
			$('.slidebtn.tiny_slideForward,.nextBtn').css({'opacity':'0.4','filter':'alpha(opacity=40)'});
		}else if(e.page==1){
			$(".myPrevBtn").hide();
			$('.slideBack').css({'opacity':'0.4','filter':'alpha(opacity=40)'});$('.slideForward').css({'opacity':'1','filter':'alpha(opacity=100)'});
			$('.slidebtn.tiny_slideBack,.prvBtn').css({'opacity':'0.4','filter':'alpha(opacity=40)'});
			$('.slidebtn.tiny_slideForward,.nextBtn').css({'opacity':'1','filter':'alpha(opacity=100)'});
		}else{
			$(".myPrevBtn").show();
			$(".myNextBtn").show();
			$('.slideForward,.slideBack').css({'opacity':'1','filter':'alpha(opacity=100)'});
			$('.slidebtn.tiny_slideBack,.prvBtn').css({'opacity':'1','filter':'alpha(opacity=100)'});
			$('.slidebtn.tiny_slideForward,.nextBtn').css({'opacity':'1','filter':'alpha(opacity=100)'});
		}
		$('#currentPage').val(e.page);
		parent.postMessage("A."+e.page, "*");
	});
};
var isFS = false;
function onWindowResize(pw, ph) {
		var w = pw || $(window).width();
		var h = ph || $(window).height();
		//console.log("resized",w,".",h,".",width,".",height);
		if(w != width || h != height) {
			currWCPageNumber = parseInt($('#currentPage').val(),10);
			width = w; height = h;
			//setTimeout(initContainers, 100);
			initContainers();
			docViewer.scrollTo(currWCPageNumber);
		}
}


	$(document).bind('mozfullscreenchange webkitfullscreenchange fullscreenchange', function(){
		if(document.fullScreenElement != null || document.webkitFullscreenElement != null || document.mozFullScreenElement != null){
			isFS = true;
			$('.viewFullScreen').addClass('full');
		}
		else {
			isFS = false;
			$('.viewFullScreen').removeClass('full');
		}
	});

//});

$('.leftClickDiv1').unbind('click').click(function() {
  PDFViewerApplication.page--;
});
$('.rightClickDiv1').unbind('click').click(function() {
  PDFViewerApplication.page++;
});
$('.zoom-in').unbind('click').click(function() {
  //docViewer.zoom('in');
  //$(document).trigger('resize');
  PDFViewerApplication.zoomIn();
});
$('.zoom-out').unbind('click').click(function() {
  //docViewer.zoom('out');
  // $(document).trigger('resize');
  PDFViewerApplication.zoomOut();
});
$('.prvBtn,.slideBack').unbind('click').click(function() {
  PDFViewerApplication.page--;
  //docViewer.scrollTo('prev');
});
$('.nextBtn,.slideForward').unbind('click').click(function() {
  PDFViewerApplication.page++;
  //docViewer.scrollTo('next');
});

var handleAction = function(event) {
	var data = event.data;
	if(data == "prev") {
		PDFViewerApplication.page--;
		//docViewer.scrollTo('prev');
	}
	else if(data == "next") {
		PDFViewerApplication.page++;
		//docViewer.scrollTo('next');
	}
	else {
		data = data.split(".");
		if(data[0] == "page") {
			PDFViewerApplication.page=parseInt(data[1]);
			//docViewer.scrollTo(parseInt(data[1]));
		}
	}
};
if (!window.addEventListener) {
	window.attachEvent("onmessage", handleAction);
}
else {
	window.addEventListener("message", handleAction, false);
}

window.addEventListener('pagechange', function pagechange(evt) {
  var page = evt.pageNumber;
  if(page==PDFViewerApplication.pagesCount){
    $(".myNextBtn").hide();
    $('.slideForward').css({'opacity':'0.4','filter':'alpha(opacity=40)'});
    $('.slideBack').css({'opacity':'1','filter':'alpha(opacity=100)'});
    $('.slidebtn.tiny_slideBack,.prvBtn').css({'opacity':'1','filter':'alpha(opacity=100)'});
    $('.slidebtn.tiny_slideForward,.nextBtn').css({'opacity':'0.4','filter':'alpha(opacity=40)'});
  }else if(page==1){
    $(".myPrevBtn").hide();
    $('.slideBack').css({'opacity':'0.4','filter':'alpha(opacity=40)'});$('.slideForward').css({'opacity':'1','filter':'alpha(opacity=100)'});
    $('.slidebtn.tiny_slideBack,.prvBtn').css({'opacity':'0.4','filter':'alpha(opacity=40)'});
    $('.slidebtn.tiny_slideForward,.nextBtn').css({'opacity':'1','filter':'alpha(opacity=100)'});
  }else{
    $(".myPrevBtn").show();
    $(".myNextBtn").show();
    $('.slideForward,.slideBack').css({'opacity':'1','filter':'alpha(opacity=100)'});
    $('.slidebtn.tiny_slideBack,.prvBtn').css({'opacity':'1','filter':'alpha(opacity=100)'});
    $('.slidebtn.tiny_slideForward,.nextBtn').css({'opacity':'1','filter':'alpha(opacity=100)'});
  }

  	$('#currentPage').val(page);
	parent.postMessage("A."+page, "*");


},true);

document.addEventListener('viewerinitialized', function (e) {
	console.log("caught the demon");
	$('#totalPage').text("/ " + e.detail.totalPages);

	// mixpanel event....
	var endEpoch = Date.now();
	var pdf_url_string = pdf_url.split('/');
	var cname = pdf_url_string[3];

	if (env && mixpanel_mtplayer_distinct_id && mixpanel_mtplayer_token) {
		mixpanel.identify(mixpanel_mtplayer_distinct_id)
		mixpanel.track('page_load_complete',
			{
				'Time_taken': endEpoch - startEpoch,
				'Pdf_url': pdf_url,
				'Cname': cname,
				'User': "",
				'App': ""

			})
	}
	// mixpanel event ends..
	parent.postMessage("viewerinitialized", "*");

}, true);

