//
//  MainTableViewController.swift
//  CoreDataImportTest
//
//  Created by Ryan Mathews on 3/3/16.
//  Copyright © 2016 OrangeQC. All rights reserved.
//

import UIKit
import MagicalRecord
import CoreDataImportKit
import MessageUI

struct ImportStats {
    var isCold: Bool
    var time: Double
    var isHalf: Bool
}

class MainTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    let cellNames = ["Import Half", "Import with MagicalRecord", "Import with CoreDataImportKit", "Imported Objects", "Reset Stats", "Email Stats"]
    var databaseIsCold = true
    var importHalf = true

    var companies: [ [NSObject : AnyObject] ] = []
    var employees: [ [NSObject : AnyObject] ] = []

    var magicalRecordStats: [ ImportStats ] = []
    var cdiImportStats: [ ImportStats ] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Import Tests"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: Selector("trashDatabase"))

        companies = dataFromJSONFile("companies") as! [ [NSObject : AnyObject] ]
        employees = dataFromJSONFile("employees") as! [ [NSObject : AnyObject] ]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellNames.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let identifier = [1,2,3].indexOf(indexPath.row) == nil ? "basicCell" : "subtitleCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)

        cell.textLabel?.text = cellNames[indexPath.row]

        if indexPath.row == 0 {
            cell.textLabel?.text = importHalf ? "Import Half" : "Import All"
        }
        else if indexPath.row == 1 {
            let (hot, cold) = hotAndColdStats(magicalRecordStats)
            cell.detailTextLabel?.text = "Hot (\(hot.count)): \(hot.avg) sec, Cold (\(cold.count)): \(cold.avg) sec"
        }
        else if indexPath.row == 2 {
            let (hot, cold) = hotAndColdStats(cdiImportStats)
            cell.detailTextLabel?.text = "Hot (\(hot.count)): \(hot.avg) sec, Cold (\(cold.count)): \(cold.avg) sec"
        }
        else if indexPath.row == 3 {
            let employeeCount = Employee.MR_countOfEntities()
            let companyCount = Company.MR_countOfEntities()
            cell.detailTextLabel?.text = "\(employeeCount) employees, \(companyCount) companies"
        }

        return cell;
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch indexPath.row {
        case 0:
            switchImportHalf()
        case 1:
            importWithMagicalRecord()
        case 2:
            importWithCoreDataImportKit()
        case 3:
            print("not implimented")
        case 4:
            resetStats()
        case 5:
            emailStats()
        default:
            print("not implimented")
        }
    }

    func switchImportHalf() {
        importHalf = !importHalf
        tableView.reloadData()
    }

    // Doesn't work as expected
//    func runMultipleTests(count: Int) {
//        for _ in 0...count {
//
//            // Reset everything
//            trashDatabase()
//
//            // Cold for CDI
//            importWithCoreDataImportKit()
//
//            // Warm for CDI
//            importWithCoreDataImportKit()
//            
//            // Reset everything
//            trashDatabase()
//
//            // Cold for MR
//            importWithMagicalRecord()
//
//            // Warm for MR
//            importWithMagicalRecord()
//
//
//        }
//    }

    func trashDatabase() {
        NSManagedObjectContext.MR_rootSavingContext().deleteAllData()
        databaseIsCold = true
        tableView.reloadData()
    }

    func dataFromJSONFile(fileName: String) -> AnyObject? {
        let url = NSBundle.mainBundle().URLForResource(fileName, withExtension: "json")
        let data = NSData(contentsOfURL: url!)

        do {
            return try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
        }
        catch { /* Try again */ }
        return nil;
    }

    func importWithMagicalRecord() {

        let beginning = NSDate().timeIntervalSince1970

        let rootContext = NSManagedObjectContext.MR_rootSavingContext()
        let localContext = NSManagedObjectContext.MR_contextWithParent(rootContext)

        localContext.performBlockAndWait { () -> Void in


            let companyArray: [ [ NSObject : AnyObject ] ] = self.importHalf ? Array(self.companies.prefixThrough(self.companies.count / 2)) : self.companies
            Company.MR_importFromArray(companyArray, inContext: localContext)

            let employeeArray: [ [ NSObject : AnyObject ] ] = self.importHalf ? Array(self.employees.prefixThrough(self.employees.count / 2)) : self.employees
            Employee.MR_importFromArray(employeeArray, inContext: localContext)

            localContext.MR_saveToPersistentStoreWithCompletion({ (success: Bool, error: NSError?) -> Void in
                let ending = NSDate().timeIntervalSince1970
                let time = (ending - beginning)
                self.magicalRecordStats.append(ImportStats(isCold: self.databaseIsCold, time: time, isHalf: self.importHalf))
                self.tableView.reloadData()
                self.databaseIsCold = false
            })
        }
    }

    func importWithCoreDataImportKit() {
        let beginning = NSDate().timeIntervalSince1970

        let rootContext = NSManagedObjectContext.MR_rootSavingContext()
        let localContext = NSManagedObjectContext.MR_contextWithParent(rootContext)

        localContext.performBlockAndWait { () -> Void in

            let companyArray: [ [ NSObject : AnyObject ] ] = self.importHalf ? Array(self.companies.prefixThrough(self.companies.count / 2)) : self.companies
            let mapping1 = CDIMapping(entityName: "Company", inManagedObjectContext: localContext)
            let cdiImport1 = CDIImport(externalRepresentation: companyArray, mapping: mapping1, context: localContext)
            cdiImport1.importRepresentation()

            let employeeArray: [ [ NSObject : AnyObject ] ] = self.importHalf ? Array(self.employees.prefixThrough(self.employees.count / 2)) : self.employees
            let mapping2 = CDIMapping(entityName: "Employee", inManagedObjectContext: localContext)
            let cdiImport2 = CDIImport(externalRepresentation: employeeArray, mapping: mapping2, context: localContext)
            cdiImport2.importRepresentation()

            localContext.MR_saveToPersistentStoreWithCompletion({ (success: Bool, error: NSError?) -> Void in
                let ending = NSDate().timeIntervalSince1970
                let time = (ending - beginning)
                self.cdiImportStats.append(ImportStats(isCold: self.databaseIsCold, time: time, isHalf: self.importHalf))
                self.tableView.reloadData()
                self.databaseIsCold = false
            })
        }
    }

    func resetStats() {
        magicalRecordStats = []
        cdiImportStats = []
        tableView.reloadData()
    }

    func hotAndColdStats(stats: [ ImportStats ]) -> (hot: (count: Int, avg: Double), cold: (count: Int, avg: Double)) {
        let coldTimes = stats.filter { $0.isCold == true }.map { $0.time }
        let hotTimes = stats.filter { $0.isCold == false }.map { $0.time }
        let coldAvg = coldTimes.count == 0 ? 0.0 : coldTimes.reduce(0, combine: +) / Double(coldTimes.count)
        let hotAvg = hotTimes.count == 0 ? 0.0 : hotTimes.reduce(0, combine: +) / Double(hotTimes.count)

        func simpleDouble(d: Double) -> Double {
            let multiplier = pow(10.0, 2.0)
            return round(d * multiplier) / multiplier
        }

        return ((hotTimes.count, simpleDouble(hotAvg)), (coldTimes.count, simpleDouble(coldAvg)))
    }

    func emailStats() {
        var emailAttachment = "library, is cold, half import, time\n"
        for stat in magicalRecordStats {
            emailAttachment += "magical record,\(stat.isCold),\(stat.isHalf),\(stat.time)\n"
        }
        for stat in cdiImportStats {
            emailAttachment += "cord data import kit,\(stat.isCold),\(stat.isHalf),\(stat.time)\n"
        }

        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setSubject("Core Data import stats")
        mailComposerVC.setMessageBody("Here is a csv with the stats from your session.", isHTML: false)

        if let attachment = emailAttachment.dataUsingEncoding(NSUTF8StringEncoding) {
            mailComposerVC.addAttachmentData(attachment, mimeType: "text", fileName: "core-data-import-stats.csv")
        }

        self.presentViewController(mailComposerVC, animated: true, completion: nil)
    }

    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}

// http://stackoverflow.com/a/34551827/130556
extension NSManagedObjectContext
{
    func deleteAllData()
    {
        guard let persistentStore = persistentStoreCoordinator?.persistentStores.last else {
            return
        }

        guard let url = persistentStoreCoordinator?.URLForPersistentStore(persistentStore) else {
            return
        }

        performBlockAndWait { () -> Void in
            self.reset()
            do
            {
                try self.persistentStoreCoordinator?.removePersistentStore(persistentStore)
                try NSFileManager.defaultManager().removeItemAtURL(url)
                try self.persistentStoreCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
            }
            catch { /*dealing with errors up to the usage*/ }
        }
    }
}