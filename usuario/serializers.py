from rest_framework import serializers
from .models import Usuario 

class UsuarioSerializer(serializers.ModelSerializer):
    
    # 1.  Campo de seguridad (solo entrada)
    password = serializers.CharField(
        write_only=True, 
        required=True, 
        style={'input_type': 'password'}
    )
    
    class Meta:
        model = Usuario
        # Incluimos 'password' para la entrada, pero no se mostrará en la salida
        fields = ('id', 'username', 'email', 'dni', 'password')
        read_only_fields = ('id',) 
        
        # 💡 Esta configuración garantiza que 'password' no se devuelva nunca en GET
        extra_kwargs = {'password': {'write_only': True}}