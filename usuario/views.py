from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from usuario.services import UsuarioService
from usuario.serializers import UsuarioSerializer


@api_view(['POST'])
def login_view(request):
    if request.method == 'POST':
        email = request.data.get('email')
        password = request.data.get('password')
        try:
            auth_data = UsuarioService.autenticar_usuario(email, password)
            return Response(auth_data)  
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_401_UNAUTHORIZED)
    return Response({'error': 'Método no permitido'}, status=status.HTTP_405_METHOD_NOT_ALLOWED)


@api_view(['POST'])
def register_view(request):
    if request.method == 'POST':
        usuario_data = request.data
        try:
            nuevo_usuario = UsuarioService.crear_usuario(usuario_data)
            
            #  CORRECCIÓN: Usar el Serializer para la respuesta
            serializer = UsuarioSerializer(nuevo_usuario)
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        except ValueError as e:
            #  Usamos 400 BAD REQUEST aquí, ya que el error viene de datos incompletos o duplicados.
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
