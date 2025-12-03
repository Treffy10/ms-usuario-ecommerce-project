from django.contrib import admin
from usuario.models import Usuario
""""
@admin.register(Usuario)
class UsuarioAdmin(admin.ModelAdmin):
    list_display = ('email', 'username', 'edad', 'dni', 'is_staff', 'is_active')
    search_fields = ('email', 'username', 'dni')
    list_filter = ('is_staff', 'is_active')
    ordering = ('email',)
    fieldsets = (
        (None, {'fields': ('email', 'username', 'edad', 'dni', 'password')}),
        ('Permissions', {'fields': ('is_staff', 'is_active', 'is_superuser', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('last_login',)}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'edad', 'dni', 'password1', 'password2', 'is_staff', 'is_active')}
        ),
    )
    def get_readonly_fields(self, request, obj=None):
        if obj:  # Editing an existing object
            return self.readonly_fields + ('email', 'dni')
        return self.readonly_fields
    
admin.site.site_header = "Administración del Servicio de Usuarios"
admin.site.site_title = "Servicio de Usuarios"
admin.site.index_title = "Panel de Administración del Servicio de Usuarios"

"""