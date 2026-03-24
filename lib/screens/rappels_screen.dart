import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class RappelsScreen extends StatefulWidget {
  const RappelsScreen({super.key});

  @override
  State<RappelsScreen> createState() => _RappelsScreenState();
}

class _RappelsScreenState extends State<RappelsScreen> {
  final NotificationService _notifications = NotificationService();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _message = 'Rappel de paiement de cotisation';
  bool _isLoading = false;

  Future<void> _programmerRappel() async {
    setState(() => _isLoading = true);

    final scheduledDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date doit être dans le futur'), backgroundColor: Colors.orange),
      );
      setState(() => _isLoading = false);
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch % 100000;

    await _notifications.scheduleNotification(
      id: id,
      title: 'Rappel Tontine',
      body: _message,
      scheduledDate: scheduledDate,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rappel programmé avec succès'), backgroundColor: Colors.green),
    );

    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programmer un rappel'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Message
            TextFormField(
              initialValue: _message,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              onChanged: (value) => _message = value,
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.green),
              title: const Text('Date'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),

            // Heure
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.green),
              title: const Text('Heure'),
              subtitle: Text(_selectedTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),

            const SizedBox(height: 24),

            // Bouton
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _programmerRappel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('PROGRAMMER LE RAPPEL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}