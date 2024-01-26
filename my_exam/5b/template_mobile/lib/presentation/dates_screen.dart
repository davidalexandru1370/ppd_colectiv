import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:template_mobile/common/utilities.dart';
import 'package:template_mobile/domain/Task.dart';
import 'package:template_mobile/presentation/add_task.dart';
import 'package:template_mobile/presentation/widgets/toast.dart';
import 'package:template_mobile/service/service.dart';
import 'package:template_mobile/service/web_socket.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../persistence/Repository.dart';

import '../service/network.dart';
import 'tasks_screen.dart';

class DatesScreen extends StatelessWidget {
  const DatesScreen({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _CategoriesScreen(),
    );
  }
}

class _CategoriesScreen extends StatefulWidget {
  const _CategoriesScreen({super.key});

  @override
  State<_CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<_CategoriesScreen> {
  bool _isLoading = true;
  bool _isOnline = false;
  List<String> dates = [];
  late Repository repository;
  late FitnessService itemService;
  var connectivity = ConnectivityResult.none;
  final WebSocketConnection _webSocketConnection = WebSocketConnection.instance;
  final NetworkConnectivity _connectivity = NetworkConnectivity.instance;
  late FToast fToast;

  @override
  void initState() {
    repository = Repository();
    itemService = FitnessService();
    fToast = FToast();
    fToast.init(context);
    connection();

    fetchDates();

    try {
      _webSocketConnection.listen(
          (data) {
            var json = jsonDecode(data);
            var item = Task.fromMap(json);
            print("Received item" + item.toString());
            // Fluttertoast.showToast(
            //     msg: "Received item" + item.toString(),
            //     toastLength: Toast.LENGTH_LONG,
            //
            //     backgroundColor: Colors.green,
            //     gravity: ToastGravity.TOP);
            var fancyText = "Received new item: \n" + item.toString();
            fToast.showToast(child: MyToast.getToast(fancyText));
            repository.insert(item.toMap(), Utilities.principalTable);
          },
          () {},
          () {},
          (status) {
            if(mounted == false){
              return;
            }
            setState(() {
              _isOnline = status;
            });
          });
    } catch (e) {
      print(e);
    }
  }

  void fetchDates() {
    try {
      itemService.getAllDates().then((value) {
        setState(() {
          dates = value;
          _isLoading = false;
        });
        repository.deleteAll(Utilities.secondTable);
        for (var element in value) {
          Map<String, dynamic> map = {"${Utilities.secondTable}": element};

          repository.insert(map, Utilities.secondTable);
        }
      }).onError((error, stackTrace) {
        print(error);
        repository.getAllDates().then((value) {
          setState(() {
            dates = value;
            _isLoading = false;
          });
        });
      });
    } catch (e) {
      print(e);
    }
  }

  void connection() {
    _connectivity.initialize();
    _connectivity.myStream.listen((event) {
      print(event);
      setState(() {
        connectivity = event.keys.first;
        if (event.keys.first == ConnectivityResult.none) {
          _isOnline = false;
        } else {
          _isOnline = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AddTask()));
          },
          tooltip: 'Add Task',
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text("  Online "),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: _isOnline ? Colors.green : Colors.red,
                      shape: BoxShape.circle),
                ),
              ]),
              _isOnline == false
                  ? ElevatedButton(
                      onPressed: () {
                        fetchDates();
                      },
                      child: const Icon(Icons.change_circle))
                  : const SizedBox()
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(

                height: MediaQuery.of(context).size.height,
                child: ListView.builder(
                  itemCount: dates.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 10),
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  TaskScreen(date: dates[index])),
                        );
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.black45)),
                      title: Text(dates[index]),
                    );
                  },
                ),
              ));
  }
}
