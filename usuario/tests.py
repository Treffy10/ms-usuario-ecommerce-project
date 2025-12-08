from django.test import TestCase, Client
from django.urls import reverse
from django.contrib.auth.hashers import make_password
from usuario.models import Usuario
from usuario.services import UsuarioService
from usuario.repositories import UsuarioRepository
from rest_framework import status
import json


class UsuarioModelTests(TestCase):
    """Pruebas para el modelo Usuario"""
    
    def setUp(self):
        """Preparar datos para las pruebas"""
        self.usuario_data = {
            'email': 'test@example.com',
            'username': 'Test User',
            'dni': '12345678A'
        }
    
    def test_crear_usuario_con_manager(self):
        """Prueba que el manager cree un usuario correctamente"""
        usuario = Usuario.objects.create_user(
            email=self.usuario_data['email'],
            username=self.usuario_data['username'],
            dni=self.usuario_data['dni'],
            password='password123'
        )
        self.assertEqual(usuario.email, self.usuario_data['email'])
        self.assertEqual(usuario.username, self.usuario_data['username'])
        self.assertTrue(usuario.check_password('password123'))
    
    def test_email_debe_ser_unico(self):
        """Prueba que el email sea único"""
        Usuario.objects.create_user(
            email=self.usuario_data['email'],
            username=self.usuario_data['username'],
            dni=self.usuario_data['dni'],
            password='password123'
        )
        with self.assertRaises(Exception):
            Usuario.objects.create_user(
                email=self.usuario_data['email'],
                username='Otro User',
                dni='87654321B',
                password='password456'
            )
    
    def test_dni_debe_ser_unico(self):
        """Prueba que el DNI sea único"""
        Usuario.objects.create_user(
            email=self.usuario_data['email'],
            username=self.usuario_data['username'],
            dni=self.usuario_data['dni'],
            password='password123'
        )
        with self.assertRaises(Exception):
            Usuario.objects.create_user(
                email='otro@example.com',
                username='Otro User',
                dni=self.usuario_data['dni'],
                password='password456'
            )
    
    def test_get_first_name(self):
        """Prueba el método get_first_name"""
        usuario = Usuario.objects.create_user(
            email=self.usuario_data['email'],
            username='Juan Carlos Rodriguez',
            dni=self.usuario_data['dni'],
            password='password123'
        )
        self.assertEqual(usuario.get_first_name(), 'Juan')
    
    def test_crear_superuser(self):
        """Prueba la creación de un superusuario"""
        superuser = Usuario.objects.create_superuser(
            email='admin@example.com',
            username='Admin User',
            dni='99999999Z',
            password='adminpass123'
        )
        self.assertTrue(superuser.is_admin)
        self.assertTrue(superuser.is_active)


class UsuarioRepositoryTests(TestCase):
    """Pruebas para el repositorio de Usuario"""
    
    def setUp(self):
        """Crear usuarios de prueba"""
        self.usuario1 = Usuario.objects.create_user(
            email='user1@example.com',
            username='User One',
            dni='11111111A',
            password='password123'
        )
        self.usuario2 = Usuario.objects.create_user(
            email='user2@example.com',
            username='User Two',
            dni='22222222B',
            password='password456'
        )
    
    def test_listar_usuarios(self):
        """Prueba que se listen todos los usuarios"""
        usuarios = UsuarioRepository.listar()
        self.assertEqual(usuarios.count(), 2)
    
    def test_obtener_por_id(self):
        """Prueba obtener usuario por ID"""
        usuario = UsuarioRepository.obtener_por_id(self.usuario1.id)
        self.assertEqual(usuario.email, 'user1@example.com')
    
    def test_obtener_por_id_inexistente(self):
        """Prueba obtener usuario con ID inexistente"""
        usuario = UsuarioRepository.obtener_por_id(9999)
        self.assertIsNone(usuario)
    
    def test_actualizar_usuario(self):
        """Prueba actualizar datos del usuario"""
        datos_actualizados = {'username': 'User One Updated'}
        usuario = UsuarioRepository.actualizar(self.usuario1.id, datos_actualizados)
        self.assertEqual(usuario.username, 'User One Updated')
    
    def test_eliminar_usuario(self):
        """Prueba eliminar un usuario"""
        resultado = UsuarioRepository.eliminar(self.usuario1.id)
        self.assertTrue(resultado)
        self.assertIsNone(UsuarioRepository.obtener_por_id(self.usuario1.id))
    
    def test_eliminar_usuario_inexistente(self):
        """Prueba eliminar un usuario que no existe"""
        resultado = UsuarioRepository.eliminar(9999)
        self.assertFalse(resultado)


class UsuarioServiceTests(TestCase):
    """Pruebas para el servicio de Usuario"""
    
    def setUp(self):
        """Crear datos de prueba"""
        self.usuario = Usuario.objects.create_user(
            email='service@example.com',
            username='Service User',
            dni='33333333C',
            password='password123'
        )
    
    def test_autenticar_usuario_exitoso(self):
        """Prueba autenticación exitosa"""
        auth_data = UsuarioService.autenticar_usuario(
            'service@example.com',
            'password123'
        )
        self.assertIn('access', auth_data)
        self.assertIn('refresh', auth_data)
        self.assertEqual(auth_data['user_id'], self.usuario.id)
    
    def test_autenticar_usuario_password_incorrecto(self):
        """Prueba autenticación con contraseña incorrecta"""
        with self.assertRaises(ValueError) as context:
            UsuarioService.autenticar_usuario(
                'service@example.com',
                'passwordincorrecto'
            )
        self.assertEqual(str(context.exception), "Credenciales inválidas.")
    
    def test_autenticar_usuario_email_inexistente(self):
        """Prueba autenticación con email que no existe"""
        with self.assertRaises(ValueError) as context:
            UsuarioService.autenticar_usuario(
                'noexiste@example.com',
                'password123'
            )
        self.assertEqual(str(context.exception), "Credenciales inválidas.")
    
    def test_generar_tokens(self):
        """Prueba generación de tokens JWT"""
        tokens = UsuarioService.generar_tokens_para_usuario(self.usuario)
        self.assertIn('access', tokens)
        self.assertIn('refresh', tokens)
        self.assertIsNotNone(tokens['access'])
        self.assertIsNotNone(tokens['refresh'])
    
    def test_crear_usuario_exitoso(self):
        """Prueba crear un usuario correctamente"""
        datos = {
            'email': 'newuser@example.com',
            'username': 'New User',
            'dni': '44444444D',
            'password': 'newpass123'
        }
        usuario = UsuarioService.crear_usuario(datos)
        self.assertEqual(usuario.email, 'newuser@example.com')
        self.assertTrue(usuario.check_password('newpass123'))
    
    def test_crear_usuario_sin_email(self):
        """Prueba crear usuario sin email"""
        datos = {
            'username': 'No Email User',
            'dni': '55555555E',
            'password': 'password123'
        }
        with self.assertRaises(ValueError) as context:
            UsuarioService.crear_usuario(datos)
        self.assertIn("Email", str(context.exception))
    
    def test_crear_usuario_sin_password(self):
        """Prueba crear usuario sin contraseña"""
        datos = {
            'email': 'nopass@example.com',
            'username': 'No Pass User',
            'dni': '66666666F'
        }
        with self.assertRaises(ValueError) as context:
            UsuarioService.crear_usuario(datos)
        self.assertIn("contraseña", str(context.exception))
    
    def test_crear_usuario_email_duplicado(self):
        """Prueba crear usuario con email que ya existe"""
        datos = {
            'email': 'service@example.com',  # Email ya existe
            'username': 'Duplicate Email',
            'dni': '77777777G',
            'password': 'password123'
        }
        with self.assertRaises(ValueError) as context:
            UsuarioService.crear_usuario(datos)
        self.assertIn("email ya está registrado", str(context.exception))
    
    def test_obtener_usuario(self):
        """Prueba obtener usuario por ID"""
        usuario = UsuarioService.obtener_usuario(self.usuario.id)
        self.assertEqual(usuario.email, 'service@example.com')
    
    def test_listar_usuarios(self):
        """Prueba listar usuarios"""
        usuarios = UsuarioService.listar_usuarios()
        self.assertGreater(usuarios.count(), 0)


class LoginViewTests(TestCase):
    """Pruebas para la vista de login"""
    
    def setUp(self):
        """Preparar cliente de prueba y usuario"""
        self.client = Client()
        self.usuario = Usuario.objects.create_user(
            email='login@example.com',
            username='Login User',
            dni='88888888H',
            password='password123'
        )
    
    def test_login_exitoso(self):
        """Prueba login con credenciales correctas"""
        response = self.client.post(
            reverse('login'),
            data=json.dumps({
                'email': 'login@example.com',
                'password': 'password123'
            }),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.json())
        self.assertIn('refresh', response.json())
    
    def test_login_password_incorrecto(self):
        """Prueba login con contraseña incorrecta"""
        response = self.client.post(
            reverse('login'),
            data=json.dumps({
                'email': 'login@example.com',
                'password': 'passwordincorrecto'
            }),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertIn('error', response.json())
    
    def test_login_email_inexistente(self):
        """Prueba login con email que no existe"""
        response = self.client.post(
            reverse('login'),
            data=json.dumps({
                'email': 'noexiste@example.com',
                'password': 'password123'
            }),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_login_metodo_get_no_permitido(self):
        """Prueba que GET no está permitido en login"""
        response = self.client.get(reverse('login'))
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)


class RegisterViewTests(TestCase):
    """Pruebas para la vista de registro"""
    
    def setUp(self):
        """Preparar cliente de prueba"""
        self.client = Client()
    
    def test_register_exitoso(self):
        """Prueba registro exitoso"""
        response = self.client.post(
            reverse('register'),
            data=json.dumps({
                'email': 'newregister@example.com',
                'username': 'New Register User',
                'dni': '99999999I',
                'password': 'newpassword123'
            }),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.json()['email'], 'newregister@example.com')
    
    def test_register_email_duplicado(self):
        """Prueba registro con email duplicado"""
        Usuario.objects.create_user(
            email='duplicate@example.com',
            username='User Duplicate',
            dni='10101010J',
            password='password123'
        )
        response = self.client.post(
            reverse('register'),
            data=json.dumps({
                'email': 'duplicate@example.com',
                'username': 'Another User',
                'dni': '11111112K',
                'password': 'password456'
            }),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.json())
    
    def test_register_sin_email(self):
        """Prueba registro sin email"""
        response = self.client.post(
            reverse('register'),
            data=json.dumps({
                'username': 'No Email',
                'dni': '12121212L',
                'password': 'password123'
            }),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_register_sin_password(self):
        """Prueba registro sin contraseña"""
        response = self.client.post(
            reverse('register'),
            data=json.dumps({
                'email': 'nopass@example.com',
                'username': 'No Password',
                'dni': '13131313M'
            }),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_register_password_no_en_respuesta(self):
        """Prueba que la contraseña no se devuelva en la respuesta"""
        response = self.client.post(
            reverse('register'),
            data=json.dumps({
                'email': 'checkpass@example.com',
                'username': 'Check Pass',
                'dni': '14141414N',
                'password': 'mypassword123'
            }),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertNotIn('password', response.json())
    
    def test_register_metodo_get_no_permitido(self):
        """Prueba que GET no está permitido en register"""
        response = self.client.get(reverse('register'))
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)