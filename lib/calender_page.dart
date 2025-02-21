import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  String _selectedCategory = 'Fuel'; // Default category
  Map<DateTime, List<Map<String, dynamic>>> _expenses = {};
  Map<String, double> _monthlyIncome = {}; // Store income by month

  final List<String> _categories = [
    'Fuel',
    'Medicine',
    'Tea',
    'EMI',
    'SIP',
    'Shopping',
    'Food',
    'Transport',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final expenseData = prefs.getString('expenses');
    final incomeData = prefs.getString('income');

    if (expenseData != null) {
      Map<String, dynamic> decodedExpenses = jsonDecode(expenseData);
      setState(() {
        _expenses = decodedExpenses.map((key, value) => MapEntry(
            DateTime.parse(key), List<Map<String, dynamic>>.from(value)));
      });
    }

    if (incomeData != null) {
      setState(() {
        _monthlyIncome = Map<String, double>.from(jsonDecode(incomeData));
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedExpenses = jsonEncode(
        _expenses.map((key, value) => MapEntry(key.toIso8601String(), value)));
    String encodedIncome = jsonEncode(_monthlyIncome);

    await prefs.setString('expenses', encodedExpenses);
    await prefs.setString('income', encodedIncome);
  }

  void _addIncome() {
    if (_incomeController.text.isNotEmpty) {
      double income = double.tryParse(_incomeController.text) ?? 0;
      if (income > 0) {
        setState(() {
          String monthKey = '${_focusedDay.year}-${_focusedDay.month}';
          _monthlyIncome[monthKey] = income;
          _incomeController.clear();
          _saveData();
        });
      }
    }
  }

  void _addExpense() {
    if (_selectedDay != null && _amountController.text.isNotEmpty) {
      double amount = double.tryParse(_amountController.text) ?? 0;
      if (amount > 0) {
        setState(() {
          _expenses[_selectedDay!] = _expenses[_selectedDay!] ?? [];
          _expenses[_selectedDay!]!.add({
            'amount': amount,
            'category': _selectedCategory,
          });
          _amountController.clear();
          _saveData();
        });
      }
    }
  }

  double _calculateTotalExpenses(DateTime date) {
    return _expenses[date]
            ?.fold(0, (sum, item) => sum! + (item['amount'] as double)) ??
        0;
  }

  double _calculateMonthlyExpenses(DateTime month) {
    double total = 0;
    _expenses.forEach((date, expenses) {
      if (date.year == month.year && date.month == month.month) {
        total += _calculateTotalExpenses(date);
      }
    });
    return total;
  }

  double _getMonthlyIncome(DateTime month) {
    String monthKey = '${month.year}-${month.month}';
    return _monthlyIncome[monthKey] ?? 0;
  }

  double _calculateMonthlyBalance(DateTime month) {
    double income = _getMonthlyIncome(month);
    double expenses = _calculateMonthlyExpenses(month);
    return income - expenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
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
            calendarStyle: const CalendarStyle(
              defaultTextStyle:
                  TextStyle(color: Color.fromARGB(255, 253, 253, 253)),
              todayDecoration: BoxDecoration(
                color: Color.fromARGB(255, 225, 112, 112),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color.fromARGB(255, 77, 109, 233),
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white),
              weekendStyle: TextStyle(color: Colors.white),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                double totalExpense = _calculateTotalExpenses(date);
                return totalExpense > 0
                    ? Positioned(
                        bottom: 1,
                        child: Text(
                          '\$${totalExpense.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Color.fromARGB(255, 73, 189, 60),
                              fontSize: 12),
                        ),
                      )
                    : null;
              },
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Income Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _incomeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Enter Monthly Income",
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 73, 189, 60),
                      ),
                      onPressed: _addIncome,
                      child: const Text("Set Income"),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Expense Section
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Enter Expense Amount",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 2),
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.black,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    alignment: Alignment.center,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items: _categories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Center(
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: "Select Category",
                      labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 160, 40, 40),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 240, 238, 238)),
                  onPressed: _addExpense,
                  child: const Text("Add Expense"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: _selectedDay != null
                ? Column(
                    children: [
                      Text(
                        "Daily Expenses: \$${_calculateTotalExpenses(_selectedDay!).toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, color: Colors.red),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _expenses[_selectedDay!]?.length ?? 0,
                          itemBuilder: (context, index) {
                            var expense = _expenses[_selectedDay!]![index];
                            return ListTile(
                              title: Text(
                                "${expense['category']}: \$${expense['amount'].toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Text("Select a date to view expenses",
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255))),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Monthly Income: \$${_getMonthlyIncome(_focusedDay).toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
                Text(
                  "Monthly Expenses: \$${_calculateMonthlyExpenses(_focusedDay).toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                ),
                Text(
                  "Monthly Balance: \$${_calculateMonthlyBalance(_focusedDay).toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 18,
                    color: _calculateMonthlyBalance(_focusedDay) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
