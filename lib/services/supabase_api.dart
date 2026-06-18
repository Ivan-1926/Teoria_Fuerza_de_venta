import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

const _supabaseUrl = supabaseUrl;
const _supabaseKey = supabaseAnonKey;

Map<String, String> _headers({bool returnRepresentation = false}) => {
  'apikey': _supabaseKey,
  'Authorization': 'Bearer $_supabaseKey',
  'Content-Type': 'application/json',
  if (returnRepresentation) 'Prefer': 'return=representation',
};

// ─── HEALTH CHECK ────────────────────────────────────────────────────────────

/// Verifica si el proyecto Supabase responde (tabla credit_applications).
Future<bool> pingSupabase() async {
  try {
    final url = Uri.parse(
      '$_supabaseUrl/rest/v1/fv_credit_applications?select=id&limit=1',
    );
    final res = await http.get(url, headers: _headers());
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

// ─── AUTH ────────────────────────────────────────────────────────────────────

Future<Map<String, dynamic>?> loginOfficer(
  String email,
  String password,
) async {
  final url = Uri.parse(
    '$_supabaseUrl/rest/v1/officers?email=eq.$email&password=eq.$password&select=*&limit=1',
  );
  final res = await http.get(url, headers: _headers());
  if (res.statusCode == 200) {
    final list = json.decode(res.body) as List<dynamic>;
    if (list.isNotEmpty) return list.first as Map<String, dynamic>;
  }
  return null;
}

// ─── PORTFOLIO ───────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> fetchDailyPortfolio({
  int limit = 100,
  String? officerId,
}) async {
  String query =
      '$_supabaseUrl/rest/v1/fv_daily_portfolio?select=*&order=priority.desc,next_visit_date.asc&limit=$limit';
  if (officerId != null && officerId.isNotEmpty) {
    query += '&officer_id=eq.$officerId';
  }
  final res = await http.get(Uri.parse(query), headers: _headers());
  if (res.statusCode == 200) {
    return (json.decode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
  throw Exception('Error portfolio: ${res.statusCode}');
}

// ─── CLIENTS ─────────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> fetchClients({String? search}) async {
  String query = '$_supabaseUrl/rest/v1/fv_clients?select=*&limit=200';
  if (search != null && search.isNotEmpty) {
    query += '&name=ilike.*$search*';
  }
  final res = await http.get(Uri.parse(query), headers: _headers());
  if (res.statusCode == 200) {
    return (json.decode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
  throw Exception('Error clients: ${res.statusCode}');
}

Future<Map<String, dynamic>?> fetchClientById(String id) async {
  final url = Uri.parse(
    '$_supabaseUrl/rest/v1/fv_clients?id=eq.$id&select=*&limit=1',
  );
  final res = await http.get(url, headers: _headers());
  if (res.statusCode == 200) {
    final list = json.decode(res.body) as List<dynamic>;
    if (list.isNotEmpty) return list.first as Map<String, dynamic>;
  }
  return null;
}

// ─── APPLICATIONS ────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> fetchApplications({
  String? status,
  String? clientId,
  String? officerId,
}) async {
  String query =
      '$_supabaseUrl/rest/v1/fv_credit_applications?select=*&order=submitted_at.desc&limit=200';
  if (status != null && status.isNotEmpty && status != 'todos') {
    query += '&status=eq.$status';
  }
  if (clientId != null) query += '&client_id=eq.$clientId';
  if (officerId != null && officerId.isNotEmpty && officerId != 'demo-officer-001') {
    query += '&or=(officer_id.eq.$officerId,officer_id.is.null)';
  }
  final res = await http.get(Uri.parse(query), headers: _headers());
  if (res.statusCode == 200) {
    return (json.decode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
  throw Exception('Error applications: ${res.statusCode}');
}

Future<Map<String, dynamic>> createCreditApplication(
  Map<String, dynamic> payload,
) async {
  final url = Uri.parse('$_supabaseUrl/rest/v1/fv_credit_applications');
  final res = await http.post(
    url,
    headers: _headers(returnRepresentation: true),
    body: json.encode(payload),
  );
  if (res.statusCode == 201) {
    final data = json.decode(res.body);
    if (data is List && data.isNotEmpty) {
      return data.first as Map<String, dynamic>;
    }
    return {};
  }
  throw Exception('Error creating application: ${res.statusCode} ${res.body}');
}

Future<void> updateApplicationStatus(String id, String status) async {
  await patchCreditApplication(id, {'status': status});
}

Future<void> patchCreditApplication(
  String id,
  Map<String, dynamic> fields,
) async {
  if (fields.isEmpty) return;
  final url = Uri.parse('$_supabaseUrl/rest/v1/fv_credit_applications?id=eq.$id');
  final res = await http.patch(
    url,
    headers: _headers(),
    body: json.encode(fields),
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error updating application: ${res.statusCode} ${res.body}');
  }
}

// ─── ROUTE VISITS ─────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> fetchRouteVisits(
  String date, {
  String? officerId,
}) async {
  String query =
      '$_supabaseUrl/rest/v1/fv_route_visits?visit_date=eq.$date&select=*&order=visit_order.asc';
  if (officerId != null && officerId.isNotEmpty) {
    query += '&officer_id=eq.$officerId';
  }
  final res = await http.get(Uri.parse(query), headers: _headers());
  if (res.statusCode == 200) {
    return (json.decode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
  throw Exception('Error visits: ${res.statusCode}');
}

Future<void> updateVisitStatus(String visitId, String status) async {
  final url = Uri.parse('$_supabaseUrl/rest/v1/fv_route_visits?id=eq.$visitId');
  await http.patch(
    url,
    headers: _headers(),
    body: json.encode({'visit_status': status}),
  );
}

// ─── CLIENT BY DNI ───────────────────────────────────────────────────────────

Future<Map<String, dynamic>?> fetchClientByDni(String dni) async {
  final url = Uri.parse(
    '$_supabaseUrl/rest/v1/fv_clients?dni=eq.$dni&select=*&limit=1',
  );
  final res = await http.get(url, headers: _headers());
  if (res.statusCode == 200) {
    final list = json.decode(res.body) as List<dynamic>;
    if (list.isNotEmpty) return list.first as Map<String, dynamic>;
  }
  return null;
}

// ─── BLACKLIST ───────────────────────────────────────────────────────────────

Future<Map<String, dynamic>?> fetchBlacklistEntry(String dni) async {
  for (final table in ['fv_blacklist', 'blacklist', 'listas_negras', 'blacklists']) {
    try {
      final url = Uri.parse(
        '$_supabaseUrl/rest/v1/$table?dni=eq.$dni&select=*&limit=1',
      );
      final res = await http.get(url, headers: _headers());
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        if (list.isNotEmpty) return list.first as Map<String, dynamic>;
      }
    } catch (_) {}
  }

  final client = await fetchClientByDni(dni);
  if (client != null) {
    final status = client['status']?.toString().toLowerCase() ?? '';
    if (status == 'blacklisted' || status == 'lista_negra') {
      return {
        'dni': dni,
        'reason':
            client['blacklist_reason']?.toString() ??
            'Cliente en lista negra interna',
      };
    }
  }
  return null;
}

// ─── BURO QUERIES ────────────────────────────────────────────────────────────

Future<Map<String, dynamic>> saveBuroQuery(Map<String, dynamic> payload) async {
  for (final table in [
    'fv_buro_queries',
    'buro_queries',
    'credit_bureau_queries',
    'buro_consultas',
  ]) {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/$table');
      final res = await http.post(
        url,
        headers: _headers(returnRepresentation: true),
        body: json.encode(payload),
      );
      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        if (data is List && data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
        return payload;
      }
    } catch (_) {}
  }
  throw Exception('No se pudo guardar la consulta de buró');
}

Future<List<Map<String, dynamic>>> fetchBuroQueries(String dni) async {
  for (final table in [
    'fv_buro_queries',
    'buro_queries',
    'credit_bureau_queries',
    'buro_consultas',
  ]) {
    try {
      final url = Uri.parse(
        '$_supabaseUrl/rest/v1/$table?dni=eq.$dni&select=*&order=consulted_at.desc&limit=5',
      );
      final res = await http.get(url, headers: _headers());
      if (res.statusCode == 200) {
        return (json.decode(res.body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
    } catch (_) {}
  }
  return [];
}

// ─── CREDIT BUREAU (legacy wrapper → consulta_buro) ─────────────────────────

Future<Map<String, dynamic>> checkCreditBureau(String dni) async {
  final client = await fetchClientByDni(dni);
  final blacklist = await fetchBlacklistEntry(dni);
  final score = (client?['credit_score'] as num?)?.toInt() ?? 650;
  return {
    'dni': dni,
    'name': client?['name']?.toString() ?? 'Consultado',
    'score': score,
    'calificacion_sbs': score,
    'deuda_total': (client?['total_debt'] as num?)?.toDouble() ?? 0,
    'mayor_deuda': (client?['max_debt'] as num?)?.toDouble() ?? 0,
    'dias_mora': (client?['days_overdue'] as num?)?.toInt() ?? 0,
    'in_blacklist': blacklist != null,
    'blacklist_reason': blacklist?['reason']?.toString(),
    'payment_history': (score * 0.35).round(),
    'debt_level': (score * 0.30).round(),
    'credit_age': (score * 0.15).round(),
    'credit_mix': (score * 0.10).round(),
    'new_credit': (score * 0.10).round(),
    'alerts': blacklist != null
        ? ['Cliente en lista negra']
        : score < 600
        ? ['Deuda en mora detectada']
        : [],
    'recommendation': blacklist != null
        ? 'BLOQUEADO — Lista negra'
        : score >= 700
        ? 'Cliente elegible para crédito'
        : score >= 600
        ? 'Evaluar con garantía adicional'
        : 'No recomendado en este momento',
    'checked_at': DateTime.now().toIso8601String(),
  };
}

// ─── CLIENT DOCUMENTS (M6) ───────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> fetchClientDocuments({
  String? clientId,
  String? dni,
}) async {
  String query = '$_supabaseUrl/rest/v1/fv_client_documents?select=*';
  if (clientId != null && clientId.isNotEmpty) {
    query += '&client_id=eq.$clientId';
  } else if (dni != null && dni.isNotEmpty) {
    query += '&dni=eq.$dni';
  } else {
    return [];
  }
  final res = await http.get(Uri.parse(query), headers: _headers());
  if (res.statusCode == 200) {
    return (json.decode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
  return [];
}

Future<Map<String, dynamic>> saveClientDocument(
  Map<String, dynamic> payload,
) async {
  final url = Uri.parse('$_supabaseUrl/rest/v1/fv_client_documents');
  final res = await http.post(
    url,
    headers: _headers(returnRepresentation: true),
    body: json.encode(payload),
  );
  if (res.statusCode == 201) {
    final data = json.decode(res.body);
    if (data is List && data.isNotEmpty) {
      return data.first as Map<String, dynamic>;
    }
    return payload;
  }
  throw Exception('Error guardando documento: ${res.statusCode} ${res.body}');
}

Future<void> deleteClientDocumentRemote(String id) async {
  final url = Uri.parse('$_supabaseUrl/rest/v1/fv_client_documents?id=eq.$id');
  await http.delete(url, headers: _headers());
}

// ─── STORAGE ─────────────────────────────────────────────────────────────────

Future<String> uploadDocumentFile(
  String filePath,
  String bucket,
  String destPath,
) async {
  final file = File(filePath);
  if (!file.existsSync()) throw Exception('File not found: $filePath');
  final bytes = await file.readAsBytes();
  final url = Uri.parse('$_supabaseUrl/storage/v1/object/$bucket/$destPath');
  final res = await http.put(
    url,
    headers: {
      ..._headers(),
      'x-upsert': 'true',
      'Content-Type': _mimeForPath(filePath),
    },
    body: bytes,
  );
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception('Upload failed: ${res.statusCode} ${res.body}');
  }
  return '$_supabaseUrl/storage/v1/object/public/$bucket/$destPath';
}

String _mimeForPath(String path) {
  final l = path.toLowerCase();
  if (l.endsWith('.jpg') || l.endsWith('.jpeg')) return 'image/jpeg';
  if (l.endsWith('.png')) return 'image/png';
  if (l.endsWith('.pdf')) return 'application/pdf';
  return 'application/octet-stream';
}
