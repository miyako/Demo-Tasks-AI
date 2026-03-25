property emails : cs.EmailsSelection
property currentEmail : cs.EmailsEntity
property selectedEmails : Collection
property isProcessing : Boolean

Class constructor

// Load all emails ordered by reception date (most recent first)
This.emails:=ds.Emails.all().orderBy("ReceptionDate desc")
This.currentEmail:=Null
This.selectedEmails:=[]
This.isProcessing:=False


Function processEmailWithAI($formEventCode : Integer)

Case of 
	: ($formEventCode=On Clicked)
		// Check if an email is selected
		If (This.currentEmail=Null)
			ALERT("Please select an email to process.")
			return 
		End if 
		
		// Check if already processed
		If (This.currentEmail.Status="Processed")
			ALERT("This email has already been processed.")
			return 
		End if 
		
		This.isProcessing:=True
		
		var $processor : cs.EmailAIProcessor
		var $result : Object
		
		$processor:=cs.EmailAIProcessor.new()
		$result:=$processor.analyzeAndCreateTask(This.currentEmail)
		
		This.isProcessing:=False
		
		If ($result.success)
			// Update email status
			This.currentEmail.Status:="Processed"
			This.currentEmail.save()
			
			// Refresh the list
			This.emails:=ds.Emails.all().orderBy("ReceptionDate desc")
			
			If ($result.taskCreated)
				ALERT("Task created successfully!\n\nSummary: "+String($result.task.Summary)+"\nDepartment: "+String($result.departmentName)+"\nAssignee: "+String($result.assigneeName))
			Else 
				ALERT("Email processed - no task needed.\n\nReason: "+String($result.reasoning))
			End if 
		Else 
			ALERT("Error processing email: "+String($result.error))
		End if 
End case


Function refreshList($formEventCode : Integer)

Case of 
	: ($formEventCode=On Clicked)
		This.emails:=ds.Emails.all().orderBy("ReceptionDate desc")
		This.currentEmail:=Null
		This.selectedEmails:=[]
End case
