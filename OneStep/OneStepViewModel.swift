import Foundation
import Combine
import UIKit
import CoreLocation
import SwiftUI


class OneStepViewModel: NSObject, OneStepViewModelProtocol {
    @Published private(set) var photos: [UIImage] = []
    @Published private(set) var buttonText: String = "Start"

    private let currentAuthorizationStatus = PassthroughSubject<CLAuthorizationStatus, Never>()
    private let buttonActionPublisher = PassthroughSubject<Void, Never>()
    private let recentLocation = PassthroughSubject<CLLocation, Never>()
    private let locationManager = CLLocationManager()
    
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        
        currentAuthorizationStatus
            .combineLatest(buttonActionPublisher)
            .map(\.0)
            .sink { [weak self] status in
                switch status {
                    case .notDetermined, .restricted, .denied, .authorizedWhenInUse:
                        self?.locationManager.requestAlwaysAuthorization()
                    case .authorizedAlways:
                        if self?.buttonText == "Stop" {
                            self?.buttonText = "Start"
                            self?.locationManager.stopUpdatingLocation()
                        } else {
                            self?.buttonText = "Stop"
                            self?.locationManager.startUpdatingLocation()
                        }
                    @unknown default:
                        return
                }
            }
            .store(in: &cancellables)
        
        recentLocation
            .scan(CLLocation()) { last, next in
                last.distance(from: next) > 100 ? next : last
            }
            .removeDuplicates()
            .map(\.coordinate)
            .flatMap(URLSession.shared.getPhoto)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] image in
                guard let image = image else { return }
                self?.photos.insert(image, at: 0)
            })
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: .endFetching, object: nil)
            .sink { [weak self] _ in
                self?.buttonText = "Start"
                self?.locationManager.stopUpdatingLocation()
            }
            .store(in: &cancellables)
    }
    
    func buttonAction() {
        buttonActionPublisher.send()
    }
}

extension OneStepViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        currentAuthorizationStatus.send(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.last.map(recentLocation.send)
    }
}
