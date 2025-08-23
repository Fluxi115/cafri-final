import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class ColaboradorCalendario extends StatefulWidget {
  final String userEmail;
  const ColaboradorCalendario({super.key, required this.userEmail});

  @override
  State<ColaboradorCalendario> createState() => _ColaboradorCalendarioState();
}

class _ColaboradorCalendarioState extends State<ColaboradorCalendario> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};
  bool _loading = true;
  String? _error;
  late DateTime _primerDia;
  late DateTime _ultimoDia;
  StreamSubscription<QuerySnapshot>? _firestoreListener;

  DateTime _getPrimerDiaMes(DateTime date) =>
      DateTime(date.year, date.month, 1);
  DateTime _getUltimoDiaMes(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);

  @override
  void initState() {
    super.initState();
    _primerDia = _getPrimerDiaMes(_focusedDay);
    _ultimoDia = _getUltimoDiaMes(_focusedDay);
    _escucharFirestore();
  }

  @override
  void dispose() {
    _firestoreListener?.cancel();
    super.dispose();
  }

  void _escucharFirestore() {
    _loading = true;
    _eventos.clear();
    _firestoreListener?.cancel();

    final stream = FirebaseFirestore.instance
        .collection('actividades')
        .where('colaborador', isEqualTo: widget.userEmail)
        .where('fecha', isGreaterThanOrEqualTo: _primerDia)
        .where('fecha', isLessThanOrEqualTo: _ultimoDia)
        .orderBy('fecha')
        .snapshots();

    _firestoreListener = stream.listen(
      (snapshot) {
        final eventosTemp = <DateTime, List<Map<String, dynamic>>>{};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final fecha = (data['fecha'] as Timestamp).toDate();
          final dia = DateTime(fecha.year, fecha.month, fecha.day);
          eventosTemp
              .putIfAbsent(dia, () => [])
              .add(Map<String, dynamic>.from(data));
        }
        setState(() {
          _eventos = eventosTemp;
          _loading = false;
          _error = null;
        });
      },
      onError: (error) {
        setState(() {
          _eventos.clear();
          _loading = false;
          _error = error.toString();
        });
      },
    );
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _primerDia = _getPrimerDiaMes(_focusedDay);
      _ultimoDia = _getUltimoDiaMes(_focusedDay);
      _loading = true;
    });
    _escucharFirestore();
  }

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'aceptada':
        return Colors.blue;
      case 'en_proceso':
        return Colors.amber;
      case 'pausada':
        return Colors.deepOrange;
      case 'terminada':
        return Colors.green;
      default:
        return Colors.indigo;
    }
  }

  List<Map<String, dynamic>> _getEventosDelDia(DateTime day) {
    final dia = DateTime(day.year, day.month, day.day);
    return _eventos[dia] ?? [];
  }

  void _mostrarEventosDelDia(BuildContext context, DateTime day) {
    final eventosDia = _getEventosDelDia(day);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        if (_loading) {
          return SizedBox(
            height: 200,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (_error != null) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                "Error: $_error",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (eventosDia.isEmpty) {
          return SizedBox(
            height: 200,
            child: const Center(
              child: Text('No hay actividades para este día.'),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: eventosDia.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final actividad = eventosDia[i];
              final fecha = (actividad['fecha'] as Timestamp).toDate();
              final estado = actividad['estado'] ?? '';
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _estadoColor(estado).withAlpha(40),
                    child: Icon(Icons.event_note, color: _estadoColor(estado)),
                  ),
                  title: Text(
                    actividad['descripcion'] ?? 'Sin descripción',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Estado: ${estado.isNotEmpty ? estado[0].toUpperCase() + estado.substring(1).replaceAll('_', ' ') : ''}',
                        style: TextStyle(
                          color: _estadoColor(estado),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hora: ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 29, 77, 235),
            Color.fromARGB(255, 0, 0, 0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      _selectedDay != null &&
                      day.year == _selectedDay!.year &&
                      day.month == _selectedDay!.month &&
                      day.day == _selectedDay!.day,
                  eventLoader: _getEventosDelDia,
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Colors.indigo[400],
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.indigo.withAlpha(80),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.redAccent),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    leftChevronIcon: const Icon(
                      Icons.chevron_left,
                      color: Colors.indigo,
                    ),
                    rightChevronIcon: const Icon(
                      Icons.chevron_right,
                      color: Colors.indigo,
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w600,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _mostrarEventosDelDia(context, selectedDay);
                  },
                  onPageChanged: _onPageChanged,
                ),
              ),
            ),
          ),
          // ¡Ya no hay lista de eventos abajo!
          const Spacer(),
        ],
      ),
    );
  }
}
