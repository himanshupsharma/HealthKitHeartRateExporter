//
//  ViewController.swift
//  HeartRateExporter
//
//  Created by Himanshu Sharma-SSI on 11/18/15.
//  Copyright © 2015 Himanshu Sharma-SSI. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    //MARK: Properties
    
    @IBOutlet weak var startTimePicker: UIDatePicker!
    
    @IBOutlet weak var endTimePicker: UIDatePicker!
    
    let healthStore = HKHealthStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Actions

    @IBAction func downloadHeartRate(sender: UIButton) {
        let heartRateType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        
        if (HKHealthStore.isHealthDataAvailable()){
            var csvString = "Time,Date,Heartrate(BPM)\n"
            self.healthStore.requestAuthorizationToShareTypes(nil, readTypes:[heartRateType], completion:{(success, error) in
                let sortByTime = NSSortDescriptor(key:HKSampleSortIdentifierEndDate, ascending:false)
                let timeFormatter = NSDateFormatter()
                timeFormatter.dateFormat = "hh:mm:ss"
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "MM/dd/YYYY"
                
                let startTime = self.startTimePicker.date
                let endTime = self.endTimePicker.date
                let predicate = HKQuery.predicateForSamplesWithStartDate(startTime, endDate: endTime, options: .StrictStartDate)
                
                let query = HKSampleQuery(sampleType:heartRateType, predicate:predicate, limit:0, sortDescriptors:[sortByTime], resultsHandler:{(query, results, error) in
                    guard let results = results else { return }
                    if(0 == results.count) {
                        let alert = UIAlertController(title: "Error", message: "No data available for this time range.", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                        return
                    }
                    for quantitySample in results {
                        let quantity = (quantitySample as! HKQuantitySample).quantity
                        let heartRateUnit = HKUnit(fromString: "count/min")
                        
                        csvString += "\(timeFormatter.stringFromDate(quantitySample.startDate)),\(dateFormatter.stringFromDate(quantitySample.startDate)),\(quantity.doubleValueForUnit(heartRateUnit))\n"
                        print("\(timeFormatter.stringFromDate(quantitySample.startDate)),\(dateFormatter.stringFromDate(quantitySample.startDate)),\(quantity.doubleValueForUnit(heartRateUnit))")
                    }
                    
                    do {
                        let documentsDir = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain:.UserDomainMask, appropriateForURL:nil, create:true)
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "dd-MM-yyyy-hh-mm-ss"
                        let filename = "heartratedata_" + dateFormatter.stringFromDate(startTime) + "_" + dateFormatter.stringFromDate(endTime) + ".csv"
                        try csvString.writeToURL(NSURL(string:filename, relativeToURL:documentsDir)!, atomically:true, encoding:NSASCIIStringEncoding)
                    }
                    catch {
                        print("Error occured")
                    }
                    
                })
                self.healthStore.executeQuery(query)
            })

        } else {
            print("Access to Health Store is not available.")
            let alert = UIAlertController(title: "Error", message: "Access to Health Store is not available.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

