class AsesorNegocioModel {
  final String id;
  final String codigoEmpleado;
  final String nombres;
  final String apellidos;
  final String agenciaId;
  final String perfil;
  final bool activo;
  final String rol; // asesor | supervisor | admin (RBAC)

  const AsesorNegocioModel({
    required this.id,
    required this.codigoEmpleado,
    required this.nombres,
    required this.apellidos,
    required this.agenciaId,
    required this.perfil,
    required this.activo,
    this.rol = 'asesor',
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  bool get puedeAprobar => rol == 'supervisor' || rol == 'admin';

  factory AsesorNegocioModel.fromMap(Map<String, dynamic> map) {
    return AsesorNegocioModel(
      id: map['id']?.toString() ?? '',
      codigoEmpleado: map['codigo_empleado']?.toString() ?? '',
      nombres: map['nombres']?.toString() ?? '',
      apellidos: map['apellidos']?.toString() ?? '',
      agenciaId: map['agencia_id']?.toString() ?? '',
      perfil: map['perfil']?.toString() ?? '',
      activo: map['activo'] == true,
      rol: map['rol']?.toString() ?? 'asesor',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'codigo_empleado': codigoEmpleado,
        'nombres': nombres,
        'apellidos': apellidos,
        'agencia_id': agenciaId,
        'perfil': perfil,
        'activo': activo,
        'rol': rol,
      };
}
