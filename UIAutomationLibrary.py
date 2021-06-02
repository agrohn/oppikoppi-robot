#  This file is part of oppikoppi.
#  Copyright (C) 2021 Anssi Gröhn
#  
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

from uiautomation import uiautomation
import subprocess
import time

#uiautomation.SetGlobalSearchTimeout(125)
window = 0
queryChangeWindow = 0
publishWindow = 0

def wait_for_active_window(windowName, timeOut=20):
	global window
	window = uiautomation.WindowControl(searchDepth=10, Name=windowName)
	if window.Exists(timeOut):
		return True
	else:
		raise Exception("Could not find window %s" %windowName)


def set_template_parameters(courseid,server):
	global window
	window.SetActive()
	window.Maximize()

	# Open edit parameters via shortcut keys
	queryEditButton=window.MenuItemControl(Name="Transform data")
	# Split button has dropdown menu as next
	queryEditButton.Click()
	time.sleep(0.5)
	# redundancy to edit parameters
	menuItem=window.MenuItemControl(Name="Edit parameters")
	if not menuItem.Exists():
		queryEditButton.Click()
		time.sleep(0.5)
		menuitem.Refind()
	
	menuItem.Click()
	time.sleep(0.5)


	
	paramWindow=window.WindowControl(Name="Edit Parameters")
	# in case parameter input window does not exist, click might not have gone through, so retry
	if not paramWindow.Exists():
		menuItem.Click()
	paramWindow.Refind()
	# type course id
	paramWindow.EditControl(Name="courseid").SetFocus()
	time.sleep(0.5)
	# twice, since first might get lost
	paramWindow.SendKeys('{Ctrl}a')
	time.sleep(0.5)
	paramWindow.SendKeys('{Ctrl}a')
	time.sleep(0.5)
	paramWindow.SendKeys(courseid)
	# type server ip/domain name
	paramWindow.EditControl(Name="server").SetFocus()
	time.sleep(0.5)
	# twice, since first might get lost
	paramWindow.SendKeys('{Ctrl}a')
	time.sleep(0.5)
	paramWindow.SendKeys('{Ctrl}a')
	time.sleep(0.5)
	paramWindow.SendKeys(server)
	
	paramWindow.SendKeys('{TAB}s{Enter}')

	window.ButtonControl(Name="Apply changes").Click()

# setting course parameter on report server version of power bi desktop
def set_course_parameter_rs(courseid):
	global window
	window.SetActive()
	window.Maximize()

	# Open edit parameters via shortcut keys
	queryEditButton=window.SplitButtonControl(Name="Edit Queries")
	# Split button has dropdown menu as next
	queryEditButton=queryEditButton.GetNextSiblingControl()
	queryEditButton.Click()
	time.sleep(0.5)
	menuItem=window.MenuItemControl(Name="Edit Parameters")
	menuItem.Click()
	time.sleep(0.5)


	paramWindow=window.WindowControl(Name="Enter Parameters")
	# in case parameter input window does not exist, click might not have gone through, so retry
	if not paramWindow.Exists():
		menuItem.Click()
	paramWindow.Refind()

	paramWindow.EditControl(Name="courseid").SetFocus()
	time.sleep(0.5)
	paramWindow.SendKeys('{Ctrl}a')
	paramWindow.SendKeys(courseid)
	paramWindow.SendKeys('{TAB}{Enter}')

	window.ButtonControl(Name="Apply changes").Click()

def wait_until_query_changes_appears():
	global window
	global queryChangeWindow
	window.SetActive()
	window.Maximize()

	text=window.TextControl(Name="Apply query changes")	
	while 	not text.Exists():
		try:
			text.Refind()
		except:
			pass

	
def get_applying_query_changes_state():
		global window
		global queryChangeWindow
		window.SetActive()
		window.Maximize()

		text=window.TextControl(Name="Apply query changes")
		if	text.Exists():
			try:
				queryChangeWindow=text.GetParentControl().GetParentControl().GetParentControl()
				cancelButton=queryChangeWindow.ButtonControl(Name="Cancel")
				if	cancelButton.Exists():
					return "Processing"
				elif queryChangeWindow.ButtonControl(Name="Close").Exists():
					return   "Failed"
				else:
					return	"Done"
			except:
				return	"Done"
		else:
				return	"Done"
		

def click_query_change_close():
	global window
	global queryChangeWindow
	window.SetActive()
	window.Maximize()

	text=window.TextControl(Name="Apply query changes")
	if	text.Exists():
		btnCtrl = queryChangeWindow.ButtonControl(Name="Close")
		if btnCtrl.Exists():
			btnCtrl.Click()

def close_powerbi_dont_save():
	global window
	window.SetActive()
	window.Maximize()

	window.SendKeys('{LALT}fx')
	window.TextControl(Name="Don't save").Click()

def send_close_shortcut():
	global window
	window.SetActive()
	window.Maximize()

	window.SendKeys('{LALT}fx')

def save_report_rs():
	global window

	window.SetActive()
	window.Maximize()

	window.ButtonControl(Name="File tab").Click()
	saveMenuItem=window.MenuItemControl(Name="Save")
	if saveMenuItem.Exists():
		saveMenuItem.Click()
		wait_for_working_on_it()

def save_report():
	global window

	window.SetActive()
	window.Maximize()

	window.TextControl(Name="File").Click()
	saveMenuItem=window.ListItemControl(Name="Save")
	if saveMenuItem.Exists():
		saveMenuItem.Click()
		wait_for_working_on_it()

def wait_for_working_on_it():
	global window
	window.SetActive()
	window.Maximize()

	try:
		savingDialog = window.TextControl(Name="Working on it")	
		while savingDialog.Exists():
			time.sleep(1)
	except:
		pass

def click_publish()	:
	global window
	window.SetActive()
	window.Maximize()
	btnCtrl=window.ButtonControl(Name="Publish")
	
	if btnCtrl.Exists():

		btnCtrl.Click()
	else:
		raise Exception("Could not find Publish button")

# Click publish button on report server version of power bi desktop
def click_publish_rs():
	global window
	window.SetActive()
	window.Maximize()

	window.TextControl(Name="File").Click()
	window.ListItemControl(Name="Save as").Click()
	publishButton=window.TextControl(Name="Power BI Report Server")

	if publishButton.Exists():
		publishButton.Click()
	else:
		raise Exception("Could not find Publish button")

def apply_changes():
	global window
	window.SetActive()
	window.Maximize()

	applyPane = window.PaneControl(Name="Microsoft Power BI Desktop")
	if applyPane.Exists():
		btnCtrl=applyPane.ButtonControl(Name="Apply")
		if btnCtrl.Exists():
			btnCtrl.Click()
		else:
			raise Exception("There is not Apply Button")
	else:
		raise Exception("There is not Apply Pane")

def publish_visualization_to_powerbi_service(workspaceName):
	global window
	global publishWindow
	window.SetActive()
	window.Maximize()

	click_publish()

	publishWindow=window.PaneControl(Name="Publish to Power BI")
	workspace=publishWindow.TextControl(Name=workspaceName)
	if workspace.Exists():
		workspace.Click()
		publishWindow.ButtonControl(Name="Select").Click()
	else:
		# Sometimes clicks do not seem to get through on first attempt, so let's try again
		click_publish()
		workspace.Refind()
		if workspace.Exists():
			workspace.Click()
			publishWindow.ButtonControl(Name="Select").Click()
		else:
			raise Exception("Could not find publishing workspace %s (tried twice, you know)" %workspaceName)

# power bi desktop report server version
def publish_visualization_to_powerbi_service_rs(serverUrl):
	global window
	global publishWindow
	window.SetActive()
	window.Maximize()
	
	click_publish_rs()
	
	serverSelectWindow=window.PaneControl(Name="Power BI Report Server Selection")
	serverAddressField=serverSelectWindow.EditControl()

	
	if serverAddressField.Exists():
		
		
		# select proper server 
		serverAddressField.SendKeys('{Ctrl}a')
		serverAddressField.SendKeys(serverUrl)
		
		serverSelectWindow.ButtonControl(Name="OK").Click()
		time.sleep(0.5)
		

		# navigate to correct directory 
		publishTopWindow=window.WindowControl(Name="Save report")
		publishWindow=publishTopWindow.PaneControl(Name="Save report")
		
		if publishWindow.Exists():
			
			publishWindow.GroupControl(Name="Oppimisanalytiikka").DoubleClick()
			publishWindow.ButtonControl(Name="OK").Click()
		else:
			raise Exception("could not find save report window")

	

def get_publishing_state():
	global window
	if not window.Exists():
		raise Exception("We should have a window.")
	window.SetActive()
	window.Maximize()
	print("Here we start again")
	# This might just disappear entirely from time to time, so catch exception and ignore.
	# Handle data overwrites on normal Power BI Desktop 
	try:
		replaceWindow=window.WindowControl(Name="Replacing dataset")
		# We overwrite existing datasets without mercy
		if replaceWindow.Exists():
			replaceButton = replaceWindow.ButtonControl(Name="Replace")
			if replaceButton.Exists():
				replaceButton.Click()
	except:
		pass
	
	print("Continuing here")
	publishingWindow=window.WindowControl(Name='Publishing to Power BI')
	if publishingWindow.Exists():
		print("Publishing window ok")
		if publishingWindow.TextControl(Name="Cancel").Exists():
			return 	"Processing"
		elif publishingWindow.ButtonControl(Name="Got it").Exists():
			return	"Done"
	else:
		print("No publishing window")
		if window.IsMinimize:
			window.Maximize()
			publishingWindow.Refind()
			if publishingWindow.Exists():
				if publishingWindow.TextControl(Name="Cancel").Exists():
					return 	"Processing"
				elif publishingWindow.ButtonControl(Name="Got it").Exists():
					return	"Done"
			else:
				raise Exception("Publish window should be active")
		else:
			raise Exception("Power BI window is missing even after attempt to maximize, cannot continue.")


def get_publishing_state_rs():
	global window
	if not window.Exists():
		raise Exception("We should have a window.")
	window.SetActive()
	window.Maximize()	

	# Handle data overwrites on Power Bi Desktop for Report Server
	try:
		replaceWindow=window.WindowControl(Name="Confirm overwrite")
		# We overwrite existing datasets without mercy
		if replaceWindow.Exists():
			replaceButton = replaceWindow.ButtonControl(Name="Yes")
			if replaceButton.Exists():
				replaceButton.Click()
	except:
		pass


	publishingWindow=window.PaneControl(Name="Saving to Power BI Report Server")
	
	if publishingWindow.Exists():
		print("Publishing window ok")
		
		# Statement order here is crucial, cancel exists (although disabled) also after completion.
		if publishingWindow.ButtonControl(Name="Close").Exists():
			successMsg=publishingWindow.TextControl(Name="Success!")
			if successMsg.Exists():
				return "Done"
			return	"Failed"
		elif publishingWindow.TextControl(Name="Cancel").Exists():
			return 	"Processing"
		
	else:
		
		print("No publishing window")
		if window.IsMinimize:
			window.Maximize()
			publishingWindow.Refind()
			if publishingWindow.Exists():
				# Statement order here is crucial, cancel exists (although disabled) also after completion.
				if publishingWindow.ButtonControl(Name="Close").Exists():
					successMsg=publishingWindow.TextControl(Name="Success!")
					if successMsg.Exists():
						return "Done"
					return	"Failed"
				elif publishingWindow.TextControl(Name="Cancel").Exists():
					return 	"Processing"				
			else:
				raise Exception("Publish window should be active")
		else:
			raise Exception("Power BI window is missing even after attempt to maximize, cannot continue.")


def close_publishing():
	global window
	window.SetActive()
	window.Maximize()

	publishingWindow=window.WindowControl(Name="Publishing to Power BI")
	if publishingWindow.Exists():
		btnGotIt=publishingWindow.ButtonControl(Name="Got it")
		if btnGotIt.Exists():
			btnGotIt.Click()
	# in case we have  report server version
	publishingWindow=window.WindowControl(Name="Saving to Power BI Report Server")
	if publishingWindow.Exists():
		btnGotIt=publishingWindow.ButtonControl(Name="Close")
		if btnGotIt.Exists():
			btnGotIt.Click()


