import SwiftUI

struct HomeOutletView: View {
    
    var outlet: HomeOutlet
    
    var body: some View {
        GridRow {
            Button(outlet.accessory.name) {
                outlet.isOn.toggle()
            }
            .buttonStyle(FlexButtonStyle(isSelected: outlet.isOn))
        }
    }
}
