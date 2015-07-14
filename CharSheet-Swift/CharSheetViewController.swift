//
//  CharSheetViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 13/07/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

import UIKit
import CoreData

/// Base-class for view controllers that use Managed Object Contexts and CharSheet objects.
class CharSheetViewController: UIViewController
{
	/// The char sheet this controller will manage.
	var charSheet: CharSheet!

	/// The ManagedObjectContext needed to make changes to the Core Data objects.
	var managedObjectContext: NSManagedObjectContext!
}
