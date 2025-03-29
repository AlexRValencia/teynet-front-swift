import SwiftUI

struct UserFormView: View {
    @ObservedObject var viewModel: UserAdminViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case username, fullName, password, confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información del usuario")) {
                    // Nombre de usuario
                    TextField("Nombre de usuario", text: $viewModel.formUsername)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .fullName
                        }
                    
                    // Nombre completo
                    TextField("Nombre completo", text: $viewModel.formFullName)
                        .focused($focusedField, equals: .fullName)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                    
                    // Rol
                    Picker("Rol", selection: $viewModel.formRole) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.displayName).tag(role.rawValue)
                        }
                    }
                    
                    // Estado (activo/inactivo)
                    Toggle("Usuario activo", isOn: $viewModel.formStatus)
                }
                
                Section(header: Text("Contraseña")) {
                    // Contraseña
                    SecureField(viewModel.isEditMode ? "Nueva contraseña (opcional)" : "Contraseña", text: $viewModel.formPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .confirmPassword
                        }
                    
                    // Confirmar contraseña
                    SecureField("Confirmar contraseña", text: $viewModel.formConfirmPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                    
                    if viewModel.isEditMode {
                        Text("Deja en blanco para mantener la contraseña actual")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Mensaje de error
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
                
                // Botones de acción
                Section {
                    Button(action: viewModel.saveUser) {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(.white)
                                Text("Guardando...")
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text(viewModel.isEditMode ? "Actualizar usuario" : "Crear usuario")
                                    .bold()
                                Spacer()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                    .listRowBackground(Color.blue)
                    .foregroundColor(.white)
                    
                    Button("Cancelar", role: .cancel) {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                    .listRowBackground(Color(.systemGray6))
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Editar Usuario" : "Nuevo Usuario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .interactiveDismissDisabled(viewModel.isLoading)
            .onAppear {
                // Establecer el foco en el primer campo después de un breve retraso
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .username
                }
            }
        }
    }
}

#Preview {
    UserFormView(viewModel: UserAdminViewModel())
} 