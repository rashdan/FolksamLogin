//
//  LoginViewController.swift
//  FolksamApp
//
//  Created by Johan Torell on 2021-01-28.
//

import FolksamCore
import FolksamCommon
import UIKit
import Foundation

public protocol LoginDelegate: AnyObject {
    func loginViewController(loginSuccessful: Bool)
}

public class LoginViewController: UIViewController {
    @IBOutlet var folksamLogo: UIImageView!
    @IBOutlet var logoWidth: NSLayoutConstraint!
    @IBOutlet var logoCenterY: NSLayoutConstraint!
    @IBOutlet var buttonBottomSafeArea: NSLayoutConstraint!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    @IBOutlet var pnrTextField: UITextField!
    @IBOutlet var bankidButton: FolksamButton!

    /// services
    private var apiService: LoginServiceProtocol!

    /// delegate
    // swiftlint:disable weak_delegate
    // delegate cant be weak with a factory method?
    private var mainAppDelegate: LoginDelegate!
    // swiftlint:enable weak_delegate

    override public func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()

        // move button out of sight
        buttonBottomSafeArea.constant = 1000

        // call the 'keyboardWillShow' function when the view controller receive the notification that a keyboard is going to be shown
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)

        // call the 'keyboardWillHide' function when the view controlelr receive notification that keyboard is going to be hidden
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // delegate cant be weak var with a factory method?
    // need to manually deinit?
    deinit {
        mainAppDelegate = nil

        // remove teh keyboard listerners
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bankidButton.enable = false
        UIView.animate(withDuration: 1, delay: 0.5, usingSpringWithDamping: 1, initialSpringVelocity: 2, options: .curveEaseInOut, animations: { [weak self] in
            if let self = self {
                self.logoWidth.constant = 200
                self.logoCenterY.constant = -250
                self.buttonBottomSafeArea.constant = 300
                self.view.layoutIfNeeded()
            }
        }, completion: nil)
    }

    public static func make(apiService: LoginServiceProtocol, mainAppDelegate: LoginDelegate) -> LoginViewController {
        guard let viewController = UIStoryboard(name: "Login", bundle: Bundle.module).instantiateInitialViewController() as? LoginViewController else { fatalError() }
        viewController.apiService = apiService
        viewController.mainAppDelegate = mainAppDelegate
        return viewController
    }

    @IBAction func pnrChanged(_: Any) {
        if let pnr = pnrTextField.text {
            if case SwedishSSN.personnummer = SwedishSSN(pnr) {
                DispatchQueue.main.async {
                    self.bankidButton.enable = true
                }
            } else {
                DispatchQueue.main.async {
                    self.bankidButton.enable = false
                }
            }
        }
    }

    @IBAction func loginAction(_: Any) {
        if let pnr = pnrTextField.text {
            pnrTextField.endEditing(true)
            loadingView.alpha = 1
            apiService.startBankID(pnr: pnr) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .failure(error):
                    // TODO: show error message
                    print(error.localizedDescription)
                    self.loadingView.alpha = 0
                case let .success(success):
                    // TODO: handle false success
                    self.mainAppDelegate.loginViewController(loginSuccessful: success)
                }
            }
        }
    }
}

// MARK: - Keyboard

extension LoginViewController {
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            // if keyboard size is not available for some reason, dont do anything
            return
        }

        // move the root view up by the distance of keyboard height
        view.frame.origin.y = 0 - (keyboardSize.height)
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        // move back the root view origin to zero
        view.frame.origin.y = 0
    }
}

// Put this piece of code anywhere you like
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = true
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
