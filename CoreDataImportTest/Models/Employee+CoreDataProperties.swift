//
//  Employee+CoreDataProperties.swift
//  CoreDataImportTest
//
//  Created by Ryan Mathews on 3/3/16.
//  Copyright © 2016 OrangeQC. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Employee {

    @NSManaged var name: String?
    @NSManaged var id: NSNumber?
    @NSManaged var boss: Employee?
    @NSManaged var company: Company?
    @NSManaged var subordinates: Employee?

}
