// Configuración de Supabase para la app.
// Puedes sobrescribir estos valores en tiempo de compilación con --dart-define.

const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://uomaqpphyouzbnestbba.supabase.co',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_fymmXEWgkQSdaXe-F3_8OA_QK6ZOnCe',
);
