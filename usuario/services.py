from usuario.repositories import UsuarioRepository
from usuario.models import Usuario # 💡 Necesario para crear/cifrar
from rest_framework_simplejwt.tokens import RefreshToken 
from django.contrib.auth.hashers import make_password # Para cifrar contraseñas

class UsuarioService:
    
    # --- Lógica de Autenticación y Tokens ---
    
    @staticmethod
    def generar_tokens_para_usuario(user):
        refresh = RefreshToken.for_user(user)
        return {
            'access': str(refresh.access_token), #  Nombrar como 'access' (estándar JWT)
            'refresh': str(refresh)              #  Nombrar como 'refresh' (estándar JWT)
        }
        
    @staticmethod
    def autenticar_usuario(email: str, password: str):
        try:
            user = Usuario.objects.get(email=email)
        except Usuario.DoesNotExist:
            raise ValueError("Credenciales inválidas.")

        # Verificar contraseña
        if not user.check_password(password):
            raise ValueError("Credenciales inválidas.")
        
        #  Aquí va lógica de negocio adicional (ej. Verificar intentos de login fallidos)

        tokens = UsuarioService.generar_tokens_para_usuario(user)

        return {
            'user_id': user.id,
            **tokens,
            'username': user.get_first_name()
        }
    
    # --- CRUD de Usuarios ---

    @staticmethod
    def obtener_usuario(id):
        # El repositorio ya devuelve None si no encuentra, lo cual es correcto aquí.
        return UsuarioRepository.obtener_por_id(id) 
    
    @staticmethod
    def listar_usuarios():
        return UsuarioRepository.listar()
    
    @staticmethod
    def crear_usuario(datos):
        #  Lógica de Negocio (Validaciones)
        if 'email' not in datos or 'password' not in datos:
            raise ValueError("Email y contraseña son obligatorios")
        
        #  Verificar si el email ya existe (el campo 'unique=True' lo hará en la BD, 
        # pero es mejor validarlo antes de guardar para un mejor mensaje de error)
        if Usuario.objects.filter(email=datos['email']).exists():
            raise ValueError("El email ya está registrado.")
        
        # 1.  Crear la instancia y cifrar
        usuario = Usuario(
            username=datos.get('username'),
            email=datos.get('email'),
            dni=datos.get('dni'),
            password=make_password(datos['password']),
        )
        # 2.  Guardar en la base de datos (ya cifrado)
        usuario.save()
        return usuario

    @staticmethod
    def actualizar_usuario(id, datos):
        # Lógica de Servicio: Si actualizan la contraseña, debe ser cifrada.
        if 'password' in datos:
            # NOTA: Esto solo funcionará si UsuarioRepository.actualizar está adaptado
            # para no sobrescribir el campo de password. 
            # Es mejor manejar el password en un servicio separado.
            pass # Lógica compleja, se maneja aparte.

        return UsuarioRepository.actualizar(id, datos)

    @staticmethod
    def eliminar_usuario(id):
        return UsuarioRepository.eliminar(id)