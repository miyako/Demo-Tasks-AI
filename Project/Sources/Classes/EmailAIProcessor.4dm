// EmailAIProcessor
// Processes emails using AI to analyze content and create tasks automatically
// Uses 4D AI Kit with OpenAI

property client : cs.AIKit.OpenAI

Class constructor
	
	// Initialize OpenAI client
	// Note: API key should be configured in settings or environment
	This.client:=cs.AIKit.OpenAI.new(cs.AppUtils.me._getKeyForProvider("OpenAI"))
	
	
Function analyzeAndCreateTask($email : cs.EmailsEntity)->$result : Object
	
	$result:=New object("success"; False)
	
	If ($email=Null)
		$result.error:="No email provided"
		return $result
	End if 
	
	// Build the context about departments and employees for the AI
	var $departmentsInfo : Text
	var $dept : cs.DepartmentsEntity
	
	$departmentsInfo:=""
	For each ($dept; ds.Departments.all())
		$departmentsInfo+="- "+$dept.Name
		If ($dept.Description#Null) && ($dept.Description#"")
			$departmentsInfo+=": "+$dept.Description
		End if 
		// Add employees in this department
		var $empNames : Text
		$empNames:=""
		var $emp : cs.EmployeesEntity
		For each ($emp; $dept.Employees)
			If ($empNames#"")
				$empNames+=", "
			End if 
			$empNames+=$emp.Firstname+" "+$emp.Name
		End for each 
		If ($empNames#"")
			$departmentsInfo+=" (Employees: "+$empNames+")"
		End if 
		$departmentsInfo+="\n"
	End for each 
	
	// Build the prompt
	var $systemPrompt : Text
	$systemPrompt:="You are an AI assistant for a travel agency. Your job is to analyze incoming emails and determine:\n"
	$systemPrompt+="1. If a task needs to be created based on the email content\n"
	$systemPrompt+="2. Which department should handle this task\n"
	$systemPrompt+="3. A summary and description for the task\n"
	$systemPrompt+="4. A suggested due date based on urgency (number of days from today)\n\n"
	$systemPrompt+="Available departments and their employees:\n"
	$systemPrompt+=$departmentsInfo+"\n"
	$systemPrompt+="IMPORTANT: You must respond with ONLY a valid JSON object (no markdown, no code blocks, no additional text).\n"
	$systemPrompt+="The JSON must have this exact structure:\n"
	$systemPrompt+="{\n"
	$systemPrompt+="  \"shouldCreateTask\": true or false,\n"
	$systemPrompt+="  \"departmentName\": \"exact department name from the list above\",\n"
	$systemPrompt+="  \"taskSummary\": \"brief task title\",\n"
	$systemPrompt+="  \"taskDescription\": \"detailed description of what needs to be done\",\n"
	$systemPrompt+="  \"daysUntilDue\": number between 1 and 30,\n"
	$systemPrompt+="  \"urgency\": \"low\", \"medium\", or \"high\",\n"
	$systemPrompt+="  \"reasoning\": \"brief explanation of your decision\"\n"
	$systemPrompt+="}\n\n"
	$systemPrompt+="If no task is needed (e.g., spam, newsletter, already handled), set shouldCreateTask to false."
	
	var $userPrompt : Text
	$userPrompt:="Please analyze this email and determine if a task should be created:\n\n"
	$userPrompt+="From: "+$email.Sender+"\n"
	$userPrompt+="Subject: "+$email.Subject+"\n"
	$userPrompt+="Date: "+String($email.ReceptionDate)+"\n"
	$userPrompt+="Body:\n"+$email.Body
	
	// Call the AI
	var $messages : Collection
	$messages:=New collection
	$messages.push(New object("role"; "system"; "content"; $systemPrompt))
	$messages.push(New object("role"; "user"; "content"; $userPrompt))
	
	var $chatResponse : Object
	Try
		$chatResponse:=This.client.chat.completions.create($messages; {model: "gpt-4o"})
	Catch
		$result.error:="AI API error: "+Last errors.first().message
		return $result
	End try
	
	If ($chatResponse.success=False)
		$result.error:="AI request failed: "+$chatResponse.errors.join("\r")
		return $result
	End if 
	
	// Parse the AI response
	var $aiResponse : Text
	$aiResponse:=$chatResponse.choice.message.content
	
	// Clean up the response - remove markdown code blocks if present
	If ($aiResponse="@```json*")
		$aiResponse:=Replace string($aiResponse; "```json"; "")
		$aiResponse:=Replace string($aiResponse; "```"; "")
	End if 
	$aiResponse:=Trim($aiResponse)
	
	var $parsed : Object
	Try
		$parsed:=JSON Parse($aiResponse)
	Catch
		$result.error:="Failed to parse AI response: "+$aiResponse
		return $result
	End try
	
	// Check if we should create a task
	If ($parsed.shouldCreateTask=False)
		$result.success:=True
		$result.taskCreated:=False
		$result.reasoning:=$parsed.reasoning
		return $result
	End if 
	
	// Find the department
	var $department : cs.DepartmentsEntity
	$department:=ds.Departments.query("Name = :1"; $parsed.departmentName).first()
	
	If ($department=Null)
		// Try partial match
		$department:=ds.Departments.query("Name = :1"; $parsed.departmentName+"@").first()
	End if 
	
	If ($department=Null)
		$result.error:="Department not found: "+$parsed.departmentName
		return $result
	End if 
	
	// Get an employee from this department to assign the task
	var $assignee : cs.EmployeesEntity
	$assignee:=$department.Employees.first()
	
	If ($assignee=Null)
		// Try the department manager
		$assignee:=$department.Manager
	End if 
	
	// Create the task
	var $task : cs.TasksEntity
	$task:=ds.Tasks.new()
	$task.Summary:=$parsed.taskSummary
	$task.Description:=$parsed.taskDescription
	$task.CreationDate:=Current date
	$task.DueDate:=Current date+$parsed.daysUntilDue
	$task.Status:="Open"
	$task.Email:=$email
	
	If ($assignee#Null)
		$task.Assignee:=$assignee
	End if 
	
	var $saveResult : Object
	$saveResult:=$task.save()
	
	If ($saveResult.success)
		$result.success:=True
		$result.taskCreated:=True
		$result.task:=$task
		$result.departmentName:=$department.Name
		$result.assigneeName:=Choose($assignee#Null; $assignee.Firstname+" "+$assignee.Name; "Unassigned")
		$result.reasoning:=$parsed.reasoning
		$result.urgency:=$parsed.urgency
	Else 
		$result.error:="Failed to save task: "+$saveResult.statusText
	End if 
	
	return $result
	