from usuario.models import Usuario
# Necesitas importar esta excepción estándar para manejar búsquedas fallidas.
from django.core.exceptions import ObjectDoesNotExist 

class UsuarioRepository:
    
    @staticmethod
    def listar():
        # Correcto en ambos ORMs, pero confirmado para Django ORM.
        return Usuario.objects.all() 

    @staticmethod
    def obtener_por_id(id):
        try:
            #  CORRECCIÓN: Usamos .get(pk=id) para obtener por clave primaria.
            # Si no se encuentra, Django lanza la excepción ObjectDoesNotExist.
            return Usuario.objects.get(pk=id)
        except ObjectDoesNotExist:
            return None # Devolver None si no se encuentra.
    
    @staticmethod
    def crear(datos):
        #  MEJORA: Usamos el método .create() del Manager.
        # Esto es más conciso y a veces más seguro.
        return Usuario.objects.create(**datos) 

    @staticmethod
    def actualizar(id, datos):
        usuario = UsuarioRepository.obtener_por_id(id)
        if not usuario:
            return None
        
        #  La lógica de setattr() y save() es correcta para la actualización.
        for campo, valor in datos.items():
            setattr(usuario, campo, valor)
            
        usuario.save()
        return usuario

    @staticmethod
    def eliminar(id):
        #  Usar try/except para obtener el objeto.
        try:
            usuario = Usuario.objects.get(pk=id)
            usuario.delete()
            return True
        except ObjectDoesNotExist:
            return False