import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  String _selectedCategory = 'Fuel';

  // Storage for expenses and income
  final Map<DateTime, List<Map<String, dynamic>>> _expenses = {};
  final Map<DateTime, double> _income = {}; // Stores income per day

  // Calculate total expenses for a specific date
  double _calculateTotalExpenses(DateTime date) {
    return _expenses[date]
            ?.fold(0, (sum, item) => sum! + (item['amount'] as double)) ??
        0;
  }

  // Get total income for a specific date
  double _getIncome(DateTime date) {
    return _income[date] ?? 0;
  }

  // Calculate balance (Income - Expense)
  double _calculateBalance(DateTime date) {
    return _getIncome(date) - _calculateTotalExpenses(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to black
      appBar: AppBar(
        title: const Text('Income & Expense Tracker'),
        backgroundColor: Colors.black, // AppBar black for consistency
        foregroundColor: Colors.white, // Ensure text is visible
      ),
      body: Container(
        color: Colors.black, // Set overall background color
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  double total = _calculateTotalExpenses(date);
                  if (total > 0) {
                    return Positioned(
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "\$${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              calendarStyle: const CalendarStyle(
                defaultTextStyle:
                    TextStyle(color: Colors.white), // Calendar day text color
                todayDecoration: BoxDecoration(
                  color: Colors.blue, // Highlight today's date
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.green, // Selected date highlight
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                formatButtonTextStyle: TextStyle(color: Colors.white),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTextField(_incomeController, "Enter Income"),
                  const SizedBox(height: 5),
                  _buildButton("Add Income", Colors.green, () {
                    if (_selectedDay != null &&
                        _incomeController.text.isNotEmpty) {
                      double income =
                          double.tryParse(_incomeController.text) ?? 0;
                      if (income > 0) {
                        setState(() {
                          _income[_selectedDay!] = income;
                          _incomeController.clear();
                        });
                      }
                    }
                  }),
                  const SizedBox(height: 5),
                  _buildTextField(_amountController, "Enter Expense Amount"),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Select Expense Category"),
                    items: [
                      'Fuel',
                      'Food',
                      'Breakfast',
                      'Dinner',
                      'Miscellaneous',
                      'Dress',
                      'EMI',
                      'Credit Card',
                      'Bank Transfer'
                    ]
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 5),
                  _buildButton("Add Expense", Colors.red, () {
                    if (_selectedDay != null &&
                        _amountController.text.isNotEmpty) {
                      double amount =
                          double.tryParse(_amountController.text) ?? 0;
                      if (amount > 0) {
                        setState(() {
                          _expenses[_selectedDay!] =
                              _expenses[_selectedDay!] ?? [];
                          _expenses[_selectedDay!]!.add({
                            'amount': amount,
                            'category': _selectedCategory,
                          });
                          _amountController.clear();
                        });
                      }
                    }
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _selectedDay != null
                  ? Column(
                      children: [
                        _buildText(
                            "Income: \$${_getIncome(_selectedDay!).toStringAsFixed(2)}",
                            Colors.green),
                        _buildText(
                            "Expense: \$${_calculateTotalExpenses(_selectedDay!).toStringAsFixed(2)}",
                            Colors.red),
                        _buildText(
                            "Balance: \$${_calculateBalance(_selectedDay!).toStringAsFixed(2)}",
                            Colors.blue),
                        Expanded(
                          child: _expenses[_selectedDay!] != null
                              ? ListView.builder(
                                  itemCount: _expenses[_selectedDay!]!.length,
                                  itemBuilder: (context, index) {
                                    var expense =
                                        _expenses[_selectedDay!]![index];
                                    return ListTile(
                                      title: Text(
                                        "${expense['category']}: \$${expense['amount'].toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _expenses[_selectedDay!]!
                                                .removeAt(index);
                                          });
                                        },
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Text(
                                      "No expenses recorded for this day",
                                      style: TextStyle(color: Colors.white)),
                                ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text("Select a date to view transactions",
                          style: TextStyle(color: Colors.white)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to style text fields
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  // Helper method to create buttons with color
  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

  // Helper method for consistent input decoration
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      border:
          const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      enabledBorder:
          const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      focusedBorder:
          const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
    );
  }

  // Helper method for consistent text styling
  Widget _buildText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
    );
  }
}
