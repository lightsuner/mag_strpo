import Foundation
import UIKit

public class KairosClient {
    let api_url: String = "https://api.kairos.com/"
    let app_id: String
    let app_key: String
    var headers: HTTPURLResponse?
    
    public init(app_id: String, app_key: String) {
        self.app_id = app_id
        self.app_key = app_key
    }
    
    public func convertImageToBase64String(file: String) -> String {
        let image = UIImage(named: file)
        let imageData = UIImageJPEGRepresentation(image!, 0)
        let base64String = imageData?.base64EncodedString(options:[])
        return base64String!
    }
    
    public func convertImage(ciImage: CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    public func convertImageToBase64String(ciImage: CIImage) -> String {
        let image = convertImage(ciImage: ciImage)
        let imageData = UIImageJPEGRepresentation(image, 0)
        let base64String = imageData?.base64EncodedString(options:[])
        return base64String!
    }
    
    // Kairos API - HTTP Request
    public func send(url:String, data: Dictionary<String, Any>? = [:], httpType: String, taskCallback: @escaping (Bool, AnyObject, AnyObject?) -> ()) -> Void {
        
        let jsonData = try? JSONSerialization.data(withJSONObject: data!)
        
        // create post request with headers
        let urlObject = URL(string: url)!
        var request = URLRequest(url: urlObject)
        request.httpMethod = httpType
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(self.app_id, forHTTPHeaderField: "app_id")
        request.addValue(self.app_key, forHTTPHeaderField: "app_key")
        
        // insert json data to the request
        request.httpBody = jsonData
        
        URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if let data = data {
                let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: [])
                let jsonErrors = (jsonResponse as? [String : AnyObject])?["Errors"]
                
                self.headers = response as? HTTPURLResponse
                
                if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode, jsonErrors == nil {
                    taskCallback(true, jsonResponse as AnyObject!, jsonErrors as AnyObject?)
                } else {
                    self.getError(errors: jsonErrors as AnyObject?)
                }
            }
        })
        
        task.resume()
        //PlaygroundPage.current.needsIndefiniteExecution = true
    }
    
    public func getError(errors: AnyObject?) -> Void {
        var errorCode = self.headers!.statusCode
        var errorMessage = "Could not get response"
    
        if errors != nil {
            let firstError = (errors! as! Array<[String : AnyObject]>)[0]
            
            errorCode = firstError["ErrCode"] as! Int
            errorMessage = firstError["Message"] as! String
        }

        print("Error (\(errorCode)): \(errorMessage)")
    }
    
    public func request(method: String, data: Dictionary<String, Any>? = [:], httpTypeOverride: Any? = nil, callback: @escaping (Bool, AnyObject, AnyObject?) -> ()) -> Void {
        
        let url = (self.api_url + method).replacingOccurrences(of: "\\/{2,}", with: "/", options: .regularExpression, range: nil)
        
        var httpType: String = "POST" // default
        
        let matchMediaId = "/v2/(media|analytics)/[a-z0-9]+"
        let range = url.range(of: matchMediaId, options: .regularExpression)
        
        if range != nil {
            httpType = "GET"
        }
        
        if httpTypeOverride != nil {
            httpType = httpTypeOverride as! String
        }
        
        self.send(url: url, data: data, httpType: httpType) { (ok, data, errors) in
            // if http error then display it
            if ok == false {
                self.getError(errors: errors)
            }
            
            // else pass the data along
            callback(ok, data, errors)
        }
    }
}
