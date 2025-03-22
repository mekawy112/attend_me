import 'package:flutter/material.dart';
import 'package:locate_me/widgets/nav_bar.dart';
import 'package:locate_me/screens/face_rec_screen/HomeScreen.dart';

// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: AttendanceScreen(),
//     );
//   }
// }

class AttendanceScreen extends StatelessWidget {
  final List<Map<String, String>> courses = [
    {
      'name': 'Financial Mathematics -T',
      'time': '11:15 - 12:19',
      'code': 'BGS2106',
      'section': 'Lab - 1',
    },
    {
      'name': 'Partnership Accounting -T',
      'time': '09:00 - 11:14',
      'code': 'BGA2103',
      'section': 'Lecture - 1',
    },
    {
      'name': 'Principles Of Marketing -T',
      'time': '12:20 - 13:29',
      'code': 'BGK2101',
      'section': 'Lab - 1',
    },
    {
      'name': 'Principles Of Marketing -T',
      'time': '12:20 - 13:29',
      'code': 'BGK2101',
      'section': 'Lab - 1',
    },
  ];

  AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // فقط شريط تنقل واحد (الأزرق)
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          // إضافة زر للوصول السريع إلى صفحة التعرف على الوجه
          IconButton(
            icon: const Icon(Icons.face),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      // الاحتفاظ بالقائمة الجانبية
      drawer: const NavBar(),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Name
                  Text(
                    'Course Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course['name']} ${course['time']}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Course Code and Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoBox('Course Code', course['code']!),
                      _infoBox('Sec. Num.', course['section']!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Attend Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Attend',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
