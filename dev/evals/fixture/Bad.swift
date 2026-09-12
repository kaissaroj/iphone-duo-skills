import UIKit
class VC: UIViewController {
    override func viewDidLoad() {
        let w = UIScreen.main.bounds.width
        let scale = UIScreen.main.scale
        if UIDevice.current.orientation.isLandscape { }
        if UIDevice.current.userInterfaceIdiom == .pad { }
        let width = view.bounds.width - view.safeAreaInsets.left * 2
        let toolbar = UIToolbar()
        let item = UIBarButtonItem(image: UIImage(systemName: "square"), style: .plain, target: nil, action: nil)
        let more = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: nil)
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        card.center = view.center
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
