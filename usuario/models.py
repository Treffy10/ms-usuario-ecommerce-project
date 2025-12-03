from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin

class UsuarioManager(BaseUserManager):
    def create_user(self, email, username, dni, password=None):
        if not email:
            raise ValueError("El usuario debe tener un email")
        email = self.normalize_email(email)
        user = self.model(email=email, username=username, dni=dni)
        user.set_password(password) #  Hash seguro
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, username, dni, password):
        user = self.create_user(email, username, dni, password)
        user.is_admin = True
        user.save(using=self._db)
        return user


class Usuario(AbstractBaseUser, PermissionsMixin):
    username = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    dni = models.CharField(max_length=20, unique=True)

    # Campos obligatorios para Django Admin / Auth
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UsuarioManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username", "dni"]

    def __str__(self):
        return self.email

    def get_first_name(self):
        return self.username.split(' ')[0] if self.username else ''