import SwiftUI
import MapKit
import CoreLocation

struct LocationMapView: UIViewRepresentable {
    let location: CLLocation

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = true
        mapView.showsUserLocation = false
        mapView.mapType = .standard

        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "スキャン地点"
        annotation.subtitle = "動物痕跡の発見場所"
        mapView.addAnnotation(annotation)

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "スキャン地点"
        annotation.subtitle = "動物痕跡の発見場所"

        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotation(annotation)

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
        uiView.setRegion(region, animated: true)
    }
}

