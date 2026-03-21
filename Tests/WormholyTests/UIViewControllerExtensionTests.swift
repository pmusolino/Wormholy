import XCTest
@testable import WormholySwift

final class UIViewControllerExtensionTests: XCTestCase {
    func testCurrentViewControllerPrefersPresentedViewController() {
        let presented = UIViewController()
        let root = PresentedStubViewController(presentedViewController: presented)

        let current = UIViewController.currentViewController(from: root)

        XCTAssert(current === presented)
    }

    func testCurrentViewControllerReturnsVisibleNavigationControllerViewController() {
        let first = UIViewController()
        let second = UIViewController()
        let navigationController = UINavigationController(rootViewController: first)
        navigationController.setViewControllers([first, second], animated: false)

        let current = UIViewController.currentViewController(from: navigationController)

        XCTAssert(current === second)
    }

    func testCurrentViewControllerReturnsSelectedTabViewController() {
        let first = UIViewController()
        let second = UIViewController()
        let tabBarController = UITabBarController()
        tabBarController.setViewControllers([first, second], animated: false)
        tabBarController.selectedIndex = 1

        let current = UIViewController.currentViewController(from: tabBarController)

        XCTAssert(current === second)
    }

    func testCurrentViewControllerTraversesChildViewControllers() {
        let child = UIViewController()
        let container = UIViewController()
        container.addChild(child)
        child.didMove(toParent: container)

        let current = UIViewController.currentViewController(from: container)

        XCTAssert(current === child)
    }
}

private final class PresentedStubViewController: UIViewController {
    private let stubPresentedViewController: UIViewController?

    init(presentedViewController: UIViewController?) {
        self.stubPresentedViewController = presentedViewController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var presentedViewController: UIViewController? {
        stubPresentedViewController
    }
}