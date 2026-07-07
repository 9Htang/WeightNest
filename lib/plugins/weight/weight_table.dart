import 'package:flutter/material.dart';
import '../../database/database.dart';

/// 体重记录列表。接收外部已加载的 [weights]，避免与上层图表组件重复查询同一只鸟。
class WeightTable extends StatelessWidget {
  /// 体重记录列表（按 recordedAt 倒序），由父组件通过 [db.getByBird] 加载后传入。
  final List<Weight> weights;

  const WeightTable({super.key, required this.weights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (weights.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
            child: Text('暂无体重记录', style: TextStyle(color: Colors.grey))),
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
                  child: Icon(Icons.trending_down,
                      size: 14, color: Colors.red.shade400),
                )
              else
                const SizedBox(width: 20),
              Expanded(
                child: Text(
                  w.recordedAt
                      .toString()
                      .substring(0, 19)
                      .replaceAll('T', ' '),
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
                      : (w.isFasting
                          ? theme.colorScheme.primary
                          : Colors.orange),
                ),
              ),
              if (!w.isFasting)
                const Text(' *',
                    style: TextStyle(fontSize: 11, color: Colors.orange)),
            ]),
          );
        },
      ),
    );
  }
}
