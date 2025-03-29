import SwiftUI

struct NewClientView: View {
    @Binding var isPresented: Bool
    var onSave: (Client) -> Void
    
    @StateObject private var clientManager = ClientManager.shared
    @State private var name = ""
    @State private var legalName = ""
    @State private var rfc = ""
    @State private var contactPerson = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información básica")) {
                    TextField("Nombre del cliente", text: $name)
                    TextField("Razón social", text: $legalName)
                    TextField("RFC", text: $rfc)
                        .autocapitalization(.allCharacters)
                    TextField("Persona de contacto", text: $contactPerson)
                }
                
                Section(header: Text("Información de contacto")) {
                    TextField("Correo electrónico", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Teléfono", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("Dirección", text: $address)
                }
                
                Section(header: Text("Notas adicionales")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Nuevo Cliente")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    isPresented = false
                },
                trailing: Button("Guardar") {
                    let newClient = Client(
                        name: name,
                        legalName: legalName,
                        rfc: rfc,
                        contactPerson: contactPerson,
                        email: email,
                        phone: phone,
                        address: address,
                        notes: notes
                    )
                    
                    // Pasar el cliente a la función onSave proporcionada
                    onSave(newClient)
                    
                    isPresented = false
                }
                .disabled(name.isEmpty)
            )
        }
    }
}

#Preview {
    NewClientView(isPresented: .constant(true), onSave: { _ in })
} 