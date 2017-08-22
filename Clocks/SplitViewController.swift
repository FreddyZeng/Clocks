//
//  SplitViewController.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/21.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose with or without
//  fee is hereby granted, provided that the above copyright notice and this permission notice
//  appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
//  SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//  AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
//  NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
//  OF THIS SOFTWARE.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
	
	@IBOutlet var masterViewController: UINavigationController?
	@IBOutlet var detailViewController: UINavigationController?
	var lastPresentedUuid: UUID?
	
	// This is a more robust tracking of `isCollapsed`
	var needPopWhenClearing: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		detailViewController = viewControllers.last as? UINavigationController
		masterViewController = viewControllers.first as? UINavigationController
		
		// Override point for customization after application launch.
		self.preferredDisplayMode = .allVisible
		self.delegate = self
		detailViewController?.topViewController?.navigationItem.leftBarButtonItem = displayModeButtonItem
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: ViewState.changedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Document.changedNotification, object: nil)
		lastPresentedUuid = ViewState.shared.topLevel.detailView?.uuid
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@objc func handleChangeNotification(_ notification: Notification) {
		guard let dvc = detailViewController, let mvc = masterViewController else { return }
		let isUserAction = notification.userActionData != nil
		if let uuid = ViewState.shared.topLevel.detailView?.uuid, Document.shared.timezones[uuid] != nil, lastPresentedUuid == nil {
			lastPresentedUuid = uuid
			
			if isUserAction {
				showDetailViewController(dvc, sender: mvc)
			} else {
				UIView.performWithoutAnimation {
					showDetailViewController(dvc, sender: nil)
				}
			}
		} else if ViewState.shared.topLevel.detailView.map({ Document.shared.timezones[$0.uuid] }) == nil, lastPresentedUuid != nil {
			lastPresentedUuid = nil
			if needPopWhenClearing {
				if mvc.topViewController == dvc {
					mvc.popViewController(animated: isUserAction)
				}
				
				// This avoids an animation glitch where the second time the view controller is presented, it is presented at "navigation bar hidden" sizing before "popping" to "navigation bar visible" sizing.
				if let fvc = dvc.viewControllers.last {
					dvc.viewControllers.remove(at: dvc.viewControllers.count - 1)
					dvc.pushViewController(fvc, animated: false)
				}
			}
		}
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		detailViewController?.topViewController?.navigationItem.leftBarButtonItem = nil
		needPopWhenClearing = true
		if ViewState.shared.topLevel.detailView == nil {
			// Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
			return true
		}
		return false
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
		needPopWhenClearing = false
		detailViewController?.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
		return nil
	}
}
