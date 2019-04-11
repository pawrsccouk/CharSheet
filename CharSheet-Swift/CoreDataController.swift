//
//  CoreDataController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 18/11/2016.
//  Copyright © 2016 Patrick Wallace. All rights reserved.
//

import CoreData

/// I manage the top-level Core Data objects.
class CoreDataController
{
	private var persistentStoreName: String

	/// The persistent store coordinator for the application.
	///
	/// This implementation creates and return a coordinator, having added the store for the application to it.
	var persistentStoreCoordinator: NSPersistentStoreCoordinator

	/// Returns the managed object context for the application
	///
	/// This is already bound to the persistent store coordinator for the application.
	///
	/// This property is optional since there are error conditions that could
	/// cause the creation of the context to fail.
	var managedObjectContext: NSManagedObjectContext

	/// The managed object model for the application.
	///
	/// This property is not optional. It is a fatal error for the application not to be able to find and load its model.
	var managedObjectModel: NSManagedObjectModel

	/// Initializer.
	///
	/// - parameter persistentStoreName: The filename to use to create the sqlite database.
	init(persistentStoreName: String) throws
	{
		self.persistentStoreName = persistentStoreName

		let modelURL = Bundle.main.url(forResource: "CharSheet", withExtension: "momd")!
		managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!

		persistentStoreCoordinator = try createStoreCoordinator(persistentStoreName: persistentStoreName, managedObjectModel: managedObjectModel)
		managedObjectContext = try createObjectContext(persistentStoreCoordinator: persistentStoreCoordinator)
	}
}

// MARK: - Private Data

/// The directory the application uses to store the Core Data store file.
///
/// This code uses a directory named "Patrick-Wallace.CharSheet" in the application's documents Application Support directory.
fileprivate func applicationDocumentsDirectory() -> URL
{
	let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
	return urls[urls.count - 1]
}


/// Create the persistent store coordinator for the given store name.
///
/// - parameter persistentStoreName: The filename to read or write to.
/// Usually of the form "name.sqlite" as this is a sqlite3 store type.
/// - parameter managedObjectModel: The ManagedObjectModel object this store represents.
///
/// Throws an exception if the store cannot be created.
fileprivate func createStoreCoordinator(persistentStoreName: String, managedObjectModel: NSManagedObjectModel) throws -> NSPersistentStoreCoordinator
{
	let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
	let url = applicationDocumentsDirectory().appendingPathComponent(persistentStoreName)
	// A userInfo dictionary which can be passed to addPersistentStoreWithType:configuration:url:options:error to request that Core Data automatically migrate the application to the latest version if necessary.
	let userInfo = [
		NSMigratePersistentStoresAutomaticallyOption: true,
		NSInferMappingModelAutomaticallyOption      : true]
	try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: userInfo)
	return coordinator
}

fileprivate func createObjectContext(persistentStoreCoordinator: NSPersistentStoreCoordinator) throws -> NSManagedObjectContext
{
	let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
	managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
	return managedObjectContext
}

