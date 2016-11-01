//
//  ViewController.swift
//  LineView
//
//  Created by Nishith Singh on 10/31/2016.
//  Copyright (c) 2016 Nishith Singh. All rights reserved.
//

import UIKit
import Photos
import LineView

class ViewController: UIViewController {
    @IBOutlet var lineView: LineView!{
        didSet{
            lineView.delegate = self
        }
    }
    @IBOutlet var undoButton: UIButton!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var eraseButton: UIButton!
    @IBOutlet var saveToFileButton: UIButton!
    @IBOutlet var saveToAlbumButton: UIButton!
    @IBOutlet var redoButton: UIButton!
    
    //MARK: - Handlers
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        lineView.undoButtonClicked()
    }
    
    @IBAction func clearButtonPressed(_ sender: UIButton) {
        lineView.clearButtonClicked()
    }
    
    @IBAction func eraseButtonPressed(_ sender: UIButton) {
        lineView.eraserButtonClicked()
    }
    @IBAction func saveToFileButtonPressed(_ sender: UIButton) {
        lineView.save2FileButtonClicked(controller: self)
    }
    @IBAction func saveToAlbumButtonPressed(_ sender: UIButton) {
        lineView.save2AlbumButtonClicked()
    }
    @IBAction func redoButtonPressed(_ sender: UIButton) {
        lineView.redoButtonClicked()
    }
    @IBAction func loadFromGalleryButtonPressed(_ sender: UIButton) {
        let controller = UIImagePickerController()
        controller.sourceType = .photoLibrary
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
}

extension ViewController : UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            if let imageData = UIImageJPEGRepresentation(image, 100){
                if let pngImage = UIImage(data: imageData){
                    lineView.loadFromAlbumButtonClicked(image: pngImage)
                }
            }
        }
    }
}

extension ViewController : LineViewDelegate {
    func setUndoButtonEnable(enabled:Bool){
        undoButton.isEnabled = enabled
    }
    func setClearButtonEnable(enabled:Bool){
        clearButton.isEnabled = enabled
    }
    func setEraserButtonEnable(enabled:Bool){
        eraseButton.isEnabled = enabled
    }
    func setSave2FileButtonEnable(enabled:Bool){
        saveToFileButton.isEnabled = enabled
    }
    func setSave2AlbumButtonEnable(enabled:Bool){
        saveToAlbumButton.isEnabled = enabled
    }
    func setRedoButtonEnable(enabled:Bool){
        redoButton.isEnabled = enabled
    }
    func savedToFile(URL: URL) {
        
    }
}

