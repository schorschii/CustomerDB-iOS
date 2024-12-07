//
//  AppointmentViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class AppointmentViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var imageLogo: UIImageView!
    @IBOutlet weak var viewAppointments: UIView!
    @IBOutlet weak var scrollViewAppointments: UIScrollView!
    @IBOutlet weak var buttonAdd: UIButton!
    @IBOutlet weak var calendarChooser: UIDatePicker!
    
    let mDb = CustomerDatabase()
    var mShowCalendars:[CustomerCalendar] = []
    var mAppointments:[CustomerAppointment] = []
    var mCurrentDate = Date()
    
    var mMainViewControllerRef:MainViewController? = nil
    
    static func timeToDisplayString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollViewAppointments.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        calendarChooser.contentHorizontalAlignment = .center
        drawEvents()
        initColor()
    }
    
    override func viewDidLayoutSubviews() {
        scrollViewAppointments.contentOffset.y = CGFloat(UserDefaults.standard.float(forKey: "calendar-day-scroll"))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(UIScrollViewDelegate.scrollViewDidEndScrollingAnimation), with: nil, afterDelay: 0.3)
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        UserDefaults.standard.set(scrollViewAppointments.contentOffset.y, forKey: "calendar-day-scroll")
    }
    
    func initColor() {
        buttonAdd.backgroundColor = navigationController?.navigationBar.barTintColor
        
        if(UserDefaults.standard.bool(forKey: "unlocked-do")) {
            if let image = GuiHelper.loadImage(file: SettingsViewController.getLogoFile()) {
                imageLogo.contentMode = .scaleAspectFit
                imageLogo.image = image
                imageLogo.alpha = 0.2
            } else {
                imageLogo.image = UIImage(named: "icon_gray")
                imageLogo.alpha = 0.05
            }
        }
    }
    
    
    @IBAction func onClickAdd(_ sender: UIButton) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: "AppointmentEditNavigationViewController") as! UINavigationController
        if let vdvc = detailViewController.viewControllers.first as? AppointmentEditViewController {
            vdvc.mDefaultDate = mCurrentDate
        }
        splitViewController?.showDetailViewController(detailViewController, sender: nil)
    }
    @IBAction func onChangeDay(_ sender: UIDatePicker) {
        mCurrentDate = sender.date
        drawEvents()
    }
    @IBAction func onClickDayPrev(_ sender: UIButton) {
        mCurrentDate = Calendar.current.date(byAdding: .day, value: -1, to: mCurrentDate) ?? Date()
        calendarChooser.date = mCurrentDate
        drawEvents()
    }
    @IBAction func onClickDayNext(_ sender: UIButton) {
        mCurrentDate = Calendar.current.date(byAdding: .day, value: 1, to: mCurrentDate) ?? Date()
        calendarChooser.date = mCurrentDate
        drawEvents()
    }
    
    func drawEvents() {
        // clear old entries
        mAppointments.removeAll()
        for view in viewAppointments.subviews {
            if let appointmentView = view as? CalendarAppointmentView {
                appointmentView.removeFromSuperview()
            }
        }
        
        // add new entries
        for c in mDb.getCalendars(showDeleted: false) {
            for a in mDb.getAppointments(calendarId: c.mId, day: mCurrentDate, showDeleted: false) {
                a.mColor = c.mColor
                mAppointments.append(a)
            }
        }
        
        // draw entries
        if(mAppointments.count > 0) {
            mAppointments = mAppointments.sorted(by: {
                let change1 = $0.getStartTimeInMinutes()
                let change2 = $1.getStartTimeInMinutes()
                if(change1 == change2) {
                    let change3 = $0.getEndTimeInMinutes()
                    let change4 = $1.getEndTimeInMinutes()
                    return change3 < change4
                } else {
                    return change1 < change2
                }
            })
            let screenWidth = viewAppointments.frame.size.width
            let screenHeight = viewAppointments.frame.size.height
            
            let clusters:[Cluster] = createClusters(cliques: createCliques(appointments: mAppointments))
            for c in clusters {
                for a in c.getAppointments() {
                    let itemWidth = screenWidth / CGFloat(c.getMaxCliqueSize())
                    let leftMargin = itemWidth * CGFloat(c.getNextPosition())
                    let itemHeight = CGFloat(
                        max(minutesToPixels(screenHeight: Int(screenHeight), minutes: a.getEndTimeInMinutes()) - minutesToPixels(screenHeight: Int(screenHeight), minutes: a.getStartTimeInMinutes()), 10)
                    )
                    let topMargin = CGFloat(
                        minutesToPixels(screenHeight: Int(screenHeight), minutes: a.getStartTimeInMinutes())
                    )
                    
                    var color = UIColor.lightGray
                    color = UIColor(hex: a.mColor)
                    
                    let appointmentView = CalendarAppointmentView()
                    appointmentView.addTarget(self, action: #selector(onAppointmentClicked(_:)), for: .touchUpInside)
                    appointmentView.frame = CGRect(
                        origin: CGPoint(x: leftMargin, y: topMargin),
                        size: CGSize(width: itemWidth, height: itemHeight)
                    )

                    viewAppointments.addSubview(appointmentView)
                    var customerText = ""
                    if(a.mCustomerId != nil) {
                        if let c = mDb.getCustomer(id: a.mCustomerId!, showDeleted: false) {
                            customerText = c.getFullName(lastNameFirst: false)
                        }
                    } else {
                        customerText = a.mCustomer
                    }
                    appointmentView.setValues(
                        appointment: a,
                        text: a.mTitle,
                        subtitle: (customerText+"  "+a.mLocation).trimmingCharacters(in: .whitespacesAndNewlines),
                        time: AppointmentViewController.timeToDisplayString(date: a.mTimeStart!)+" - "+AppointmentViewController.timeToDisplayString(date: a.mTimeEnd!),
                        backgroundColor: color
                    )
                }
            }
        }
    }
    
    @objc func onAppointmentClicked(_ sender: Any) {
        if let appointmentView = sender as? CalendarAppointmentView {
            let detailViewController = storyboard?.instantiateViewController(withIdentifier:"AppointmentEditNavigationViewController") as! UINavigationController
            if let vdvc = detailViewController.viewControllers.first as? AppointmentEditViewController {
                vdvc.mCurrentAppointment = appointmentView.mAppointment!
            }
            splitViewController?.showDetailViewController(detailViewController, sender: nil)
        }
    }
    
    static var MINUTES_IN_A_HOUR = 24 * 60
    func minutesToPixels(screenHeight:Int, minutes:Int) -> Int {
        return (screenHeight * minutes) / AppointmentViewController.MINUTES_IN_A_HOUR
    }

    func createCliques(appointments:[CustomerAppointment]) -> [Clique] {
        let startTime = appointments[0].getStartTimeInMinutes()
        let endTime = appointments[appointments.count - 1].getEndTimeInMinutes()

        var cliques:[Clique] = []

        for i in startTime..<endTime {
            var c:Clique? = nil
            for a in appointments {
                if(a.getStartTimeInMinutes() < i && a.getEndTimeInMinutes() > i) {
                    if(c == nil) {
                        c = Clique()
                    }
                    c!.addAppointment(a)
                }
            }
            if(c != nil) {
                if(!cliques.contains(c!)) {
                    cliques.append(c!)
                }
            }
        }
        return cliques
    }

    func createClusters(cliques:[Clique]) -> [Cluster] {
        var clusters:[Cluster] = []
        var cluster:Cluster? = nil
        for c in cliques {
            if(cluster == nil) {
                cluster = Cluster()
                cluster!.addClique(c)
            } else {
                if(cluster!.getLastClique()!.intersects(c)) {
                    cluster!.addClique(c)
                } else {
                    clusters.append(cluster!)
                    cluster = Cluster()
                    cluster!.addClique(c)
                }
            }
        }
        if(cluster != nil) {
            clusters.append(cluster!)
        }
        return clusters
    }
    
    class Clique : Equatable {
        var mAppointments:[CustomerAppointment] = []

        func getAppointments() -> [CustomerAppointment] {
            return mAppointments
        }

        func addAppointment(_ a: CustomerAppointment) {
            mAppointments.append(a)
        }

        func intersects(_ clique2: Clique) -> Bool {
            for i in mAppointments {
                for k in clique2.mAppointments {
                    if i === k {
                        return true
                    }
                }
            }
            return false
        }
        
        static func ==(lhs: Clique, rhs: Clique) -> Bool {
            return lhs === rhs
        }
    }

    class Cluster {
        var cliques:[Clique] = []
        var maxCliqueSize = 1
        var nextCurrentDrawPosition = 0

        func addClique(_ c: Clique) {
            cliques.append(c)
            maxCliqueSize = max(maxCliqueSize, c.getAppointments().count)
        }

        func getMaxCliqueSize() -> Int {
            return maxCliqueSize
        }

        func getLastClique() -> Clique? {
            if(cliques.count > 0) {
                return cliques[cliques.count - 1]
            }
            return nil
        }

        func getAppointments() -> [CustomerAppointment] {
            var events:[CustomerAppointment] = []
            for clique in cliques {
                for a in clique.getAppointments() {
                    if(!events.contains(where: { $0.mId == a.mId })) {
                        events.append(a)
                    }
                }
            }
            return events
        }
        
        func getNextPosition() -> Int {
            var position = nextCurrentDrawPosition
            if(position >= maxCliqueSize) {
                position = 0
            }
            nextCurrentDrawPosition = position + 1
            return position
        }
    }
    
}

class CalendarAppointmentView : UIControl {
    var mAppointment : CustomerAppointment? = nil
    func setValues(appointment:CustomerAppointment, text:String, subtitle:String, time:String, backgroundColor:UIColor) {
        mAppointment = appointment
        
        self.alpha = 0.8
        self.clipsToBounds = true
        self.isUserInteractionEnabled = true
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = 6
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 1
        
        var primaryColor = UIColor.black
        if(backgroundColor.isDark()) {
            primaryColor = UIColor.white
        }
        var secondaryColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 180/255)
        if(backgroundColor.isDark()) {
            secondaryColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 180/255)
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = false
        
        let labelTitle = UILabel()
        labelTitle.text = text
        labelTitle.textColor = primaryColor
        stackView.addArrangedSubview(labelTitle)
        
        let labelSubtitle = UILabel()
        labelSubtitle.text = subtitle
        labelSubtitle.textColor = secondaryColor
        stackView.addArrangedSubview(labelSubtitle)
        
        let labelTime = UILabel()
        labelTime.text = time
        labelTime.textColor = secondaryColor
        labelTime.font = CTFontCreateUIFontForLanguage(.label, 11, nil)
        stackView.addArrangedSubview(labelTime)
        
        self.addSubview(stackView)
        stackView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 4).isActive = true
        stackView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 4).isActive = true
        stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 4).isActive = true
    }
}
