//
//  GIFDetailToolView.swift
//  notGIF
//
//  Created by Atuooo on 19/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

protocol GIFDetailToolViewDelegate: class {
    func changePlaySpeed(_ speed: TimeInterval)
    func changePlayState(playing: Bool)
    func removeTagOrGIF()
    func showAllFrame()
    func shareTo(_ type: GIFActionType.ShareType)
    func addTag()
}

class GIFDetailToolView: UIView {
    
    enum ToolActionType: Int {
        case remove
        case addTag
        case share
        case showAllFrame
        case max
    }
    
    weak fileprivate var delegate: GIFDetailToolViewDelegate?
    fileprivate let height: CGFloat = 86
    fileprivate let maxSpeed: TimeInterval = 0.005
    fileprivate let minSpeed: TimeInterval = 0.50

    fileprivate var isInDefaultTag: Bool {
        return NGUserDefaults.lastSelectTagID == Config.defaultTagID
    }
    
    fileprivate var originSpeed: TimeInterval = 1
    
    fileprivate var currentSpeed: TimeInterval = 0.005 {
        didSet {
            let multiple = currentSpeed/originSpeed
            let speedInfo = String(format: "%.1fx\n%.3fs", multiple, currentSpeed)
            speedLabel.text = speedInfo
        }
    }
    
    fileprivate lazy var playButton: PlayControlButton = {
        return PlayControlButton(showPlay: false, outerDia: 22) { [weak self] isPaused in
            self?.delegate?.changePlayState(playing: !isPaused)
        }
    }()
    
    fileprivate lazy var speedLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.textTint
        label.font = UIFont.menlo(ofSize: 14)
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    fileprivate lazy var speedSlider: UISlider = {
        let slider = UISlider()
        slider.thumbTintColor = UIColor.textTint
        slider.tintColor = UIColor.textTint
        slider.maximumValue = 0.50
        slider.minimumValue = 0.005
        slider.minimumTrackTintColor = UIColor.textTint.withAlphaComponent(0.7)
        slider.maximumTrackTintColor = UIColor.textTint.withAlphaComponent(0.7)
        slider.setThumbImage(#imageLiteral(resourceName: "icon_slider_thumb"), for: .normal)
        slider.setThumbImage(#imageLiteral(resourceName: "icon_slider_thumb"), for: .highlighted)
        slider.setThumbImage(#imageLiteral(resourceName: "icon_slider_thumb"), for: .selected)
        slider.addTarget(self, action: #selector(GIFDetailToolView.sliderValueChanged(sender:)), for: .valueChanged)
        return slider
    }()
    
    fileprivate lazy var shareBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.barTint
        return view
    }()
    
    init(delegate: GIFDetailToolViewDelegate) {
        super.init(frame: CGRect(x: 0, y: kScreenHeight, width: kScreenWidth, height: height))
        makeUI()
        self.delegate = delegate
    }
    
    deinit {
        printLog("deinited")
    }
    
    // MARK: - Public Action
    func reset(withSpeed speed: TimeInterval) {
        playButton.setPlayState(playing: true)
        
        if speed <= 0 {
            speedLabel.text = "..."

        } else {
            originSpeed = speed
            currentSpeed = originSpeed
            speedSlider.setValue(Float(speed), animated: true)
        }
    }
    
    // MARK: - Control Handler
    
    func toolButtonClicked(button: UIButton) {
        guard let actionType = ToolActionType(rawValue: button.tag) else { return }
        
        switch actionType {
        case .addTag:
            delegate?.addTag()
        case .remove:
            delegate?.removeTagOrGIF()
        case .showAllFrame:
            delegate?.showAllFrame()
        case .share:
            showShareBar()
        default:
            break
        }
    }
    
    func shareButtonClicked(button: UIButton) {
        guard let shareType = GIFActionType.ShareType(rawValue: button.tag) else { return }
        delegate?.shareTo(shareType)
    }
    
    func hideShareBarButtonClicked() {
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: -0.2, options: [.curveEaseInOut], animations: {
            self.shareBar.transform = CGAffineTransform(translationX: 0, y: self.height)
        }, completion: nil)
    }
    
    func sliderValueChanged(sender: UISlider) {
        currentSpeed = TimeInterval(sender.value)
        delegate?.changePlaySpeed(currentSpeed)
    }
    
    // MARK: - Helper Methods
    
    fileprivate func makeUI() {
        let sliderH: CGFloat = height * 0.4
        backgroundColor = UIColor.barTint
        
        // tool buttons
        let toolButtonStackView = UIStackView()
        toolButtonStackView.distribution = .fillEqually
        
        for i in 0..<ToolActionType.max.rawValue {
            guard let actionType = ToolActionType(rawValue: i) else { return }
            let toolButton = UIButton()
            
            switch actionType {
            case .remove:
                toolButton.setImage(isInDefaultTag ? #imageLiteral(resourceName: "icon_delete_gif") : #imageLiteral(resourceName: "icon_remove_tag"), for: .normal)
            case .addTag:
                toolButton.setImage(#imageLiteral(resourceName: "icon_add_tag"), for: .normal)
            case .share:
                toolButton.setAwesomeIcon(iconCode: .share, color: UIColor.textTint, fontSize: 22)
            case .showAllFrame:
                toolButton.setImage(#imageLiteral(resourceName: "icon_show_frame"), for: .normal)
            default:
                break
            }
            
            toolButton.tag = i
            toolButton.tintColor = UIColor.textTint
            toolButton.addTarget(self, action: #selector(GIFDetailToolView.toolButtonClicked(button:)), for: .touchUpInside)
            
            toolButtonStackView.addArrangedSubview(toolButton)
        }
        
        addSubview(toolButtonStackView)
        toolButtonStackView.snp.makeConstraints { make in
            make.bottom.equalTo(0)
            make.centerX.equalTo(self)
            make.width.equalTo(kScreenWidth*0.8)
            make.height.equalTo(height-sliderH)
        }
        
        playButton.center = CGPoint(x: kScreenWidth*0.1, y: sliderH*0.66)
        addSubview(playButton)
        
        addSubview(speedLabel)
        speedLabel.text = "0.38s"
        speedLabel.snp.makeConstraints { make in
            make.right.equalTo(0)
            make.centerY.equalTo(playButton)
            make.width.equalTo(kScreenWidth*0.2)
        }
        
        addSubview(speedSlider)
        speedSlider.snp.makeConstraints { make in
            make.width.equalTo(kScreenWidth * 0.6)
            make.centerX.equalTo(self)
            make.centerY.equalTo(playButton)
        }
    }
    
    fileprivate func setShareBar() {
        var shareTypes: [GIFActionType.ShareType] = [.more, .twitter, .weibo, .wechat, .message]
        if !OpenShare.canOpen(.wechat) {
            shareTypes.remove(.wechat)
        }
        
        let hideButton = UIButton(type: .system)
        hideButton.setImage(#imageLiteral(resourceName: "icon_slide_down"), for: .normal)
        hideButton.tintColor = UIColor.textTint.withAlphaComponent(0.8)
        hideButton.addTarget(self, action: #selector(GIFDetailToolView.hideShareBarButtonClicked), for: [.touchUpInside])
        
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        
        for item in shareTypes {
            let button = UIButton(iconCode: item.iconCode, color: UIColor.textTint, fontSize: 30)
            button.tag = item.rawValue
            button.backgroundColor = UIColor.barTint
            
            button.addTarget(self, action: #selector(GIFDetailToolView.shareButtonClicked(button:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
        
        shareBar.addSubview(hideButton)
        shareBar.addSubview(stackView)
        addSubview(shareBar)
        
        hideButton.snp.makeConstraints { make in
            make.right.left.top.equalTo(shareBar)
            make.height.equalTo(30)
        }
        
        stackView.snp.makeConstraints { make in
            make.right.left.equalTo(shareBar)
            make.height.equalTo(height*0.5)
            make.bottom.equalTo(-height*0.2)
        }
        
        shareBar.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    fileprivate func showShareBar() {
        if !shareBar.isDescendant(of: self) {
            shareBar.transform = CGAffineTransform(translationX: 0, y: height)
            setShareBar()
        }
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.6, options: [], animations: {
            self.shareBar.transform = .identity
        }, completion: nil)
    }
    
    // MARK: - Animation
    public func animate() {
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 2, options: [.curveEaseInOut], animations: {
            self.frame.origin.y = kScreenHeight - self.height

        }, completion: nil)
    }
    
    public func setHidden(_ shouldHide: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.frame.origin.y = shouldHide ? kScreenHeight : kScreenHeight - self.height
            })
        } else {
            frame.origin.y = shouldHide ? kScreenHeight : kScreenHeight - height
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
