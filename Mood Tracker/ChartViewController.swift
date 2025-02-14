import UIKit
import Parse 

class ChartViewController: UIViewController, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource {

    var moods = [PFObject]()
    var moodCount = Int()
    var moodAverage = 0.0

    let userID = UIDevice.currentDevice().identifierForVendor.UUIDString
    
    @IBOutlet weak var chartView: BEMSimpleLineGraphView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var checkIn: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIn.layer.cornerRadius = 25
        checkIn.layer.masksToBounds = true
        
        loadMoods()
        beautifyGraph()
        
        dateLabel.text = ""
        ratingLabel.text = ""
        commentLabel.text = ""
        
        activityIndicator.startAnimating()        
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewWillAppear(animated: Bool) {
        loadMoods()
    }
    
    
    // MARK: - Navigation
    
    var transition = QZCircleSegue()
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationViewController = segue.destinationViewController as! RatingViewController
        self.transition.animationChild = checkIn
        self.transition.animationColor = UIColor.greenSeaColor()
        self.transition.fromViewController = self
        self.transition.toViewController = destinationViewController
        destinationViewController.transitioningDelegate = transition
    }
    
    
    @IBAction func unwindToMainViewController (sender: UIStoryboardSegue){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // Retrieve Parse data & calculate average
    
    func loadMoods() {
        var query = PFQuery(className:"Moods")
        
        query.whereKey("user", equalTo: userID)
        query.cachePolicy = .NetworkElseCache

        query.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [PFObject] {
                    self.moods = objects
                    self.chartView.reloadGraph()
                    
                    query.countObjectsInBackgroundWithBlock { (count: Int32, error: NSError?) -> Void in
                        if error == nil && count > 0 {
                            
                            var ratingTotal = 0
                            
                            for mood in self.moods {
                                ratingTotal += mood["rating"] as! Int
                            }
                            
                            self.moodAverage = Double(ratingTotal)/Double(self.moods.count)
                            
                            self.dateLabel.text = "\(self.moods.count) checkins"
                            self.ratingLabel.text = "Average mood:"
                            self.commentLabel.text = "\(self.moodAverage)"
                        } else {
                            self.dateLabel.text = "\(self.moods.count) checkins"
                            self.ratingLabel.text = "Not enough moods to calculate average"
                            self.commentLabel.text = "Tell me how you feel."
                        }
                    }
                }
            } else {
                var alert = UIAlertController(title: "Whoops!", message: "We're having some trouble finding your moods. Check back later.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            self.activityIndicator.stopAnimating()
            self.activityIndicator.alpha = 0
        }
    }

    
    // Set up BEM line graph
    
    func beautifyGraph(){

        self.chartView.enableBezierCurve = true
        self.chartView.animationGraphStyle = BEMLineAnimation.Draw
        
        self.chartView.displayDotsWhileAnimating = true
        self.chartView.alwaysDisplayDots = true
        self.chartView.sizePoint = 10
        
        self.chartView.averageLine.enableAverageLine = true
        self.chartView.averageLine.alpha = 0.5
        self.chartView.averageLine.width = 1
        
        self.chartView.enableTopReferenceAxisFrameLine = true
        
        self.chartView.enableXAxisLabel = true
        self.chartView.colorXaxisLabel = UIColor.wetAsphaltColor()
        
        self.chartView.colorTouchInputLine = UIColor.wetAsphaltColor()
        
        self.chartView.noDataLabelColor = UIColor.whiteColor()
        self.chartView.noDataLabelFont = UIFont (name: "Avenir Book", size: 18)!
        
        self.chartView.enableTouchReport = true
    }
    
    
    // If no data points available, show a prompt to add a mood
    
    func noDataLabelTextForLineGraph(graph: BEMSimpleLineGraphView) -> String {
        return "Add a mood to get started."
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView, didTouchGraphWithClosestIndex index: Int) {
        
        var mood = self.moods[index]
        
        var date = mood.createdAt!
        var rating = mood["rating"] as? CGFloat
        var comment = mood["comment"] as? String
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = .ShortStyle
        
        let dateString = formatter.stringFromDate(date)
        
        dateLabel.text = dateString
        ratingLabel.text = "Rating: \(rating!)"
        commentLabel.text = comment
    }
    
    
    func lineGraph(graph: BEMSimpleLineGraphView, didReleaseTouchFromGraphWithClosestIndex index: CGFloat) {
        
        self.dateLabel.text = "\(self.moods.count) checkins"
        self.ratingLabel.text = "Average mood:"
        self.commentLabel.text = "\(self.moodAverage)"
    }
    
    
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return self.moods.count
    }
    
    
    func lineGraph(graph: BEMSimpleLineGraphView, valueForPointAtIndex index: Int) -> CGFloat {
        return self.moods[index]["rating"] as! CGFloat
    }
    
    
    func lineGraph(graph: BEMSimpleLineGraphView, labelOnXAxisForIndex index: Int) -> String {
        var mood = self.moods[index]
        var date = mood.createdAt!
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        formatter.timeStyle = .ShortStyle
        
        let dateString = formatter.stringFromDate(date)
        
        return dateString
    }
    

    func numberOfGapsBetweenLabelsOnLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return 1
    }
    
    
    func minValueForLineGraph(graph: BEMSimpleLineGraphView) -> CGFloat {
        return 1
    }
    
    
    func maxValueForLineGraph(graph: BEMSimpleLineGraphView) -> CGFloat {
        return 10
    }

}