/// Datos de demostración cuando Supabase no responde o está vacío.
class DemoDataService {
  static const supabaseUrl = 'https://uomaqpphyouzbnestbba.supabase.co';

  static List<Map<String, dynamic>> demoClients() => [
        {
          'id': 'cli-demo-001',
          'client_id': 'cli-demo-001',
          'name': 'María Elena Vásquez',
          'client_name': 'María Elena Vásquez',
          'dni': '1712345678',
          'phone': '0991234567',
          'email': 'maria.vasquez@email.com',
          'address': 'Av. 6 de Diciembre N45-12, Quito',
          'business_name': 'Panadería La Espiga',
          'business_sector': 'Alimentos',
          'monthly_income': 1850,
          'business_age_years': 4,
          'credit_score': 720,
        },
        {
          'id': 'cli-demo-002',
          'client_id': 'cli-demo-002',
          'name': 'Roberto Andrés Morales',
          'client_name': 'Roberto Andrés Morales',
          'dni': '1723456789',
          'phone': '0987654321',
          'email': 'roberto.morales@email.com',
          'address': 'Cdla. Kennedy, Guayaquil',
          'business_name': 'Taller Mecánico RM',
          'business_sector': 'Servicios automotriz',
          'monthly_income': 2400,
          'business_age_years': 7,
          'credit_score': 680,
        },
        {
          'id': 'cli-demo-003',
          'client_id': 'cli-demo-003',
          'name': 'Ana Lucía Herrera',
          'client_name': 'Ana Lucía Herrera',
          'dni': '1709876543',
          'phone': '0998877665',
          'email': 'ana.herrera@email.com',
          'address': 'Calle Sucre 102, Cuenca',
          'business_name': 'Boutique Ana Moda',
          'business_sector': 'Comercio retail',
          'monthly_income': 1600,
          'business_age_years': 3,
          'credit_score': 640,
        },
      ];

  static List<Map<String, dynamic>> demoApplications() {
    final now = DateTime.now();
    return [
      _app(
        id: 'app-demo-001',
        clientName: 'María Elena Vásquez',
        clientDni: '1712345678',
        amount: 8500,
        termMonths: 18,
        purpose: 'Capital de trabajo',
        status: 'enviado',
        daysAgo: 2,
        now: now,
      ),
      _app(
        id: 'app-demo-002',
        clientName: 'Roberto Andrés Morales',
        clientDni: '1723456789',
        amount: 15000,
        termMonths: 24,
        purpose: 'Compra de equipo',
        status: 'comite',
        daysAgo: 5,
        now: now,
      ),
      _app(
        id: 'app-demo-003',
        clientName: 'Ana Lucía Herrera',
        clientDni: '1709876543',
        amount: 5200,
        termMonths: 12,
        purpose: 'Inventario temporada',
        status: 'aprobado',
        daysAgo: 8,
        now: now,
      ),
      _app(
        id: 'app-demo-004',
        clientName: 'Carlos Mendoza',
        clientDni: '1711122233',
        amount: 12000,
        termMonths: 36,
        purpose: 'Ampliación local',
        status: 'desembolsado',
        daysAgo: 15,
        now: now,
      ),
      _app(
        id: 'app-demo-005',
        clientName: 'Patricia Gómez',
        clientDni: '1799887766',
        amount: 3000,
        termMonths: 6,
        purpose: 'Gastos operativos',
        status: 'pendiente',
        daysAgo: 0,
        now: now,
      ),
    ];
  }

  static Map<String, dynamic> _app({
    required String id,
    required String clientName,
    required String clientDni,
    required double amount,
    required int termMonths,
    required String purpose,
    required String status,
    required int daysAgo,
    required DateTime now,
  }) {
    final submitted = now.subtract(Duration(days: daysAgo));
    final monthly = amount / termMonths * 1.02;
    return {
      'id': id,
      'client_id': 'cli-demo',
      'client_name': clientName,
      'client_dni': clientDni,
      'amount': amount,
      'term_months': termMonths,
      'purpose': purpose,
      'status': status,
      'tea': 18.0,
      'monthly_payment': monthly,
      'officer_id': 'demo-officer-001',
      'submitted_at': submitted.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }
}
