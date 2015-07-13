//
//  AppDelegate.swift
//  CharSheet-Swift
//
//  Created by Patrick Wallace on 31/10/2014.
//  Copyright (c) 2014 Patrick Wallace. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder
{
	var window: UIWindow?

	var masterViewController: MasterViewController!

	// MARK: Core Data stack

	/// The directory the application uses to store the Core Data store file.
	///
	/// This code uses a directory named "Patrick-Wallace.CharSheet"
	/// in the application's documents Application Support directory.
	lazy var applicationDocumentsDirectory: NSURL = {
		let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		return urls[urls.count-1] as! NSURL
		}()

	/// The managed object model for the application.
	///
	/// This property is not optional. It is a fatal error for the application not to be able to find and load its model.
	lazy var managedObjectModel: NSManagedObjectModel = {
		let modelURL = NSBundle.mainBundle().URLForResource("CharSheet", withExtension: "momd")!
		return NSManagedObjectModel(contentsOfURL: modelURL)!
		}()

	/// The persistent store coordinator for the application.
	///
	/// This implementation creates and return a coordinator, having added the store for the application to it.
	///
	/// This property is optional since there are error conditions that could cause the creation of the store to fail.
	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {

		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CharSheet.sqlite")
		var error: NSError?
		// A userInfo dictionary which can be passed to addPersistentStoreWithType:configuration:url:options:error to request that Core Data automatically migrate the application to the latest version if necessary.
		let userInfo = [
			NSMigratePersistentStoresAutomaticallyOption: true,
			NSInferMappingModelAutomaticallyOption      : true]
		if let persistentStore = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: userInfo, error: &error) {
			return coordinator
		}

		// Report any error we got.
		let dict: [NSObject: AnyObject!] = [
			NSLocalizedDescriptionKey       : "Failed to initialize the application's saved data",
			NSLocalizedFailureReasonErrorKey: "There was an error creating or loading the application's saved data.",
			NSUnderlyingErrorKey            : error]
		let err = NSError(domain: "CharSheet CoreData", code: 9999, userInfo: dict)
		// Replace this with code to handle the error appropriately.
		// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
		NSLog("Unresolved error \(err), \(err.userInfo)")
		abort()
		}()

	/// Returns the managed object context for the application
	///
	/// This is already bound to the persistent store coordinator for the application.
	///
	/// This property is optional since there are error conditions that could
	/// cause the creation of the context to fail.
	lazy var managedObjectContext: NSManagedObjectContext? = {
		let coordinator = self.persistentStoreCoordinator
		if coordinator == nil {
			return nil
		}
		var managedObjectContext = NSManagedObjectContext()
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
		}()



	// MARK: Core Data Saving support

	/// Save all changes to the current Managed Object Context.
	/// Can be called frequently; it does nothing if nothing has changed.
	func saveContext ()
	{
		if let moc = self.managedObjectContext {
			var error: NSError? = nil
			if moc.hasChanges && !moc.save(&error) {
				// Replace this implementation with code to handle the error appropriately.
				NSLog("Unresolved error \(error), \(error!.userInfo)")
				abort()
			}
		}
	}

	// MARK: Private methods

	/// Get the objects the storyboard has created, and connect them together.
	private func wireUpMasterAndDetailViews()
	{
		let splitViewController = window!.rootViewController as! UISplitViewController
		let detailNavigationController = splitViewController.viewControllers[1] as! UINavigationController

		let charSheetUseViewController = detailNavigationController.viewControllers[0] as! CharSheetUseViewController
		splitViewController.delegate = charSheetUseViewController

		charSheetUseViewController.saveAllData = { self.saveContext() }

		let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
		masterViewController = masterNavigationController.viewControllers[0] as! MasterViewController
		masterViewController.managedObjectContext = managedObjectContext!
	}
}



// MARK: - Application Delegate

extension AppDelegate: UIApplicationDelegate
{
	func application(application                   : UIApplication,
		didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
	{
		wireUpMasterAndDetailViews()
		// If we have been given a URL, make sure we can access it. Return false to abort program startup if the URL is invalid.
		if let options = launchOptions {
			let launchURL = options[UIApplicationLaunchOptionsURLKey] as! NSURL
			if !launchURL.fileURL {
				return false
			}
		}
		return true
	}

	func applicationDidEnterBackground(application: UIApplication)
	{
		saveContext()
		NSUserDefaults.standardUserDefaults().synchronize()
	}

	func applicationWillTerminate(application: UIApplication)
	{
		saveContext()
		NSUserDefaults.standardUserDefaults().synchronize()
	}

	func application(application: UIApplication,
		openURL      url        : NSURL,
		sourceApplication       : String?,
		annotation              : AnyObject?) -> Bool
	{
		// Triggered when the user opens a .charSheet attachment in an email.
		// Import the data from the URL.
		if url.fileURL {
			let result = masterViewController.importURL(url)
			if !result.success {
				masterViewController.showAlertForResult(result, title: "Error importing character sheet.")
			}
			return result.success
		}
		return false // Not a URL type we support.
	}
}
