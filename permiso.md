En el build() del form screen, leo el estado del AuthBloc que está en el árbol de widgets:

final authState = context.watch<AuthBloc>().state;  
 final canWrite = authState is AuthAuthenticated  
 ? authState.user.canWrite('pagosRealizados')  
 : true;

El flujo completo es:

1. Login / sesión restaurada  
   ApiAuthRepository llama a GET /me, parsea el campo permisos del response JSON y construye el objeto User:  
   // {"permisos": {"pagosRealizados": "lectura", "tours": "completo"}}  
   final permisosRaw = (userData['permisos'] as Map<String, dynamic>?) ?? {};
   final permisos = permisosRaw.map((k, v) => MapEntry(k, v.toString()));  
   return User(..., permisos: permisos);  

2. AuthBloc emite AuthAuthenticated(user)  
   Ese estado queda vivo en el árbol de widgets durante toda la sesión.  

3. En cualquier pantalla  
   context.watch<AuthBloc>().state obtiene ese estado. Si es AuthAuthenticated, se accede al user.permisos que es un Map<String, String>:  
   // user.permisos = {"pagosRealizados": "lectura", "tours": "completo"}  

4. canWrite(key) en User  
   bool canWrite(String key) => permisos[key] == 'completo';

- pagosRealizados → "lectura" → canWrite = false
- tours → "completo" → canWrite = true  


La clave del módulo ('pagosRealizados', 'tours', 'reservas', etc.) debe coincidir exactamente con la que viene del backend en el JSON de permisos. Si el backend envía "pagos_realizados" en lugar de "pagosRealizados", no matchea
y canWrite retorna false.
