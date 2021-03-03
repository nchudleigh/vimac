//
//  AboutPreferencesViewController.swift
//  Vimac
//
//  Created by Dexter Leng on 3/3/21.
//  Copyright © 2021 Dexter Leng. All rights reserved.
//

import Cocoa
import Preferences

class AboutPreferencesViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = Preferences.PaneIdentifier.about
    let preferencePaneTitle = "About"
    let toolbarItemIcon: NSImage
    
    init() {
        if #available(OSX 11.0, *) {
            self.toolbarItemIcon = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)!
        } else {
            self.toolbarItemIcon = NSImage(named: NSImage.infoName)!
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidLoad() {
        let iconImage = NSApp.applicationIconImage!
        iconImage.size = .init(width: 80, height: 80)
        let iconView = NSImageView(image: iconImage)
        
        let appNameLabel = NSTextField(labelWithString: "Vimac")
        appNameLabel.font = .boldSystemFont(ofSize: 18)

        let shortBundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        let versionLabel = NSTextField(labelWithString: "Version \(shortBundleVersion) (\(bundleVersion))")
        versionLabel.font = .labelFont(ofSize: 13)
        versionLabel.textColor = .secondaryLabelColor

        let copyrightNoticeLabel = NSTextField(labelWithString: "Copyright © 2021 Dexter Leng.")
        copyrightNoticeLabel.font = .labelFont(ofSize: 11)
        copyrightNoticeLabel.textColor = .secondaryLabelColor
        
        let descriptionStackView = NSStackView(views: [
            appNameLabel,
            versionLabel,
            copyrightNoticeLabel
        ])
        descriptionStackView.alignment = .leading
        descriptionStackView.orientation = .vertical
        
        let stackView = NSStackView(views: [
            iconView,
            descriptionStackView
        ])
        stackView.orientation = .horizontal
        stackView.spacing = 40
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 600),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
