//
//  NavigationController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-06.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData

#if !MEOWLWATCH_FULL
    import GoogleMobileAds
#endif

class NavigationController: UINavigationController {

    #if !MEOWLWATCH_FULL
        /// The Google ad banner.
        var bannerView: GADBannerView?

        /// The Google interstitial controller.
        var interstitial: GADInterstitial?

        lazy var adRequest: GADRequest = {
            let adRequest = GADRequest()
            var birthdayComponents = DateComponents()
            birthdayComponents.year = Calendar.current.dateComponents([.year], from: Date()).year! - 18 - Int(arc4random_uniform(4)) // Random year 18 to 22 years ago
            birthdayComponents.month = 1 + Int(arc4random_uniform(12))
            birthdayComponents.day = 1 + Int(arc4random_uniform(28))
            adRequest.birthday = Calendar.current.date(from: birthdayComponents)
            adRequest.setLocationWithLatitude(42.0565262, longitude: -87.6745328, accuracy: 3000)
            adRequest.contentURL = "https://northwestern.sodexomyway.com"
            return adRequest
        }()
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        #if !MEOWLWATCH_FULL
            if MeowlWatchData.shouldDisplayAds {
                self.bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
                let bannerView = self.bannerView!
                self.toolbar.addSubview(bannerView)
                bannerView.adUnitID = MeowlWatchData.adMobBannerAdUnitID
                bannerView.rootViewController = self
                bannerView.load(adRequest)

                maybeShowInterstitial()
            } else {
                self.setToolbarHidden(true, animated: false)
            }
        #else
            self.setToolbarHidden(true, animated: false)
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

        /// Loads the interstitial if the RNG allows.
        func maybeShowInterstitial() {
            if arc4random_uniform(3) < 1 && self.presentedViewController == nil {
                self.interstitial = GADInterstitial(adUnitID: MeowlWatchData.adMobInterstitialAdUnitID)
                interstitial!.delegate = self
                interstitial!.load(adRequest)
            }
        }

    }
#endif
