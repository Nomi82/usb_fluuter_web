import 'package:flutter/material.dart';
import 'main_presenter.dart';
import 'main_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

abstract class MainView {
  void refresh() {}

  void showToast(String message) {}
}

class MainPage extends StatefulWidget {
  MainPage({
    Key? key,
  });

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> implements MainView {
  bool _didInitState = false;
  late MainPresenter presenter;
  late MainViewModel? model;

  @override
  @mustCallSuper
  void didChangeDependencies() {
    if (!_didInitState) {
      afterViewInit();
      _didInitState = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    presenter.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    presenter = MainPresenter(
      MainViewModel(),
      this,
    ).init();
    this.model = this.presenter.viewModel;
  }

  void afterViewInit() {
    presenter.initServices();
    presenter.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WebUSB"),
      ),
      body: model!.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Text(
                        "Web USB supported: " + model!.isSupported.toString()),
                  ),
                  const SizedBox(height: 20.0),
                  if (model!.pairedDevice != null)
                    _buildPairedDeviceInfo()
                  else
                    _buildRequestDeviceButton()
                ],
              ),
            ),
      floatingActionButton: AnimatedOpacity(
        child: FloatingActionButton(
          child: presenter.isDeviceOpen()
              ? const Icon(Icons.close)
              : const Icon(Icons.usb),
          tooltip: "Start session",
          onPressed: () {
            if (presenter.isDeviceOpen()) {
              presenter.closeSession();
            } else {
              presenter.startSession();
            }
          },
        ),
        duration: const Duration(milliseconds: 100),
        opacity: model!.fabIsVisible ? 1 : 0,
      ),
    );
  }

  Widget _buildPairedDeviceInfo() {
    Map<String, dynamic> _deviceInfos = presenter.getPairedDeviceInfo();
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 400,
            child: ListView(
                shrinkWrap: true,
                children: _deviceInfos.keys.map(
                  (String property) {
                    return Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Text(
                            property,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Container(
                          padding:
                              const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
                          child: Text(
                            '${_deviceInfos[property]}',
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                    );
                  },
                ).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDeviceButton() {
    return ElevatedButton(
      onPressed: () {
        return model!.isLoading ? null : presenter.requestDevices();
      },
      child: const Text('Request Device'),
    );
  }

  @override
  void refresh() => setState(() {});

  @override
  void showToast(String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
