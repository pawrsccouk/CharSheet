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
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    var masterViewController: MasterViewController!

    // MARK: - ApplicationDelegate

    func application(application                   : UIApplication,
		didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
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

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        self.saveContext()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    func application(application: UIApplication,
		openURL      url        : NSURL,
		sourceApplication       : String?,
		annotation              : AnyObject?) -> Bool {

        // Called when the application is started because someone clicked on or provided a document that we are registered to handle.
        // In this case, it is triggered when the user opens a .charSheet attachment in an email.
        // Import the data from the URL.
        
        if url.fileURL {
			let result = masterViewController.importURL(url)
			if !result.success {
				masterViewController.showAlertForResult(result, title: "Error importing character sheet.")
				return false // Failed to open the URL.
			}
        }
        return false // Not a URL type we support.
    }
    
    // MARK: - SplitViewControllerDelegate

	func splitViewController(splitViewController               : UISplitViewController,
		collapseSecondaryViewController secondaryViewController: UIViewController!,
		ontoPrimaryViewController primaryViewController        : UIViewController!) -> Bool {

			if let
				secondaryAsNavController = secondaryViewController as? UINavigationController,
				topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController {
					if topAsDetailController.detailItem == nil {
						// Return true to indicate that we have handled the collapse by doing nothing;
						// the secondary controller will be discarded.
						return true
					}
			}
			return false
	}

	// MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "Patrick-Wallace.CharSheet_Swift" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("CharSheet", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
        
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.

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
    
     lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    




    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    // MARK: - Private methods
    
    private func wireUpMasterAndDetailViews() {
        
        // Get the objects the storyboard has created, and connect them together.
        
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

