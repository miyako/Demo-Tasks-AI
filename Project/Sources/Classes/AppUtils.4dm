// Class: AppUtils
// Description: Shared utility class for settings I/O and localization helpers.
//   Used by formPrimeMatch and formAIConfig to avoid code duplication.
//   All functions are shared — call via cs.AppUtils.me() singleton or cs.AppUtils.new().

property _settingsCache : Object

//MARK: - Singleton accessor

shared singleton Class constructor()
	
Function _secretsFolder() : 4D.Folder
	
	return Folder("/PACKAGE/Secrets")
	
Function _setKeyForProvider($provider : Text; $apiKey : Text)
	
	var $file : 4D.File
	$file:=This._secretsFolder().file($provider+".token")
	If ($file.exists) && ($file.getText()#$apiKey)
		$file.setText($apiKey)
	End if 
	
Function _getKeyForProvider($provider : Text) : Text
	
	var $file : 4D.File
	$file:=This._secretsFolder().file($provider+".token")
	return $file.exists ? $file.getText() : ""