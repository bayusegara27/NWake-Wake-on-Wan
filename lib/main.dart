import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    home: PCControlApp(),
    theme: ThemeData(
      primaryColor: Color.fromARGB(248, 255, 255, 255),
    ),
  ));
}

class PCControlApp extends StatefulWidget {
  @override
  _PCControlAppState createState() => _PCControlAppState();
}

class _PCControlAppState extends State<PCControlApp> {
  String? ipAddress;
  int port = 8085;
  String password = "powersw";
  bool isDarkTheme = false;
  bool isEnglish = false;

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ipAddress = prefs.getString('ipAddress') ?? '';
      port = prefs.getInt('port') ?? 8085;
      password = prefs.getString('password') ?? 'powersw';
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      isEnglish = prefs.getBool('isEnglish') ?? false;
    });
  }

  void saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('ipAddress', ipAddress ?? '');
    prefs.setInt('port', port);
    prefs.setString('password', password);
    prefs.setBool('isDarkTheme', isDarkTheme);
    prefs.setBool('isEnglish', isEnglish);
  }

  void showNotification(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.CENTER,
      backgroundColor: Color.fromARGB(255, 78, 155, 255),
    );
  }

  Future<String> checkPCStatus() async {
    try {
      final response = await http.get(
          Uri.parse('http://$ipAddress:$port/getstatus?key=$password'));

      if (response.statusCode == 200) {
        if (response.body == 'Device Online') {
          return isEnglish ? 'Online' : 'Komputer Hidup';
        } else {
          return isEnglish ? 'Offline' : 'Komputer Mati';
        }
      } else {
        return isEnglish
            ? 'Failed to check computer status: ${response.statusCode}'
            : 'Gagal memeriksa status komputer: ${response.statusCode}';
      }
    } catch (e) {
      return isEnglish
          ? 'Error: $e'
          : 'Terjadi kesalahan: $e';
    }
  }

  Future<void> turnOnPC() async {
    final response = await http.get(Uri.parse('http://$ipAddress:$port/short?key=$password'));
    if (response.statusCode == 200) {
      showNotification(isEnglish ? "Computer is turned on" : "Komputer telah diaktifkan");
    } else {
      showNotification(isEnglish ? "Failed to turn on the computer: ${response.statusCode}" : "Gagal mengaktifkan komputer: ${response.statusCode}");
    }
  }

  Future<void> turnOffPC() async {
    final response = await http.get(Uri.parse('http://$ipAddress:$port/long?key=$password'));
    if (response.statusCode == 200) {
      showNotification(isEnglish ? "Computer is turned off" : "Komputer telah dimatikan");
    } else {
      showNotification(isEnglish ? "Failed to turn off the computer: ${response.statusCode}" : "Gagal mematikan komputer: ${response.statusCode}");
    }
  }

  Future<void> showIpDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEnglish ? "IP Address Setup" : "Atur Alamat IP"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEnglish ? "Enter IP Address:" : "Masukkan alamat IP GET:"),
              TextField(
                onChanged: (value) {
                  setState(() {
                    ipAddress = value;
                  });
                },
                decoration: InputDecoration(hintText: isEnglish ? "Example: 192.168.1.X" : "Contoh: 192.168.1.X"),
              ),
              Text(isEnglish ? "Enter port (optional):" : "Masukkan port (opsional):"),
              TextField(
                onChanged: (value) {
                  setState(() {
                    port = int.tryParse(value) ?? 8085;
                  });
                },
                decoration: InputDecoration(hintText: isEnglish ? "default: 8085" : "default: 8085"),
              ),
              Text(isEnglish ? "Enter password (optional):" : "Masukkan password (opsional):"),
              TextField(
                onChanged: (value) {
                  setState(() {
                    password = value;
                  });
                },
                decoration: InputDecoration(hintText: isEnglish ? "default: powersw" : "default: powersw"),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (ipAddress != null && ipAddress!.isNotEmpty) {
                  showNotification(isEnglish ? "IP Address is set." : "Alamat IP GET telah diatur.");
                  saveData();
                }
              },
              child: Text(isEnglish ? "Save" : "Simpan"),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                minimumSize: Size(120, 40),
              ),
            ),
          ],
        );
      },
    );
  }

  void toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme;
      saveData();
    });
  }

  void toggleLanguage() {
    setState(() {
      isEnglish = !isEnglish;
      saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Nwake'),
          actions: [
            IconButton(
              icon: Icon(Icons.lightbulb_outline),
              onPressed: toggleTheme,
            ),
            IconButton(
              icon: Icon(isEnglish ? Icons.language : Icons.translate),
              onPressed: toggleLanguage,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder<String>(
                future: checkPCStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text(
                      isEnglish
                          ? 'Failed to fetch status'
                          : 'Gagal mengambil status',
                      style: TextStyle(color: Colors.red),
                    );
                  } else {
                    return Text(
                      isEnglish ? '${snapshot.data}' : '${snapshot.data}',
                      style: TextStyle(fontSize: 18),
                    );
                  }
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (ipAddress != null && ipAddress!.isNotEmpty) {
                    turnOnPC();
                  } else {
                    showNotification(isEnglish ? "IP Address is not set." : "Alamat IP GET belum diatur.");
                  }
                },
                child: Text(
                  isEnglish ? 'Turn On' : 'Nyalakan',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(255, 13, 218, 41),
                  minimumSize: Size(200, 60),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (ipAddress != null && ipAddress!.isNotEmpty) {
                    turnOffPC();
                  } else {
                    showNotification(isEnglish ? "IP Address is not set." : "Alamat IP GET belum diatur.");
                  }
                },
                child: Text(
                  isEnglish ? 'Turn Off' : 'Matikan',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(255, 216, 42, 19),
                  minimumSize: Size(200, 60),
                ),
              ),
              ElevatedButton(
                onPressed: showIpDialog,
                child: Text(
                  isEnglish ? 'Set IP Address' : 'Atur Alamat IP',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  minimumSize: Size(200, 60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}