if(typeof ReactComponents!='undefined'){
	angular.module('learnginBoardApp').constant('onClick',null).constant('onChange', function (data) {
        alert.bind(null, "value passed" + data);
      }).constant('options', []);
	for(var comp in ReactComponents){
		ReactComponents[comp].component(angular.module('learnginBoardApp'));
	}
}