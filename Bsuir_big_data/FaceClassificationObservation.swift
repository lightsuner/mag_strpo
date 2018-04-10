import Foundation
import Vision

open class FaceClassificationObservation: VNClassificationObservation {
    var name: String
    var conf: Float
    
    init(name: String, confidence: Float) {
        self.name = name
        self.conf = confidence
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject(forKey: "name") as! String
        self.conf = aDecoder.decodeObject(forKey: "confidence") as! Float
        super.init(coder: aDecoder)
    }
    
    override open var identifier: String { get { return self.name} }
    
    override open var confidence: Float { get { return self.conf } }
}
