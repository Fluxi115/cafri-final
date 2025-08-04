import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardMetricasActividades extends StatelessWidget {
  final String? nombre;
  final String? apellido;
  final String? titulo;

  const DashboardMetricasActividades({
    super.key,
    this.nombre,
    this.apellido,
    this.titulo,
  });

  Future<Map<String, int>> _contarPorEstado() async {
    Query query = FirebaseFirestore.instance.collection('actividades');
    if (nombre != null &&
        nombre!.isNotEmpty &&
        apellido != null &&
        apellido!.isNotEmpty) {
      query = query
          .where('name', isEqualTo: nombre)
          .where('lastName', isEqualTo: apellido);
    }
    final snapshot = await query.get();
    final counts = <String, int>{
      'pendiente': 0,
      'aceptada': 0,
      'en_proceso': 0,
      'pausada': 0,
      'terminada': 0,
    };
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data is Map<String, dynamic>) {
        final estado = (data['estado'] ?? 'pendiente').toString();
        if (counts.containsKey(estado)) {
          counts[estado] = (counts[estado] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _contarPorEstado(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error al cargar métricas: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final counts = snapshot.data ?? {};
        final total = counts.values.fold<int>(0, (a, b) => a + b);

        // Colores y etiquetas para el gráfico
        final estados = [
          {'label': 'Pendientes', 'key': 'pendiente', 'color': Colors.orange},
          {'label': 'Aceptadas', 'key': 'aceptada', 'color': Colors.blue},
          {
            'label': 'En proceso',
            'key': 'en_proceso',
            'color': Colors.amber[800],
          },
          {'label': 'Pausadas', 'key': 'pausada', 'color': Colors.deepOrange},
          {'label': 'Terminadas', 'key': 'terminada', 'color': Colors.green},
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (titulo != null && titulo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bar_chart,
                        color: Colors.indigo,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        titulo!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              Card(
                elevation: 2,
                color: Colors.indigo.withAlpha(18),
                margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 18,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.summarize,
                        color: Colors.indigo,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Total actividades: ",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.indigo[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "$total",
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Pie Chart
              if (total > 0)
                Center(
                  child: SizedBox(
                    height: 220,
                    width: 220,
                    child: PieChart(
                      PieChartData(
                        sections: estados.map((estado) {
                          final key = estado['key'] as String;
                          final color = estado['color'] as Color?;
                          final value = counts[key] ?? 0;
                          final percent = total > 0
                              ? (value / total * 100)
                              : 0.0;
                          return PieChartSectionData(
                            color: color,
                            value: value.toDouble(),
                            title: value > 0
                                ? '${percent.toStringAsFixed(1)}%'
                                : '',
                            radius: value > 0 ? 60 : 50,
                            titleStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ),
              if (total > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    children: estados.map((estado) {
                      final key = estado['key'] as String;
                      final color = estado['color'] as Color?;
                      final label = estado['label'] as String;
                      final value = counts[key] ?? 0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$label ($value)',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricCard(
                      label: 'Pendientes',
                      count: counts['pendiente'] ?? 0,
                      color: Colors.orange,
                      icon: Icons.hourglass_empty,
                      bgColor: Colors.orange.withAlpha(30),
                    ),
                    _buildMetricCard(
                      label: 'Aceptadas',
                      count: counts['aceptada'] ?? 0,
                      color: Colors.blue,
                      icon: Icons.check_circle_outline,
                      bgColor: Colors.blue.withAlpha(30),
                    ),
                    _buildMetricCard(
                      label: 'En proceso',
                      count: counts['en_proceso'] ?? 0,
                      color: Colors.amber[800]!,
                      icon: Icons.play_circle_outline,
                      bgColor: Colors.amber.withAlpha(30),
                    ),
                    _buildMetricCard(
                      label: 'Pausadas',
                      count: counts['pausada'] ?? 0,
                      color: Colors.deepOrange,
                      icon: Icons.pause_circle_outline,
                      bgColor: Colors.deepOrange.withAlpha(30),
                    ),
                    _buildMetricCard(
                      label: 'Terminadas',
                      count: counts['terminada'] ?? 0,
                      color: Colors.green,
                      icon: Icons.verified,
                      bgColor: Colors.green.withAlpha(30),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 6,
        color: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          width: 130,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
