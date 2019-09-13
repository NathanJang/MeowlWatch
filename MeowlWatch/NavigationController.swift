//
//  NavigationController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-06.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData
import Siren

#if !MEOWLWATCH_FULL
    import GoogleMobileAds
#endif

/// This is the navigation controller that manages child view controllers.
/// If enabled, a banner ad view is shown at the bottom of the screen.
class NavigationController: UINavigationController {

    #if !MEOWLWATCH_FULL
        /// The Google ad banner.
        var bannerView: GADBannerView?

        /// The Google interstitial controller.
        var interstitial: GADInterstitial?

        /// Creates a random ad request with a random birthday and location near Northwestern, since we don't profile users.
        lazy var adRequest: GADRequest = {
            let adRequest = GADRequest()

            if let yearNow = Calendar.current.dateComponents([.year], from: Date()).year {
                adRequest.setLocationWithLatitude(42.0565262, longitude: -87.6745328, accuracy: 3000)
            }

            adRequest.contentURL = "https://northwestern.sodexomyway.com"

            return adRequest
        }()


        var didShowModals = false

    #endif

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        #if !MEOWLWATCH_FULL
            if MeowlWatchData.shouldDisplayAds {
                let bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
                self.bannerView = bannerView
                self.toolbar.addSubview(bannerView)
                bannerView.adUnitID = MeowlWatchData.adMobBannerAdUnitID
                bannerView.rootViewController = self
                bannerView.load(adRequest)

            } else {
                self.setToolbarHidden(true, animated: false)
            }
        #else
            self.setToolbarHidden(true, animated: false)
        #endif

        view.tintColor = .purplePride

        navigationBar.prefersLargeTitles = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if !MEOWLWATCH_FULL
            conditionallyDisplayModals()
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    /// Directs the app to the settings scene.
    /// Usually used when the user taps on the widget without having purchased the widget.
    func popToRootViewControllerOrSettingsAnimatedIfNeeded() {
        guard let meowlWatchTableViewController = self.topViewController as? MeowlWatchTableViewController else {
            self.popToRootViewController(animated: false)
            if let presentedViewController = self.topViewController?.presentedViewController {
                presentedViewController.dismiss(animated: false, completion: nil)
            }
            return
        }
        if let presentedViewController = meowlWatchTableViewController.presentedViewController {
            presentedViewController.dismiss(animated: false, completion: nil)
        }
        if !MeowlWatchData.widgetIsPurchased {
            meowlWatchTableViewController.performSegue(withIdentifier: "ShowSettings", sender: self)
        }
    }

}

#if !MEOWLWATCH_FULL
    extension NavigationController: GADInterstitialDelegate {

        func interstitialDidReceiveAd(_ ad: GADInterstitial) {
            if MeowlWatchData.shouldDisplayAds && MeowlWatchData.canQuery && ad.isReady {
                ad.present(fromRootViewController: self)

                if ad.adUnitID == MeowlWatchData.adMobInterstitialAdUnitID {
                    self.interstitial = nil
                }
            }
        }

    }

    extension NavigationController {

        /// Shows them annoying popups sometimes, based on RNG.
        func conditionallyDisplayModals() {
            if !didShowModals {
                if let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, currentAppVersion != appVersion && mwLocalizedString("UpdatedVersion") == currentAppVersion {
                    showUpdatedMessage()
                    appVersion = currentAppVersion
                } else {
                    if MeowlWatchData.shouldDisplayAds {
                        let randomNumberFrom0To10 = arc4random_uniform(100)
                        if self.presentedViewController == nil && MeowlWatchData.lastQuery != nil {
                            if randomNumberFrom0To10 < 5 {
                                showTipReminder()
                            } else if randomNumberFrom0To10 < 5 {
                                // Deprecated because i'm nice
                                // showInterstitial()
                            }
                        }
                    }
                }
                didShowModals = true
            }
        }

        func showUpdatedMessage() {
            showMessageAlert(title: mwLocalizedString("UpdatedTitle"), message: mwLocalizedString("UpdatedMessage"))
        }

        /// Shows a full-screen ad.
        private func showInterstitial() {
            let interstitial = GADInterstitial(adUnitID: MeowlWatchData.adMobInterstitialAdUnitID)
            self.interstitial = interstitial
            interstitial.delegate = self
            interstitial.load(adRequest)
        }

        /// Shows a tip reminder.
        private func showTipReminder() {
            let alertController = UIAlertController(title: mwLocalizedString("TipTitle", comment: "Love MeowlWatch? Leave a tip!"), message: mwLocalizedString("TipMessage", comment: "Why they should tip"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: mwLocalizedString("TipActionTitle", comment: "Button to tip"), style: .default) { [unowned self] _ in
                self.popToRootViewControllerOrSettingsAnimatedIfNeeded()
            })
            alertController.addAction(UIAlertAction(title: mwLocalizedString("TipRateOnAppStore", comment: "Button to go to app store"), style: .default) { _ in
                let url = URL(string: rateOnAppStoreUrl)!
                UIApplication.shared.openURL(url)
            })
            alertController.addAction(UIAlertAction(title: mwLocalizedString("TipDismiss", comment: "Button to dismiss"), style: .cancel, handler: nil))
            alertController.view.tintColor = view.tintColor
            present(alertController, animated: true, completion: nil)
        }

    }
#endif
