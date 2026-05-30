import 'package:flutter/material.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('喂药记录')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            Text('喂药功能 (Plugin Demo)',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('该页面由 MedicationPlugin 动态注册',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
