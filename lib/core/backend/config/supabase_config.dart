library;

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://reksfdnmkhwlaflkoamr.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla3NmZG5ta2h3bGFmbGtvYW1yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1MDQ3MDksImV4cCI6MjA3OTA4MDcwOX0.EAa6pY2ompzhgVnDedk2POu6Te0A6ey9uhL5BAWGt3o',
  );

  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl != 'https://your-project.supabase.co' &&
        supabaseAnonKey != 'your-anon-key-here' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }
}

