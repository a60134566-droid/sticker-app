import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Печать стикеров',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Список всех вариантов стикеров
  final List<String> stickerOptions = const [
    '1', '1L', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11',
    '12', '12L', '12SL', '13', '14', '15', '16', '17', '18', '19',
    '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Печать стикеров')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.print, size: 40),
          label: const Text('Напечатать стикер', style: TextStyle(fontSize: 24)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: () => _showStickerSelection(context),
        ),
      ),
    );
  }

  void _showStickerSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Выберите цифру', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 колонки на телефоне
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    padding: const EdgeInsets.all(16),
                  ),
                  itemCount: stickerOptions.length,
                  itemBuilder: (context, index) {
                    final option = stickerOptions[index];
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue[200]!),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Закрыть выбор цифры
                        _showQuantityDialog(context, option);
                      },
                      child: Text(option, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, String selectedSticker) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Стикер: $selectedSticker'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle, size: 36, color: Colors.red),
                    onPressed: () => setState(() { if (quantity > 1) quantity--; }),
                  ),
                  Text('$quantity', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 36, color: Colors.green),
                    onPressed: () => setState(() { quantity++; }),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendPrintCommand(selectedSticker, quantity);
                  },
                  child: const Text('Печать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendPrintCommand(String stickerText, int quantity) async {
    // ⚠️ ЗАМЕНИТЕ НА РЕАЛЬНЫЙ IP-АДРЕС ПРИНТЕРА (тот, что вы проверили ping-ом)
    final String printerIp = '10.84.60.233'; 
    
    // Формируем TSPL-команду. TEXT выводит строку (цифру или модификатор)
    final String tsplCommand = '''
SIZE 50 mm, 30 mm
GAP 2 mm, 0 mm
CLS
TEXT 50, 50, "3", 0, 1, 1, "$stickerText"
PRINT 1, $quantity
''';

    try {
      final socket = await Socket.connect(printerIp, 9100, timeout: const Duration(seconds: 3));
      socket.write(tsplCommand);
      await socket.flush();
      socket.destroy();
      
      // Показать уведомление об успехе
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Задание на печать отправлено ($quantity шт.)')),
        );
      }
    } catch (e) {
      // Показать уведомление об ошибке
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
