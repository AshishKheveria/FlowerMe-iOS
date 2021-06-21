//
//  ViewController.swift
//  FlowerMe
//
//  Created by Ashish Kheveria on 15/06/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var summaryLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert image to CIImage.")
            }
            detect(image: convertedCIImage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        
        //creating a vision container for our MLModel
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed!")
        }
        
        //creating a request
        let request = VNCoreMLRequest(model: model) { request, error in
            
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify the image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        //creating the handler to process the request
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
        ]
        
        //Now gonna make the alamofire request
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { response in
            
            do {
            let dataResponse = try response.result.get()
            let flowerJSON: JSON = JSON(dataResponse)
            let pageID = flowerJSON["query"]["pageids"][0].stringValue
            let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
            let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
            self.summaryLabel.text = flowerDescription
            } catch {
            print("Error, \(error)")
            }

        }
    }
    
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }    
}

