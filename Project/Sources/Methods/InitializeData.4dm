//%attributes = {"invisible":true}

// InitializeData
// Two-phase import: 1) Import all entities (get IDs), 2) Set relations per table

var $departmentsJSON; $employeesJSON; $tasksJSON; $emailsJSON : Text
var $departments; $employees; $tasks; $emails : Collection
var $dept : cs.DepartmentsEntity
var $empEntity : cs.EmployeesEntity
var $emp : cs.EmployeesEntity
var $task : cs.TasksEntity
var $empData; $deptData; $taskData : Object

// Clear existing data
CONFIRM("This will delete all existing data and reload from JSON files. Continue?"; "Yes"; "No")
If (OK=1)
	// Delete existing records
	ds.Tasks.all().drop()
	ds.Emails.all().drop()
	ds.Employees.all().drop()
	ds.Departments.all().drop()
	
	// Load JSON files
	$departmentsJSON:=Folder(fk resources folder).file("departments.json").getText()
	$employeesJSON:=Folder(fk resources folder).file("employees.json").getText()
	$tasksJSON:=Folder(fk resources folder).file("tasks.json").getText()
	$emailsJSON:=Folder(fk resources folder).file("emails.json").getText()
	
	$departments:=JSON Parse($departmentsJSON)
	$employees:=JSON Parse($employeesJSON)
	$tasks:=JSON Parse($tasksJSON)
	$emails:=JSON Parse($emailsJSON)
	
	// ============================================
	// PHASE 1: Import all entities (get IDs generated)
	// ============================================
	Try
		ds.Departments.fromCollection($departments)
		ALERT("Imported "+String($departments.length)+" departments")
	Catch
		ALERT("Error importing departments: "+Last errors.first().message)
	End try
	
	Try
		ds.Employees.fromCollection($employees)
		ALERT("Imported "+String($employees.length)+" employees")
	Catch
		ALERT("Error importing employees: "+Last errors.first().message)
	End try
	
	Try
		ds.Tasks.fromCollection($tasks)
		ALERT("Imported "+String($tasks.length)+" tasks")
	Catch
		ALERT("Error importing tasks: "+Last errors.first().message)
	End try 
	
	Try
		ds.Emails.fromCollection($emails)
		ALERT("Imported "+String($emails.length)+" emails")
	Catch
		ALERT("Error importing emails: "+Last errors.first().message)
	End try 
	
	// ============================================
	// PHASE 2: Set relations for each table
	// ============================================
	
	// 2a. Set Employee → Department relations
	For each ($empData; $employees)
		If ($empData.departmentName#Null)
			// Find the employee entity
			$empEntity:=ds.Employees.query("Firstname = :1 AND Name = :2"; $empData.Firstname; $empData.Name).first()
			
			If ($empEntity#Null)
				// Find and set the department
				$dept:=ds.Departments.query("Name = :1"; $empData.departmentName).first()
				If ($dept#Null)
					$empEntity.Department:=$dept
					$empEntity.save()
				End if 
			End if 
		End if 
	End for each 
	
	ALERT("Linked employees to departments")
	
	// 2b. Set Department → Manager (Employee) relations
	For each ($deptData; $departments)
		
		// Find the department entity
		$dept:=ds.Departments.query("Name = :1"; $deptData.Name).first()
		
		If ($dept#Null)
			If ($deptData.managerFirstname#Null) && ($deptData.managerLastname#Null)
				// Find the employee
				$emp:=ds.Employees.query("Firstname = :1 AND Name = :2"; $deptData.managerFirstname; $deptData.managerLastname).first()
				
				If ($emp#Null)
					$dept.Manager:=$emp
					$dept.save()
				End if 
			End if 
		End if 
		
	End for each 
	
	// 2c. Set Task → Assignee (Employee) relations
	For each ($taskData; $tasks)
		If ($taskData.assigneeFirstname#Null) && ($taskData.assigneeLastname#Null)
			// Find the task entity
			$task:=ds.Tasks.query("Summary = :1"; $taskData.Summary).first()
			
			If ($task#Null)
				// Find the employee to set as assignee
				$emp:=ds.Employees.query("Firstname = :1 AND Name = :2"; \
					$taskData.assigneeFirstname; $taskData.assigneeLastname).first()
				
				If ($emp#Null)
					$task.Assignee:=$emp
					$task.save()
				End if 
			End if 
		End if 
	End for each 
	
	ALERT("Data initialization complete!\r\rDepartments: "+String(ds.Departments.all().length)+"\rEmployees: "+String(ds.Employees.all().length)+"\rTasks: "+String(ds.Tasks.all().length)+"\rEmails: "+String(ds.Emails.all().length))
	
End if 

