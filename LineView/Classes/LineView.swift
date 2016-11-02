//
//  LineView.swift
//  Draw on Image
//
//  Created by Nishith Singh on 22/10/16.
//  Copyright © 2016 Nishith Singh. All rights reserved.
//
import UIKit

public protocol LineViewDelegate {
    func setUndoButtonEnable(enabled:Bool)
    func setClearButtonEnable(enabled:Bool)
    func setEraserButtonEnable(enabled:Bool)
    func setSave2FileButtonEnable(enabled:Bool)
    func setSave2AlbumButtonEnable(enabled:Bool)
    func setRedoButtonEnable(enabled:Bool)
    func savedToFile(URL:URL)
}


public class LineView : UIView {
    public var delegate : LineViewDelegate?
    
    public var lineWidth : CGFloat!
    public var lineColor : UIColor!
    public var lineAlpha : CGFloat!
    public var USEUIBezierPath = false

    
    enum DrawState {
        case draw,clear,erase,undo,redo,reload
    }

    
    fileprivate let defaultColor : UIColor = UIColor.black
    fileprivate let defaultWidth : CGFloat = 5
    fileprivate let defaultAlpha : CGFloat = 1
    fileprivate lazy var bufferArray = [UIImage]()
    fileprivate lazy var lineArray = [UIImage]()
    fileprivate lazy var lineIndex = 0
    fileprivate lazy var redoIndex = 0
    
    fileprivate lazy var drawStep = DrawState.draw
    
    fileprivate lazy var previousPoint1 = CGPoint.zero
    fileprivate lazy var previousPoint2 = CGPoint.zero
    fileprivate lazy var currentPoint = CGPoint.zero

    
    fileprivate lazy var myPath = UIBezierPath()
    fileprivate var curImage : UIImage?

    fileprivate var PUSHTOFILE = true

    
    //MARK: - Lifecycle methods
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initializeView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeView()
    }
    
    override public func draw(_ rect: CGRect) {
        switch drawStep {
        case .draw:
            let mid1 = midPoint(p1:previousPoint1, p2:previousPoint2)
            let mid2 = midPoint(p1:currentPoint, p2:previousPoint1)
            if USEUIBezierPath{
                myPath.move(to: mid1)
                myPath.addQuadCurve(to: mid2, controlPoint: previousPoint1)
                self.lineColor.setStroke()
                myPath.stroke(with: .normal, alpha: self.lineAlpha)
            }else{
                curImage?.draw(at: CGPoint(x: 0, y: 0))
                let context = UIGraphicsGetCurrentContext()!
                self.layer.render(in: context)
                context.move(to: CGPoint(x: mid1.x, y: mid1.y))
                context.addQuadCurve(to: CGPoint(x: mid2.x, y: mid2.y), control: CGPoint(x: previousPoint1.x, y: previousPoint1.y))
                if previousPoint1.x == previousPoint2.x && previousPoint1.y == previousPoint2.y && previousPoint1.x == currentPoint.x && previousPoint1.y == currentPoint.y {
                    context.setLineCap(.round)
                }
                else {
                    context.setLineCap(.butt)
                }
                context.setBlendMode(.normal)
                context.setLineJoin(.round)
                context.setLineWidth(self.lineWidth)
                context.setStrokeColor(self.lineColor.cgColor)
                context.setShouldAntialias(true)
                context.setAllowsAntialiasing(true)
                context.setFlatness(0.1)
                context.setAlpha(self.lineAlpha)
                context.strokePath()
            }
            
        case .clear:
            let context = UIGraphicsGetCurrentContext()!
            context.clear(rect)
            
        case .erase:
            let mid1 = midPoint(p1: previousPoint1, p2: previousPoint2)
            let mid2 = midPoint(p1: currentPoint, p2: previousPoint1)
            if USEUIBezierPath{
                myPath.move(to: mid1)
                myPath.addQuadCurve(to: mid2, controlPoint: previousPoint1)
                self.lineColor.setStroke()
                myPath.stroke(with: .clear, alpha: self.lineAlpha)
            }else{
                curImage?.draw(at: CGPoint(x: 0, y: 0))
                let context = UIGraphicsGetCurrentContext()!
                self.layer.render(in: context)
                context.move(to: CGPoint(x: mid1.x, y: mid1.y))
                context.addQuadCurve(to: CGPoint(x: mid2.x, y: mid2.y), control: CGPoint(x: previousPoint1.x, y: previousPoint1.y))
                context.setLineCap(.round)
                context.setBlendMode(.clear)
                context.setLineJoin(.round)
                context.setLineWidth(self.lineWidth)
                context.setStrokeColor(self.lineColor.cgColor)
                context.setShouldAntialias(true)
                context.setAllowsAntialiasing(true)
                context.setFlatness(0.1)
                context.setAlpha(self.lineAlpha)
                context.strokePath()
            }
            
        case .undo:
            curImage?.draw(in: self.bounds)
            
        case .redo:
            curImage?.draw(in: self.bounds)
            
        case .reload:
            if let width = curImage?.size.width,
                let height = curImage?.size.height,
                width > height,
                let temp = curImage{
                curImage = temp.imageRotated(byDegrees: 90)
            }
            curImage?.draw(in: self.bounds)
        }
        super.draw(rect)
    }
    
    
    
    //MARK: - Touches handler methods
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            if USEUIBezierPath{
                myPath = UIBezierPath()
                myPath.lineWidth = lineWidth
                myPath.lineCapStyle = .round
            }
            
            previousPoint1 = touch.location(in: self)
            previousPoint2 = touch.location(in: self)
            currentPoint = touch.location(in: self)
            
            touchesMoved(touches, with:event)
            if PUSHTOFILE{
                redoIndex=0;
            }else{
                bufferArray.removeAll()
            }
            checkDrawStatus()
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch  = touches.first{
            previousPoint2  = previousPoint1
            previousPoint1  = currentPoint
            currentPoint    = touch.location(in:self)
            
            if drawStep != .erase{
                drawStep = .draw
            }
            calculateMinImageArea(previousPoint1,pp2: previousPoint2,cp:currentPoint)
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if #available(iOS 10, *){
            let format = UIGraphicsImageRendererFormat()
            let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: format)
            curImage = renderer.image() { (context) in
                self.layer.render(in: context.cgContext)
            }
        }else{
            if #available(iOS 10, *){
                let format = UIGraphicsImageRendererFormat()
                let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: format)
                curImage = renderer.image() { (context) in
                    self.layer.render(in: context.cgContext)
                }
            }else{
                UIGraphicsBeginImageContext(self.bounds.size);
                self.layer.render(in: UIGraphicsGetCurrentContext()!)
                curImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
            }
        }
        if PUSHTOFILE{
            lineIndex += 1
            DispatchQueue.global(qos:.background).async { self.writeFilesBG() }
        }else if let image = curImage{
            lineArray.append(image)
        }
        checkDrawStatus()
    }
    
    //MARK: - Helper methods
    fileprivate func initializeView(){
        self.backgroundColor = UIColor.clear
        self.lineWidth = defaultWidth
        self.lineColor = defaultColor
        self.lineAlpha = defaultAlpha
        if PUSHTOFILE {
            let pngPath = URL(fileURLWithPath: "\(NSTemporaryDirectory())WB").path
            // Check if the directory already exists
            let isDir : UnsafeMutablePointer<ObjCBool>? = nil
            let exists = FileManager.default.fileExists(atPath: pngPath, isDirectory: isDir)
            if exists {
                if isDir?.pointee.boolValue == false {
                    do {
                        try FileManager.default.removeItem(atPath: pngPath)
                    } catch _ {
                    }
                    // Directory does not exist so create it
                    do {
                        try FileManager.default.createDirectory(atPath: pngPath, withIntermediateDirectories: true, attributes: nil)
                    } catch _ {
                    }
                }
            } else {
                // Directory does not exist so create it
                do {
                    try FileManager.default.createDirectory(atPath: pngPath, withIntermediateDirectories: true, attributes: nil)
                } catch _ {
                }
            }
        }
        self.checkDrawStatus()
    }
    
    
    fileprivate func midPoint(p1:CGPoint,p2:CGPoint) -> CGPoint{
        return CGPoint(x: (p1.x + p2.x) * 0.5, y: (p1.y + p2.y) * 0.5)
    }
    
    fileprivate func calculateMinImageArea(_ pp1: CGPoint, pp2: CGPoint, cp: CGPoint) {
        // calculate mid point
        let mid1 = midPoint(p1: pp1, p2: pp2)
        let mid2 = midPoint(p1: cp, p2: pp1)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: mid1.x, y: mid1.y))
        path.addQuadCurve(to: CGPoint(x: mid2.x, y: mid2.y), control: CGPoint(x: pp1.x, y: pp1.y))
        let bounds = path.boundingBox
        var drawBox = bounds
        //Pad our values so the bounding box respects our line width
        drawBox.origin.x -= self.lineWidth * 1
        drawBox.origin.y -= self.lineWidth * 1
        drawBox.size.width += self.lineWidth * 2
        drawBox.size.height += self.lineWidth * 2
        if #available(iOS 10, *){
            let format = UIGraphicsImageRendererFormat()
            let renderer = UIGraphicsImageRenderer(size: drawBox.size, format: format)
            curImage = renderer.image() { (context) in
                self.layer.render(in: context.cgContext)
            }
        }else{
            UIGraphicsBeginImageContext(drawBox.size)
            self.layer.render(in: UIGraphicsGetCurrentContext()!)
            curImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        self.setNeedsDisplay(drawBox)
        RunLoop.current.run(mode: RunLoopMode.commonModes, before: Date())
    }

    fileprivate func writeFilesBG() {
        let pngPath = "\(NSTemporaryDirectory())WB/\(lineIndex).png"
        var saveImage : UIImage?
        if #available(iOS 10, *){
            let format = UIGraphicsImageRendererFormat()
            let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: format)
            saveImage = renderer.image() { (context) in
                self.layer.render(in: context.cgContext)
            }
        }else{
            UIGraphicsBeginImageContext(self.bounds.size);
            self.layer.render(in: UIGraphicsGetCurrentContext()!)
            saveImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        do{
            try UIImagePNGRepresentation(saveImage!)?.write(to:URL(fileURLWithPath:pngPath), options: .atomicWrite)
        }catch{
            
        }
    }

    fileprivate func showError(with title:String,andMessage message:String, onController controller:UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Button handler methods
    public func redrawLine()
    {
        UIGraphicsBeginImageContext(self.bounds.size)
        self.layer.render(in:UIGraphicsGetCurrentContext()!)
        if PUSHTOFILE,let image = UIImage(contentsOfFile:"\(NSTemporaryDirectory())WB/\(lineIndex).png"){
            curImage = image
        }else if let lastImage = lineArray.last{
            curImage = lastImage
        }else{
            curImage = nil
        }
        UIGraphicsEndImageContext();
        setNeedsDisplay(self.bounds)
    }
    
    public func undoButtonClicked()
    {
        if PUSHTOFILE{
            lineIndex -= 1
            redoIndex += 1
            drawStep = .undo
            redrawLine()
        }else{
            if lineArray.count > 0,
            let line = lineArray.last{
                bufferArray.append(line)
                lineArray.removeLast()
                drawStep = .undo
                redrawLine()
            }
        }
        checkDrawStatus()
    }

    public func redoButtonClicked()
    {
        if PUSHTOFILE{
            lineIndex += 1
            redoIndex -= 1
            drawStep = .redo
            redrawLine()
        }else{
            if bufferArray.count > 0,
            let line = bufferArray.last{
                lineArray.append(line)
                bufferArray.removeLast()
                drawStep = .redo
                redrawLine()
            }
        }
        checkDrawStatus()
    }

    public func clearButtonClicked()
    {
        if #available(iOS 10, *){
            let format = UIGraphicsImageRendererFormat()
            let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: format)
            curImage = renderer.image() { (context) in
                self.layer.render(in: context.cgContext)
            }
        }else{
            UIGraphicsBeginImageContext(self.bounds.size);
            self.layer.render(in: UIGraphicsGetCurrentContext()!)
            curImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        drawStep = .clear
        setNeedsDisplay(self.bounds)
        if PUSHTOFILE{
            lineIndex = 0
            redoIndex = 0
        }else{
            lineArray.removeAll()
            bufferArray.removeAll()
        }
        checkDrawStatus()
    }
    
    public func eraserButtonClicked() {
        if drawStep != .erase {
            drawStep = .erase
        } else {
            drawStep = .draw
        }
    }

    public func setColor(r:CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) {
        self.lineColor = UIColor(red: r, green: g, blue: b, alpha: a)
        self.lineAlpha = a;
    }

    public func save2FileButtonClicked(controller:UIViewController) {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "dd-MM-yyyy_HH:mm:ss"
        let dateString = dateFormat.string(from: Date())
        
        let pngPath = "\(NSTemporaryDirectory())Screenshot_\(dateString).png"
        var saveImage : UIImage?
        if #available(iOS 10, *){
            let format = UIGraphicsImageRendererFormat()
            let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: format)
            saveImage = renderer.image() { (context) in
                self.layer.render(in: context.cgContext)
            }
        }else{
            UIGraphicsBeginImageContext(self.bounds.size);
            self.layer.render(in: UIGraphicsGetCurrentContext()!)
            saveImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        do{
            try UIImagePNGRepresentation(saveImage!)?.write(to: URL(fileURLWithPath:pngPath), options: .atomic)
        } catch {
            showError(with: "Error", andMessage: "Failed to save file", onController: controller)
            return
        }
        showError(with: "Success", andMessage: "File saved", onController: controller)
        delegate?.savedToFile(URL: URL(fileURLWithPath:pngPath))
    }
    
    
    public func save2AlbumButtonClicked() {
        var saveImage : UIImage?
        if #available(iOS 10, *){
            let format = UIGraphicsImageRendererFormat()
            let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: format)
            saveImage = renderer.image() { (context) in
                self.layer.render(in: context.cgContext)
            }
        }else{
            UIGraphicsBeginImageContext(self.bounds.size);
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            saveImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        UIImageWriteToSavedPhotosAlbum(saveImage!, self, nil, nil)
    }
    

    public func loadFromAlbumButtonClicked(image:UIImage) {
        drawStep = .reload
        curImage = image
        setNeedsDisplay()
    }

    //MARK: - toolbarDelegate method
    fileprivate func checkDrawStatus() {
        func callEnablerButtonsWithPushToFile(enabled:Bool){
            delegate?.setUndoButtonEnable(enabled: enabled)
            delegate?.setClearButtonEnable(enabled: enabled)
            delegate?.setEraserButtonEnable(enabled: enabled)
            delegate?.setSave2FileButtonEnable(enabled: enabled)
            delegate?.setSave2AlbumButtonEnable(enabled: enabled)
            
        }
        if (PUSHTOFILE && lineIndex > 0) || (!PUSHTOFILE && lineArray.count > 0){
            callEnablerButtonsWithPushToFile(enabled: true)
        }else if (PUSHTOFILE && lineIndex == 0) || !PUSHTOFILE && lineArray.count == 0{
            callEnablerButtonsWithPushToFile(enabled: false)
        }
        
        if (PUSHTOFILE && redoIndex > 0) || (!PUSHTOFILE && bufferArray.count > 0){
            delegate?.setRedoButtonEnable(enabled: true)
            delegate?.setClearButtonEnable(enabled: true)
        }else if (PUSHTOFILE && redoIndex == 0) || (!PUSHTOFILE && bufferArray.count == 0){
            delegate?.setRedoButtonEnable(enabled: false)
        }
    }
}

extension UIImage{
    fileprivate func imageRotated(byDegrees:CGFloat) -> UIImage{
        var image : UIImage!
        if #available(iOS 10, *){
            let format = UIGraphicsImageRendererFormat()
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            image = renderer.image() { (context) in
                context.cgContext.rotate(by: byDegrees.toRadians())
                draw(at: CGPoint(x: 0, y: 0))
            }
        }else{
            UIGraphicsBeginImageContext(size)
            let context = UIGraphicsGetCurrentContext()!
            context.rotate(by: byDegrees.toRadians())
            draw(at: CGPoint(x: 0, y: 0))
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        return image
    }
}

extension CGFloat{
    fileprivate func toRadians() -> CGFloat{
        return self * .pi / 180
    }
}
