Class constructor
	// Welcome form - no data to load


Function openTasks($formEventCode : Integer)
	
	var $window : Integer
	
	Case of 
		: ($formEventCode=On Clicked)
			$window:=Open form window("TasksList"; Plain form window)
			DIALOG("TasksList"; *)
	End case 


Function openEmails($formEventCode : Integer)
	
	var $window : Integer
	
	Case of 
		: ($formEventCode=On Clicked)
			$window:=Open form window("EmailsList"; Plain form window)
			DIALOG("EmailsList"; *)
	End case 
