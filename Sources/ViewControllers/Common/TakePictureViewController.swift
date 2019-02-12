//
//  TakePictureViewController.swift
//  OpenFoodFacts
//
//  Created by Andrés Pizá Bückmann on 29/07/2017.
//  Copyright © 2017 Andrés Pizá Bückmann. All rights reserved.
//

import UIKit
import NotificationBanner

class TakePictureViewController: UIViewController {
    var dataManager: DataManagerProtocol!
    var barcode: String!
    var imageType: ImageType = .front
    var cameraController: CameraController?

    // Feedback banners
    lazy var uploadingImageBanner: StatusBarNotificationBanner = {
        let banner = StatusBarNotificationBanner(title: "product-add.uploading-image-banner.title".localized, style: .info)
        banner.autoDismiss = false
        return banner
    }()
    lazy var uploadingImageErrorBanner: NotificationBanner = {
        let banner = NotificationBanner(title: "product-add.image-upload-error-banner.title".localized,
                                        subtitle: "product-add.image-upload-error-banner.subtitle".localized,
                                        style: .danger)
        return banner
    }()
    lazy var uploadingImageSuccessBanner: NotificationBanner = {
        let banner = NotificationBanner(title: "product-add.image-upload-success-banner.title".localized, style: .success)
        return banner
    }()
    lazy var productAddSuccessBanner: NotificationBanner = {
        let banner = NotificationBanner(title: "product-add.product-add-success-banner.title".localized, style: .success)
        return banner
    }()

    @IBAction func didTapTakePictureButton(_ sender: Any) {
        if self.cameraController == nil {
            self.cameraController = CameraControllerImpl(presentingViewController: self)
        }
        guard var cameraController = self.cameraController else { return }
        cameraController.delegate = self
        cameraController.imageType = imageType
        cameraController.show()
    }

    func postImageSuccess(image: UIImage, forImageType imageType: ImageType) { /* Do nothing, overridable */ }
}

extension TakePictureViewController: CameraControllerDelegate {
    func didGetImage(image: UIImage, forImageType imageType: ImageType?) {
        // For now, images will be always uploaded with type front
        uploadingImageBanner.show()

        guard let productImage = ProductImage(barcode: barcode, image: image, type: imageType ?? .front) else {
            uploadingImageBanner.dismiss()
            uploadingImageErrorBanner.show()
            return
        }

        log.debug("### post image for \(String(describing: imageType))")

        dataManager.postImage(productImage, onSuccess: { isOffline in
            if isOffline {
                self.uploadingImageSuccessBanner.titleLabel?.text = "product-add.image-save-success-banner.title".localized
            } else {
                self.uploadingImageSuccessBanner.titleLabel?.text = "product-add.image-upload-success-banner.title".localized
            }

            self.uploadingImageBanner.dismiss()
            self.uploadingImageSuccessBanner.show()
            self.postImageSuccess(image: image, forImageType: imageType ?? .front)
        }, onError: { _ in
            self.uploadingImageBanner.dismiss()
            self.uploadingImageErrorBanner.show()
        })
    }
}
