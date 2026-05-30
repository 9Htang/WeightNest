import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../repositories/weight_repository.dart';

class WeightTable extends StatelessWidget {
  final AppDatabase db;
  final int birdId;

  const WeightTable({super.key, required this.db, required this.birdId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Weight>>(
      future: db.getByBird(birdId),
      builder: (context, snapshot) {
        final weights = snapshot.data ?? [];
        if (weights.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('暂无体重记录', style: TextStyle(color: Colors.grey))),
          );
        }
        return SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: weights.length,
            itemBuilder: (context, i) {
              final w = weights[i];
              final prev = i + 1 < weights.length ? weights[i + 1] : null;
              final isDecline = prev != null && w.weightG < prev.weightG;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  if (isDecline)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.trending_down, size: 14, color: Colors.red.shade400),
                    )
                  else
                    const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      w.recordedAt.toString().substring(0, 19).replaceAll('T', ' '),
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${w.weightG.toStringAsFixed(1)} g',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDecline
                          ? Colors.red.shade700
                          : (w.isFasting ? theme.colorScheme.primary : Colors.orange),
                    ),
                  ),
                  if (!w.isFasting) const Text(' *', style: TextStyle(fontSize: 11, color: Colors.orange)),
                ]),
              );
            },
          ),
        );
      },
    );
  }
}
