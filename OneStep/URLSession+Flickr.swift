import Foundation
import UIKit
import Combine
import CoreLocation

extension URLSession {
    func getPhotos(coordinates: CLLocationCoordinate2D) -> AnyPublisher<FlickrResponse?, Never> {
        guard let photosUrl = URL.getPhotosUrl(coordinates: coordinates) else {
            return CurrentValueSubject(nil).eraseToAnyPublisher()
        }
        
        return dataTaskPublisher(for: photosUrl)
            .map(\.data)
            .decode(type: Optional<FlickrResponse>.self, decoder: JSONDecoder())
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    func getPhoto(at coordinates: CLLocationCoordinate2D) -> AnyPublisher<UIImage?, Never> {
        getPhotos(coordinates: coordinates)
            .compactMap(\.?.photos.photo.last)
            .compactMap(URL.photoUrl)
            .flatMap(dataTaskPublisher)
            .map(\.data)
            .map(UIImage.init)
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}

private extension URL {
    static func photoUrl(photo: Photo) -> URL? {
        .init(string: "https://live.staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_b.jpg")
    }
    
    static func getPhotosUrl(coordinates: CLLocationCoordinate2D) -> URL? {
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search"
        + "&api_key=\(Constants.apiKey)"
        + "&lat=\(coordinates.latitude)"
        + "&lon=\(coordinates.longitude)&format=json&radius=0.03&nojsoncallback=1"
        
        return .init(string: urlString)
    }
}
