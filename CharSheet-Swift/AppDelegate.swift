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

	override init()
	{
		super.init()
		NotificationCenter.default.addObserver(self,
		                                                 selector: #selector(AppDelegate.saveChanges),
		                                                 name: NSNotification.Name(rawValue: "SaveChanges"),
		                                                 object: nil)
	}

	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: Core Data stack

	/// The directory the application uses to store the Core Data store file.
	///
	/// This code uses a directory named "Patrick-Wallace.CharSheet"
	/// in the application's documents Application Support directory.
	lazy var applicationDocumentsDirectory: URL = {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return urls[urls.count - 1]
		}()

	/// The managed object model for the application.
	///
	/// This property is not optional. It is a fatal error for the application not to be able to find and load its model.
	lazy var managedObjectModel: NSManagedObjectModel = {
		let modelURL = Bundle.main.url(forResource: "CharSheet", withExtension: "momd")!
		return NSManagedObjectModel(contentsOf: modelURL)!
		}()

	/// The persistent store coordinator for the application.
	///
	/// This implementation creates and return a coordinator, having added the store for the application to it.
	///
	/// This property is optional since there are error conditions that could cause the creation of the store to fail.
	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {

		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let url = self.applicationDocumentsDirectory.appendingPathComponent("CharSheet.sqlite")
		// A userInfo dictionary which can be passed to addPersistentStoreWithType:configuration:url:options:error to request that Core Data automatically migrate the application to the latest version if necessary.
		let userInfo = [
			NSMigratePersistentStoresAutomaticallyOption: true,
			NSInferMappingModelAutomaticallyOption      : true]
		do {
			let persistentStore = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: userInfo)
			return coordinator
		} catch var error as NSError {
			// Report any error we got.
			let dict: [String : AnyObject] = [
				NSLocalizedDescriptionKey        : "Failed to initialize the application's saved data" as AnyObject,
				NSLocalizedFailureReasonErrorKey : "There was an error creating or loading the application's saved data." as AnyObject,
				NSUnderlyingErrorKey             : error]
			let err = NSError(domain: "CharSheet CoreData", code: 9999, userInfo: dict)
			// Replace this with code to handle the error appropriately.
			NSLog("Unresolved error \(err), \(err.userInfo)")
			abort()
		} catch {
			fatalError()
		}

	}()

	/// Returns the managed object context for the application
	///
	/// This is already bound to the persistent store coordinator for the application.
	///
	/// This property is optional since there are error conditions that could
	/// cause the creation of the context to fail.
	lazy var managedObjectContext: NSManagedObjectContext? = {
		guard let coordinator = self.persistentStoreCoordinator else {
			return nil
		}
		let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
		}()



	// MARK: Core Data Saving support

	/// Triggered when a "SaveChanges" notification message is received.
	///
	/// Saves all changes to the Managed Object Context.
	func saveChanges()
	{
		if let moc = self.managedObjectContext, moc.hasChanges {
			do {
				try moc.save()
			} catch let error as NSError {
				// Replace this implementation with code to handle the error appropriately.
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		}
	}

	// MARK: Private methods

	/// Get the objects the storyboard has created, and connect them together.
	fileprivate func wireUpMasterAndDetailViews()
	{
		let splitViewController = window!.rootViewController as! UISplitViewController
		let detailNavigationController = splitViewController.viewControllers[1] as! UINavigationController

		let charSheetUseViewController = detailNavigationController.viewControllers[0] as! CharSheetUseViewController
		charSheetUseViewController.navigationItem.setLeftBarButton(splitViewController.displayModeButtonItem, animated: false)

		let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
		masterViewController = masterNavigationController.viewControllers[0] as! MasterViewController
		masterViewController.managedObjectContext = managedObjectContext!
	}
}



// MARK: - Application Delegate

extension AppDelegate: UIApplicationDelegate
{
	func application(_ application                 : UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
	{
		wireUpMasterAndDetailViews()
		// If we have been given a URL, make sure we can access it. Return false to abort program startup if the URL is invalid.
		if let options = launchOptions {
			let launchURL = options[UIApplicationLaunchOptionsKey.url] as! URL
			if !launchURL.isFileURL {
				return false
			}
		}
		return true
	}

	func applicationDidEnterBackground(_ application: UIApplication)
	{
		NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveChanges"), object: nil)
		UserDefaults.standard.synchronize()
	}

	func applicationWillTerminate(_ application: UIApplication)
	{
		NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveChanges"), object: nil)
		UserDefaults.standard.synchronize()
	}

	func application(_ application: UIApplication,
		open      url        : URL,
		sourceApplication       : String?,
		annotation              : Any) -> Bool
	{
		// Triggered when the user opens a .charSheet attachment in an email.
		// Import the data from the URL. Display an error if it fails.
		if url.isFileURL {
			do {
				try masterViewController.importURL(url)
			}
			catch let error as NSError {
				masterViewController.showAlertForError(error, title: "Error importing character sheet.")
			}
		}
		return false // Not a URL type we support.
	}
}
