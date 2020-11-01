//
//  ScanViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import AVFoundation
import UIKit

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var codeFrameView: UIView!
    
    let mDb = CustomerDatabase()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        captureSession = AVCaptureSession()
        if(startScan(position: currentCameraId)) {
            initScan()
        }
    }
    
    func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(
            alongsideTransition: { _ in
                self.previewLayer.connection!.videoOrientation = self.transformOrientation(
                    orientation: UIInterfaceOrientation(
                        rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
                )
                self.previewLayer.frame.size = self.view.frame.size
            },
            completion: { _ in
                
            }
        )
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func failed() {
        let ac = UIAlertController(
            title: NSLocalizedString("scanning_not_supported", comment: ""),
            message: NSLocalizedString("scanning_not_supported_description", comment: ""),
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if(captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    var currentCameraId:AVCaptureDevice.Position = .back
    func startScan(position: AVCaptureDevice.Position) -> Bool {
        let videoInput: AVCaptureDeviceInput
        let videoDevice: AVCaptureDevice? = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: position)
        if(videoDevice == nil) {
            return false
        }
        do {
            videoInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            return false
        }
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        if(captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
            captureSession.startRunning()
            return true
        } else {
            failed()
            return false
        }
    }
    func initScan() {
        let metadataOutput = AVCaptureMetadataOutput()
        if(captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.aztec,.code128,.code39,.code39Mod43,.code93,.dataMatrix,.ean13,.ean8,.interleaved2of5,.itf14,.pdf417,.qr,.upce]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = transformOrientation(
            orientation: UIInterfaceOrientation(
                rawValue: UIApplication.shared.statusBarOrientation.rawValue
            )!
        )
        //view.layer.addSublayer(previewLayer)
        view.layer.insertSublayer(previewLayer, at: 0)
        
        let interest : CGRect = CGRect(
            x: previewLayer.frame.origin.x,
            y: (previewLayer.frame.size.height/3)-20,
            width: previewLayer.frame.size.width,
            height: previewLayer.frame.size.height/2
        )
        
        codeFrameView = UIView()
        if let codeFrameView = codeFrameView {
            codeFrameView.layer.borderColor = UIColor.green.cgColor
            codeFrameView.layer.borderWidth = 2
            //codeFrameView.frame = interest
            view.addSubview(codeFrameView)
            view.bringSubviewToFront(codeFrameView)
        }
        
        metadataOutput.rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: interest)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            print("SCANNED:"+stringValue)
            AudioServicesPlayAlertSound(
                SystemSoundID(kSystemSoundID_Vibrate)
            )
            
            // check if code contains VCF formatted data
            let customers0 = CustomerVcfWriter.readVcfString(text: stringValue)
            if(customers0.count > 0) {
                askImport(customers: customers0)
                return
            }
            
            // check if code contains MECARD formatted data (similar to VCF, used by Huawei contacts app)
            if(stringValue.starts(with: "MECARD:")) {
                var formatted = stringValue.dropFirst(7)
                formatted = "BEGIN:VCARD\n" + formatted.split(separator: ";").joined(separator: "\n") + "\nEND:VCARD"
                let customers1 = CustomerVcfWriter.readVcfString(text: String(formatted))
                if(customers1.count > 0) {
                    askImport(customers: customers1)
                    return
                }
            }
            
            // no valid data found
            let cancelAction = UIAlertAction(
                title: NSLocalizedString("close", comment: ""),
                style: .cancel) { (action) in
                    self.captureSession.startRunning()
            }
            let alert = UIAlertController(
                title: NSLocalizedString("invalid_code", comment: ""),
                message: NSLocalizedString("could_not_find_valid_entries_in_this_code", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
        }
    }
    
    func askImport(customers: [Customer]) {
        if(customers.count == 0) { return }
        
        // ask for import dialog
        var importDescription = ""
        for customer in customers {
            importDescription += customer.getFirstLine()
        }
        let yesAction = UIAlertAction(
            title: NSLocalizedString("yes", comment: ""),
            style: .default) { (action) in
            for customer in customers {
                _ = self.mDb.insertCustomer(c: customer)
            }
            self.setUnsyncedChanges()
            self.navigationController?.popViewController(animated: true)
        }
        let noAction = UIAlertAction(
            title: NSLocalizedString("no", comment: ""),
            style: .cancel) { (action) in
                self.captureSession.startRunning()
        }
        let alert = UIAlertController(
            title: NSLocalizedString("do_you_want_to_import_this_customer", comment: ""),
            message: NSLocalizedString(importDescription, comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(yesAction)
        alert.addAction(noAction)
        self.present(alert, animated: true)
    }
    
    func setUnsyncedChanges() {
        if let svc = splitViewController as? MainSplitViewController {
            if let mnvc = svc.viewControllers[0] as? MasterNavigationController {
                if let mvc = mnvc.viewControllers.first as? MainViewController {
                    mvc.setUnsyncedChanges()
                }
            }
        }
    }
    
}
