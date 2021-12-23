

import UIKit

struct Prediction {
  let classIndex: Int
  let score: Float
  let rect: CGRect
}

class PrePostProcessor : NSObject {
    // 모델 입력 이미지 크기
    static let inputWidth = 640
    static let inputHeight = 640

    // model output is of size 25200*85  10668
    static let outputRow = 25200 // YOLOv5 모델 input size 640 * 640 기준 output Row 값 25200
    static let outputColumn = 85 // 클래스 수 + 5 (left, top, right, bottom, score) 값
    static let threshold : Float = 0.35 // 객체 탐지를 진행하는 최소한의 임계값 35%
    static let nmsLimit = 100 // 최대 탐지 개수
    
    // The two methods nonMaxSuppression and IOU below are from  https://github.com/hollance/YOLO-CoreML-MPSNNGraph/blob/master/Common/Helpers.swift
    /**
      Removes bounding boxes that overlap too much with other boxes that have
      a higher score.
      - Parameters:
        - boxes: an array of bounding boxes and their scores
        - limit: the maximum number of boxes that will be selected
        - threshold: used to decide whether boxes overlap too much
    */
    static func nonMaxSuppression(boxes: [Prediction], limit: Int, threshold: Float) -> [Prediction] {
      // Do an argsort on the confidence scores, from high to low.
      let sortedIndices = boxes.indices.sorted { boxes[$0].score > boxes[$1].score }

      var selected: [Prediction] = []
      var active = [Bool](repeating: true, count: boxes.count)
      var numActive = active.count

      // The algorithm is simple: Start with the box that has the highest score.
      // Remove any remaining boxes that overlap it more than the given threshold
      // amount. If there are any boxes left (i.e. these did not overlap with any
      // previous boxes), then repeat this procedure, until no more boxes remain
      // or the limit has been reached.
      outer: for i in 0..<boxes.count {
        if active[i] {
          let boxA = boxes[sortedIndices[i]]
          selected.append(boxA)
          if selected.count >= limit { break }

          for j in i+1..<boxes.count {
            if active[j] {
              let boxB = boxes[sortedIndices[j]]
              if IOU(a: boxA.rect, b: boxB.rect) > threshold {
                active[j] = false
                numActive -= 1
                if numActive <= 0 { break outer }
              }
            }
          }
        }
      }
      return selected
    }

    /**
      Computes intersection-over-union overlap between two bounding boxes.
    */
    static func IOU(a: CGRect, b: CGRect) -> Float {
      let areaA = a.width * a.height
      if areaA <= 0 { return 0 }

      let areaB = b.width * b.height
      if areaB <= 0 { return 0 }

      let intersectionMinX = max(a.minX, b.minX)
      let intersectionMinY = max(a.minY, b.minY)
      let intersectionMaxX = min(a.maxX, b.maxX)
      let intersectionMaxY = min(a.maxY, b.maxY)
      let intersectionArea = max(intersectionMaxY - intersectionMinY, 0) *
                             max(intersectionMaxX - intersectionMinX, 0)
      return Float(intersectionArea / (areaA + areaB - intersectionArea))
    }

    static func outputsToNMSPredictions(outputs: [NSNumber], imageWidth: CGFloat, imageHeight: CGFloat) -> [Prediction] {
        var predictions = [Prediction]()
        for i in 0..<outputRow {
            if Float(truncating: outputs[i*outputColumn+4]) > threshold {
                let x = Double(truncating: outputs[i*outputColumn])
                let y = Double(truncating: outputs[i*outputColumn+1])
                let w = Double(truncating: outputs[i*outputColumn+2])
                let h = Double(truncating: outputs[i*outputColumn+3])
                
                let left = (x - w/2)
                let top = (y - h/2)
                let right = (x + w/2)
                let bottom = (y + h/2)
                
                var max = Double(truncating: outputs[i*outputColumn+5])
                var cls = 0
                for j in 0 ..< outputColumn-5 {
                    if Double(truncating: outputs[i*outputColumn+5+j]) > max {
                        max = Double(truncating: outputs[i*outputColumn+5+j])
                        cls = j
                    }
                }

                let rect = CGRect(x: left, y: top, width: right-left, height: bottom-top).applying(CGAffineTransform(scaleX: CGFloat(imageWidth), y: CGFloat(imageHeight)))
                
                
                //output 값은 outputs[i * (클래스 수 + 5) + 4]
                let prediction = Prediction(classIndex: cls, score: Float(truncating: outputs[i*outputColumn+4]), rect: rect)
                predictions.append(prediction)
            }
        }

        return nonMaxSuppression(boxes: predictions, limit: nmsLimit, threshold: threshold)
    }

    static func cleanDetection(imageView: UIImageView) {
        if let layers = imageView.layer.sublayers {
            for layer in layers {
                if layer is CATextLayer {
                    layer.removeFromSuperlayer()
                }
            }
            for view in imageView.subviews {
                view.removeFromSuperview()
            }
        }
    }

    static func showDetection(imageView: UIImageView, nmsPredictions: [Prediction], classes: [String]) {
        
        for pred in nmsPredictions {
            let bbox = UIView(frame: pred.rect)
            bbox.backgroundColor = UIColor.clear
            bbox.layer.borderColor = UIColor.yellow.cgColor
            bbox.layer.borderWidth = 2
            imageView.addSubview(bbox)
            
            let textLayer = CATextLayer()
            textLayer.string = String(format: " %@ %.2f", classes[pred.classIndex], pred.score)
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.backgroundColor = UIColor.magenta.cgColor
            textLayer.fontSize = 14
            textLayer.frame = CGRect(x: pred.rect.origin.x, y: pred.rect.origin.y, width:100, height:20)
            imageView.layer.addSublayer(textLayer)
            
        }
    }

}
