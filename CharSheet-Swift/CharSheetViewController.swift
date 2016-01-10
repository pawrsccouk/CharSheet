//
//  CharSheetViewController.swift
//  CharSheet
//
//  Created by Patrick Wallace on 13/07/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

import UIKit
import CoreData

/// Abstract base-class for view controllers that use Managed Object Contexts and CharSheet objects.
///
/// This just ensures there is a charSheet property and a managedObjectContext properties on each subclass.
class CharSheetViewController: UIViewController
{
	/// The char sheet this controller will manage.
	var charSheet: CharSheet!

	/// The ManagedObjectContext needed to make changes to the Core Data objects.
	var managedObjectContext: NSManagedObjectContext!
}
