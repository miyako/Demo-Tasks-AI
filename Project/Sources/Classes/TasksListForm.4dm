property tasks : cs.TasksSelection
property currentTask : cs.TasksEntity
property selectedTasks : Collection

Class constructor

// Load all tasks ordered by due date
This.tasks:=ds.Tasks.all().orderBy("DueDate asc")
This.currentTask:=Null
This.selectedTasks:=[]


Function refreshList($formEventCode : Integer)

Case of 
	: ($formEventCode=On Clicked)
		This.tasks:=ds.Tasks.all().orderBy("DueDate asc")
		This.currentTask:=Null
		This.selectedTasks:=[]
End case