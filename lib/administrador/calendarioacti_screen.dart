import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarAdminScreen extends StatefulWidget {
  const CalendarAdminScreen({super.key});

  @override
  State<CalendarAdminScreen> createState() => _CalendarAdminScreenState();
}

class _CalendarAdminScreenState extends State<CalendarAdminScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// Función para mostrar el modal con las actividades del día
  void _mostrarActividadesDia(
    BuildContext context,
    List<Map<String, dynamic>> actividades,
    ThemeData theme,
    DateTime dia,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        if (actividades.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                "No hay actividades para este día.",
                style: theme.textTheme.bodyLarge,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Actividades del ${dia.day}/${dia.month}/${dia.year}",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                itemCount: actividades.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final actividad = actividades[i];
                  final fecha = (actividad['fecha'] as Timestamp).toDate();
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white.withAlpha(230),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo[100],
                        child: Icon(
                          Icons.event_note,
                          color: theme.colorScheme.primary,
                        ),
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
                            'Colaborador: ${actividad['colaborador'] ?? 'Sin asignar'}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          Text(
                            'Estado: ${actividad['estado'] ?? ''}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          Text(
                            'Hora: ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Calendario de Actividades'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
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
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('actividades')
                .orderBy('fecha')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Construye el mapa de eventos para TODOS los días con actividades
              final eventos = <DateTime, List<Map<String, dynamic>>>{};
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final fecha = (data['fecha'] as Timestamp).toDate();
                final dia = DateTime(fecha.year, fecha.month, fecha.day);
                eventos.putIfAbsent(dia, () => []).add(data);
              }

              List<Map<String, dynamic>> getEventosDelDia(DateTime day) {
                final dia = DateTime(day.year, day.month, day.day);
                return eventos[dia] ?? [];
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                          eventLoader: getEventosDelDia,
                          calendarStyle: CalendarStyle(
                            markerDecoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(80),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            weekendTextStyle: const TextStyle(
                              color: Colors.redAccent,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: theme.colorScheme.primary,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            weekendStyle: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            // Llama al modal sólo si hay datos cargados:
                            final eventosDia = getEventosDelDia(selectedDay);
                            _mostrarActividadesDia(
                              context,
                              eventosDia,
                              theme,
                              selectedDay,
                            );
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                              _selectedDay = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  // Ya NO hay lista de eventos abajo:
                  const Spacer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
