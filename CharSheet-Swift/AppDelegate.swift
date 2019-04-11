//
//  AppDelegate.swift
//  CharSheet-Swift
//
//  Created by Patrick Wallace on 31/10/2014.
//  Copyright (c) 2014 Patrick Wallace. All rights reserved.
//

import UIKit
import CoreData

private let SaveChanges = Notification.Name("SaveChanges")

@UIApplicationMain
class AppDelegate: UIResponder
{
	var window: UIWindow?
	var masterViewController: MasterViewController!
	lazy var model: Model = {
		return Model(coreDataController: self.coreDataController)
	}()

	lazy var coreDataController: CoreDataController = {
		do {
			let cdc = try CoreDataController(persistentStoreName: "CharSheet.sqlite")
			return cdc
		} catch let error as NSError {
			fatalError("Failed to initialize Core Data with error \(error), \(error.userInfo)")
		}
	}()

	private var saveChangesObserver: NSObjectProtocol!

	override init()
	{
		super.init()
		saveChangesObserver = NotificationCenter.default.addObserver(forName: SaveChanges, object: nil, queue: nil) {
			notification in self.saveChanges()
		}

	}

	deinit
	{
		if let saveChanges = saveChangesObserver {
			NotificationCenter.default.removeObserver(saveChanges)
		}
	}


	// MARK: Core Data Saving support

	/// Triggered when a "SaveChanges" notification message is received.
	///
	/// Saves all changes to the Managed Object Context.
	func saveChanges()
	{
		let moc = coreDataController.managedObjectContext
		if moc.hasChanges {
			do {
				try moc.save()
			} catch let error as NSError {
				fatalError("Unresolved error \(error), \(error.userInfo)")	// Replace with code to handle the error appropriately.
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
		masterViewController = (masterNavigationController.viewControllers[0] as! MasterViewController)
		masterViewController.managedObjectContext = coreDataController.managedObjectContext
		masterViewController.model = model
	}
}



// MARK: - Application Delegate

extension AppDelegate: UIApplicationDelegate
{
	func application(_ application                 : UIApplication,
					 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		wireUpMasterAndDetailViews()
		// If we have been given a URL, make sure we can access it. Return false to abort program startup if the URL is invalid.
		if let options = launchOptions {
			let launchURL = options[UIApplication.LaunchOptionsKey.url] as! URL
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

	func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool
	{
		// Triggered when the user opens a .charSheet attachment in an email.
		// Import the data from the URL. Display an error if it fails.
		// This will add the entry to the FetchedResultsController, which will trigger an update
		// in it's delegate (the master view controller).
		if url.isFileURL {
			do {
				_ = try model.importCharSheet(from: url)
			}
			catch let error as NSError {
				masterViewController.showAlertForError(error, title: "Error importing character sheet.")
			}
		}
		return false // Not a URL type we support.
	}
}
