//
//  CoreDataCollectionViewController.swift
//  OnlinePlanting
//
//  Created by Alex on 4/24/17.
//  Copyright © 2017年 epidemicreporting.com. All rights reserved.
//

import CoreData
import UIKit

/**
 Same concept as `CoreDataTableViewController`, but modified for use with `UICollectionViewController`.
 This class mostly just copies the code from `NSFetchedResultsController`
 documentation page into a subclass of `UICollectionViewController`.
 Just subclass this and set the `fetchedResultsController`.
 The only `UICollectionViewDataSource` method you'll have to implement is `collectionView:cellForItemAtIndexPath:`.
 And you can use the `NSFetchedResultsController` method `objectAtIndexPath:` to do it.
 Remember that once you create an `NSFetchedResultsController`, you cannot modify its properties.
 If you want new fetch parameters (predicate, sorting, etc.),
 create a new `NSFetchedResultsController` and set this class's `fetchedResultsController` property again.
 */
open class CoreDataCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Properties
    
    /// The controller *(this class fetches nothing if this is not set)*.
    open var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            if let frc = fetchedResultsController {
                if frc != oldValue {
                    frc.delegate = self
                    do {
                        try performFetch()
                    } catch {
                        debugPrint(error)
                    }
                }
            } else {
                collectionView?.reloadData()
            }
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
            super.viewDidLoad()
//            let bgView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
//            bgView.backgroundColor = UIColor(hexString: "#CDD2D7")
//            collectionView?.backgroundView = bgView
    }
    
    open var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool {
        get {
            return _suspendAutomaticTrackingOfChangesInManagedObjectContext
        }
        set (newValue) {
            if newValue == true {
                _suspendAutomaticTrackingOfChangesInManagedObjectContext = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self._suspendAutomaticTrackingOfChangesInManagedObjectContext = false
                }
            }
        }
    }
    
    fileprivate var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    
    open func performFetch() throws {
        guard let frc = fetchedResultsController else { return }
        
        defer {
            collectionView?.reloadData()
        }
        
        do {
            try frc.performFetch()
        } catch {
            throw error
        }
    }
    
    // MARK: - Helpers
    
    private func updateSectionsAndObjects() {
        updateSections()
        updateObjects()
    }
    
    private var sectionInserts = [Int]()
    private var sectionDeletes = [Int]()
    private var sectionUpdates = [Int]()
    
    private func updateSections() {
        if !sectionInserts.isEmpty {
            for sectionIndex in sectionInserts {
                collectionView?.insertSections(IndexSet(integer: sectionIndex))
            }
            sectionInserts.removeAll(keepingCapacity: true)
        }
        if !sectionDeletes.isEmpty {
            for sectionIndex in sectionDeletes {
                collectionView?.deleteSections(IndexSet(integer: sectionIndex))
            }
            sectionDeletes.removeAll(keepingCapacity: true)
        }
        if !sectionUpdates.isEmpty {
            for sectionIndex in sectionUpdates {
                collectionView?.reloadSections(IndexSet(integer: sectionIndex))
            }
            sectionUpdates.removeAll(keepingCapacity: true)
        }
    }
    
    private var objectInserts = [IndexPath]()
    private var objectDeletes = [IndexPath]()
    private var objectUpdates = [IndexPath]()
    
    private func updateObjects() {
        if !objectInserts.isEmpty {
            collectionView?.insertItems(at: objectInserts)
            objectInserts.removeAll(keepingCapacity: true)
        }
        if !objectDeletes.isEmpty {
            collectionView?.deleteItems(at: objectDeletes)
            objectDeletes.removeAll(keepingCapacity: true)
        }
        if !objectUpdates.isEmpty {
            collectionView?.reloadItems(at: objectUpdates)
            objectUpdates.removeAll(keepingCapacity: true)
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                         didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int,
                         for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            sectionInserts.append(sectionIndex)
        case .delete:
            sectionDeletes.append(sectionIndex)
        case .update:
            sectionUpdates.append(sectionIndex)
        default:
            break
        }
    }
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                         didChange anObject: Any, at indexPath: IndexPath?,
                         for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            guard let nip = newIndexPath else { break }
            if indexPath == nil { /// - Note: Bug fix for iOS 8.4, `indexPath` must be nil for `.insert`.
                objectInserts.append(nip)
            }
        case .delete:
            guard let ip = indexPath else { break }
            objectDeletes.append(ip)
        case .update:
            if let ip = indexPath, let nip = newIndexPath {
                if ip == nip {
                    objectUpdates.append(ip)
                } else {
                    /// - Note: Bug fix for iOS 10 (`.update` instead of `.move` -> `indexPath != newIndexPath`)
                    objectDeletes.append(ip)
                    objectInserts.append(nip)
                }
            } else {
                objectUpdates.append(indexPath!)
            }
        case .move:
            guard
                let ip = indexPath,
                let nip = newIndexPath,
                ip != nip /// - Note: Bug fix for iOS 9
                else { break }
            /// - Note: The real `.move` logic is replaced with delete/insert to avoid crashes on iOS 8/9/10.
            objectDeletes.append(ip)
            objectInserts.append(nip)
        }
    }
    
    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            collectionView?.performBatchUpdates({
                self.updateSectionsAndObjects()
            }, completion: nil)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let superNumberOfItems = super.collectionView(collectionView, numberOfItemsInSection: section)
        guard let frc = fetchedResultsController else { return superNumberOfItems }
        return (frc.sections?[section])?.numberOfObjects ?? superNumberOfItems
    }
    
}
