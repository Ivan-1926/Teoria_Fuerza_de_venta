import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import '../utils/format_utils.dart';
import '../models/credit_application_draft_model.dart';
import '../providers/credit_application_notifier.dart';
import '../theme.dart';
import '../utils/credit_simulator.dart';
import '../repositories/application_repository.dart';
import '../services/supabase_api.dart';
import '../widgets/application_form_widgets.dart';
import '../widgets/data_source_banner.dart';

class NewApplicationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? prefillClient;

  const NewApplicationScreen({super.key, this.prefillClient});

  @override
  ConsumerState<NewApplicationScreen> createState() =>
      _NewApplicationScreenState();
}

class _NewApplicationScreenState extends ConsumerState<NewApplicationScreen> {
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  late final SignatureController _signatureController;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dniCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _sectorCtrl;
  late final TextEditingController _businessAddrCtrl;
  late final TextEditingController _incomeCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _termCtrl;
  late final TextEditingController _teaCtrl;

  final _clientRepo = ApplicationRepository();
  List<Map<String, dynamic>> _clients = [];
  bool _clientsDemo = true;
  bool _supabaseReachable = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 2,
      penColor: kPrimaryBlue,
      exportBackgroundColor: Colors.white,
    );
    _initControllers();
    Future.microtask(() async {
      await _loadClients();
      await _checkResumeDraft();
    });
  }

  Future<void> _loadClients() async {
    final reachable = await pingSupabase();
    final result = await _clientRepo.loadClientsForPicker();
    if (!mounted) return;
    setState(() {
      _clients = result.clients;
      _clientsDemo = result.isDemo;
      _supabaseReachable = reachable;
    });
  }

  void _applyClient(Map<String, dynamic> c) {
    _nameCtrl.text = c['client_name']?.toString() ?? c['name']?.toString() ?? '';
    _dniCtrl.text = c['dni']?.toString() ?? '';
    _phoneCtrl.text = c['phone']?.toString() ?? '';
    _emailCtrl.text = c['email']?.toString() ?? '';
    _addressCtrl.text = c['address']?.toString() ?? '';
    _businessNameCtrl.text = c['business_name']?.toString() ?? '';
    _sectorCtrl.text = c['business_sector']?.toString() ?? '';
    _businessAddrCtrl.text =
        c['business_address']?.toString() ?? c['address']?.toString() ?? '';
    if (c['monthly_income'] != null) {
      _incomeCtrl.text = '${c['monthly_income']}';
    }
    if (c['business_age_years'] != null) {
      _ageCtrl.text = '${c['business_age_years']}';
    }
    setState(() {});
  }

  Future<void> _showClientPicker() async {
    if (_clients.isEmpty) await _loadClients();
    if (!mounted) return;
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Seleccionar cliente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBlue,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: _clients.length,
                  itemBuilder: (_, i) {
                    final c = _clients[i];
                    final name =
                        c['client_name']?.toString() ?? c['name']?.toString() ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryYellow,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: kPrimaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text('DNI ${c['dni'] ?? ''}'),
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) _applyClient(picked);
  }

  void _initControllers() {
    final p = widget.prefillClient ?? {};
    _nameCtrl = TextEditingController(
      text: p['client_name']?.toString() ?? p['name']?.toString() ?? '',
    );
    _dniCtrl = TextEditingController(text: p['dni']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: p['phone']?.toString() ?? '');
    _emailCtrl = TextEditingController(text: p['email']?.toString() ?? '');
    _addressCtrl = TextEditingController(text: p['address']?.toString() ?? '');
    _businessNameCtrl =
        TextEditingController(text: p['business_name']?.toString() ?? '');
    _sectorCtrl =
        TextEditingController(text: p['business_sector']?.toString() ?? '');
    _businessAddrCtrl = TextEditingController(
      text: p['business_address']?.toString() ?? p['address']?.toString() ?? '',
    );
    _incomeCtrl = TextEditingController(
      text: p['monthly_income'] != null ? '${p['monthly_income']}' : '',
    );
    _ageCtrl = TextEditingController(
      text: p['business_age_years'] != null
          ? '${p['business_age_years']}'
          : '',
    );
    _amountCtrl = TextEditingController();
    _termCtrl = TextEditingController(text: '12');
    _teaCtrl = TextEditingController(text: '18');
  }

  CreditApplicationNotifier get _vm =>
      ref.read(creditApplicationNotifierProvider(widget.prefillClient).notifier);

  CreditApplicationState get _state =>
      ref.watch(creditApplicationNotifierProvider(widget.prefillClient));

  Future<void> _checkResumeDraft() async {
    final dni = _dniCtrl.text.trim();
    if (dni.isEmpty) return;
    final saved = await _vm.checkResumableDraft(dni);
    if (!mounted || saved == null) return;
    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrador encontrado'),
        content: const Text(
          'Hay una solicitud guardada para este cliente. ¿Desea continuar donde la dejó?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Empezar de nuevo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reanudar'),
          ),
        ],
      ),
    );
    if (resume == true) {
      await _vm.resumeDraft(saved);
      _syncControllersFromDraft(_state.draft);
      if (saved.signatureBase64 != null &&
          saved.signatureBase64!.isNotEmpty) {
        // La firma previa no se puede pintar en el pad; el usuario puede firmar de nuevo.
      }
    }
  }

  void _syncControllersFromDraft(CreditApplicationDraftModel d) {
    _nameCtrl.text = d.clientName;
    _dniCtrl.text = d.clientDni;
    _phoneCtrl.text = d.clientPhone;
    _emailCtrl.text = d.clientEmail;
    _addressCtrl.text = d.clientAddress;
    _businessNameCtrl.text = d.businessName;
    _sectorCtrl.text = d.businessSector;
    _businessAddrCtrl.text = d.businessAddress;
    _incomeCtrl.text = d.monthlyIncome > 0 ? '${d.monthlyIncome}' : '';
    _ageCtrl.text =
        d.businessAgeYears > 0 ? '${d.businessAgeYears}' : '';
    _amountCtrl.text = d.amount > 0 ? '${d.amount}' : '';
    _termCtrl.text = '${d.termMonths}';
    _teaCtrl.text = '${d.tea}';
  }

  CreditApplicationDraftModel _draftFromForm() {
    final current = _state.draft;
    return current.copyWith(
      clientName: _nameCtrl.text.trim(),
      clientDni: _dniCtrl.text.trim(),
      clientPhone: _phoneCtrl.text.trim(),
      clientEmail: _emailCtrl.text.trim(),
      clientAddress: _addressCtrl.text.trim(),
      businessName: _businessNameCtrl.text.trim(),
      businessSector: _sectorCtrl.text.trim(),
      businessAddress: _businessAddrCtrl.text.trim(),
      monthlyIncome: double.tryParse(_incomeCtrl.text) ?? 0,
      businessAgeYears: int.tryParse(_ageCtrl.text) ?? 0,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      termMonths: int.tryParse(_termCtrl.text) ?? 12,
      tea: double.tryParse(_teaCtrl.text) ?? 18,
    );
  }

  bool _validateCurrentStep() {
    return _formKeys[_state.currentStep].currentState?.validate() ?? false;
  }

  void _onCreditFieldsChanged() {
    final draft = _vm.applySimulation(_draftFromForm());
    _vm.updateDraft(draft);
  }

  Future<void> _handleNext() async {
    if (!_validateCurrentStep()) return;
    var draft = _draftFromForm();
    if (_state.currentStep == 2) {
      draft = _vm.applySimulation(draft);
      _vm.updateDraft(draft);
    }
    if (_state.currentStep == 3) {
      if (_signatureController.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe firmar antes de enviar')),
        );
        return;
      }
      final bytes = await _signatureController.toPngBytes();
      if (bytes == null) return;
      final signed = _vm
          .applySimulation(_draftFromForm())
          .copyWith(signatureBase64: base64Encode(bytes));
      _vm.updateDraft(signed);
      await _vm.saveDraftLocal();
      final ok = await _vm.submitApplication();
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _state.successMessage ?? 'Solicitud registrada',
            ),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }
    _vm.updateDraft(draft);
    await _vm.saveDraftLocal();
    _vm.nextStep();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _nameCtrl.dispose();
    _dniCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _businessNameCtrl.dispose();
    _sectorCtrl.dispose();
    _businessAddrCtrl.dispose();
    _incomeCtrl.dispose();
    _ageCtrl.dispose();
    _amountCtrl.dispose();
    _termCtrl.dispose();
    _teaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _state.currentStep;
    final draftForSim =
        step >= 2 ? _draftFromForm() : _state.draft;
    final sim = CreditSimulator.calculate(
      amount: draftForSim.amount,
      termMonths: draftForSim.termMonths,
      teaPercent: draftForSim.tea,
    );

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Solicitud de crédito'),
        actions: [
          if (_state.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kPrimaryYellow,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Guardar borrador',
              onPressed: () async {
                _vm.updateDraft(_draftFromForm());
                await _vm.saveDraftLocal();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _state.successMessage ?? 'Borrador guardado',
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          DataSourceBanner(
            isDemo: _clientsDemo,
            supabaseReachable: _supabaseReachable || !_clientsDemo,
          ),
          _StepIndicator(current: step),
          if (_state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _state.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: step,
              children: [
                _stepClient(),
                _stepBusiness(),
                _stepCredit(sim),
                _stepConfirm(sim),
              ],
            ),
          ),
          _BottomBar(
            step: step,
            isLoading: _state.isLoading,
            onBack: step > 0 ? () => _vm.previousStep() : null,
            onNext: _state.isLoading ? null : _handleNext,
            nextLabel: step == 3 ? 'Enviar solicitud' : 'Siguiente',
          ),
        ],
      ),
    );
  }

  Widget _stepClient() {
    return Form(
      key: _formKeys[0],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const WizardStepHeader(
            stepNumber: 1,
            title: 'Datos del cliente',
            subtitle: 'Identificación y contacto del solicitante',
          ),
          ClientHeroHeader(
            name: _nameCtrl.text,
            dni: _dniCtrl.text.isEmpty ? null : _dniCtrl.text,
            subtitle: _clientsDemo
                ? 'Clientes demo · toque el ícono para buscar'
                : 'Clientes desde Supabase',
            onPickClient: _showClientPicker,
          ),
          FormSectionCard(
            title: 'Identificación',
            icon: Icons.badge_outlined,
            children: [
              PichinchaField(
                controller: _nameCtrl,
                label: 'Nombre completo *',
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                onChanged: () => setState(() {}),
              ),
              PichinchaField(
                controller: _dniCtrl,
                label: 'DNI / RUC *',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().length < 10) ? 'DNI inválido' : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FormSectionCard(
            title: 'Contacto',
            icon: Icons.contact_phone_outlined,
            children: [
              PichinchaField(
                controller: _phoneCtrl,
                label: 'Teléfono *',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Teléfono inválido'
                    : null,
              ),
              PichinchaField(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              PichinchaField(
                controller: _addressCtrl,
                label: 'Dirección de domicilio',
                icon: Icons.home_outlined,
                maxLines: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBusiness() {
    return Form(
      key: _formKeys[1],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const WizardStepHeader(
            stepNumber: 2,
            title: 'Datos del negocio',
            subtitle: 'Actividad económica e ingresos',
          ),
          FormSectionCard(
            title: 'Negocio',
            icon: Icons.storefront_outlined,
            children: [
              PichinchaField(
                controller: _businessNameCtrl,
                label: 'Nombre del negocio *',
                icon: Icons.store,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              PichinchaField(
                controller: _sectorCtrl,
                label: 'Rubro / actividad *',
                icon: Icons.category_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              PichinchaField(
                controller: _businessAddrCtrl,
                label: 'Dirección del negocio',
                icon: Icons.place_outlined,
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FormSectionCard(
            title: 'Finanzas',
            icon: Icons.payments_outlined,
            children: [
              PichinchaField(
                controller: _incomeCtrl,
                label: 'Ingreso mensual (USD) *',
                icon: Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Ingrese un monto válido';
                  return null;
                },
              ),
              PichinchaField(
                controller: _ageCtrl,
                label: 'Años en el negocio',
                icon: Icons.schedule,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepCredit(CreditSimulationResult sim) {
    return Form(
      key: _formKeys[2],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const WizardStepHeader(
            stepNumber: 3,
            title: 'Condiciones del crédito',
            subtitle: 'Monto, plazo y simulación',
          ),
          PichinchaField(
            controller: _amountCtrl,
            label: 'Monto solicitado (USD) *',
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            onChanged: _onCreditFieldsChanged,
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n < 500) return 'Monto mínimo \$500';
              return null;
            },
          ),
          PichinchaField(
            controller: _termCtrl,
            label: 'Plazo (meses) *',
            icon: Icons.date_range,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onCreditFieldsChanged,
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 3 || n > 60) return 'Plazo entre 3 y 60 meses';
              return null;
            },
          ),
          PichinchaField(
            controller: _teaCtrl,
            label: 'TEA (%) *',
            icon: Icons.percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            onChanged: _onCreditFieldsChanged,
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n <= 0 || n > 80) return 'TEA inválida';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _SimulatorPanel(
            monthlyPayment: sim.monthlyPayment,
            totalInterest: sim.totalInterest,
            totalAmount: sim.totalAmount,
          ),
        ],
      ),
    );
  }

  Widget _stepConfirm(CreditSimulationResult sim) {
    final d = _draftFromForm();
    return Form(
      key: _formKeys[3],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const WizardStepHeader(
            stepNumber: 4,
            title: 'Confirmación',
            subtitle: 'Revise el resumen y firme',
          ),
          _SummaryCard(
            title: 'Cliente',
            lines: [
              d.clientName,
              if (d.clientDni.isNotEmpty) 'DNI: ${d.clientDni}',
              if (d.clientPhone.isNotEmpty) d.clientPhone,
            ],
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            title: 'Negocio',
            lines: [
              d.businessName,
              d.businessSector,
              FormatUtils.usd(d.monthlyIncome),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            title: 'Crédito',
            lines: [
              'Monto: ${FormatUtils.usd(d.amount)}',
              'Plazo: ${d.termMonths} meses · TEA ${d.tea.toStringAsFixed(1)}%',
              'Cuota: ${FormatUtils.usd(sim.monthlyPayment)}',
              'Interés total: ${FormatUtils.usd(sim.totalInterest)}',
              'Total a pagar: ${FormatUtils.usd(sim.totalAmount)}',
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Firma digital',
            style: TextStyle(
              color: kPrimaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryYellow, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Signature(
                controller: _signatureController,
                height: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _signatureController.clear(),
            child: const Text('Limpiar firma'),
          ),
        ],
      ),
    );
  }
}

// ── UI helpers ───────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  static const _labels = ['Cliente', 'Negocio', 'Crédito', 'Confirmar'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: List.generate(4, (i) {
          final active = i <= current;
          final done = i < current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            active ? kPrimaryYellow : Colors.grey.shade300,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: active ? kPrimaryBlue : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: done || i == current
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: active ? kPrimaryBlue : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < current ? kPrimaryYellow : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String step;
  final String title;
  const _StepTitle(this.step, this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(
              title,
              style: const TextStyle(
                color: kPrimaryBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}

class _SimulatorPanel extends StatelessWidget {
  final double monthlyPayment;
  final double totalInterest;
  final double totalAmount;
  const _SimulatorPanel({
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Simulador en tiempo real',
            style: TextStyle(
              color: kPrimaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SimRow('Cuota mensual', FormatUtils.usd(monthlyPayment), highlight: true),
          _SimRow('Interés total', FormatUtils.usd(totalInterest)),
          _SimRow('Total a pagar', FormatUtils.usd(totalAmount)),
        ],
      ),
    );
  }
}

class _SimRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SimRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade700)),
            Text(
              value,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: kPrimaryBlue,
                fontSize: highlight ? 18 : 15,
              ),
            ),
          ],
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _SummaryCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kPrimaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...lines.where((l) => l.isNotEmpty).map(
                (l) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(l, style: const TextStyle(fontSize: 14)),
                ),
              ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int step;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  const _BottomBar({
    required this.step,
    required this.isLoading,
    this.onBack,
    this.onNext,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Atrás'),
                ),
              ),
            if (onBack != null) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryYellow,
                  foregroundColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isLoading ? null : onNext,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(nextLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
