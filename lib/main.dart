import 'package:flutter/material.dart';
import 'dart:async';

import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<KeyValue> list = [];
  List<LdapModel> dataList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _callLDAP();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: dataList.length > 0
            ? ListView.builder(
                itemCount: dataList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    margin: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Center(
                          child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Person : ${dataList[index].title}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                        ),
                        ...List.generate(
                            dataList[index].data.length,
                            (innerIndex) =>
                                _getListItem(dataList[index].data[innerIndex]))
                      ],
                    ),
                  );
                })
            : SizedBox());
  }

  _getListItem(KeyValue keyValue) {
    return Container(
        alignment: Alignment.topLeft,
        margin: EdgeInsets.all(5),
        // padding: EdgeInsets.all(8),
        child: Text('${keyValue.key}' + ' : ' + '${keyValue.value}'));
  }

  Future<void> _callLDAP() async {
    Logger.root.onRecord.listen((LogRecord r) {
      print('=====> ${r.time}: ${r.loggerName}: ${r.level.name}: ${r.message}');
    });

    Logger.root.level = Level.FINE;

    await example();
  }

  // var base = 'cn=janubavam,ou=people,dc=localhost,dc=net'; // to get one user details
  var base = 'ou=people,dc=localhost,dc=net'; // to get all user details
  var filter = Filter.present('objectClass');
// var attrs = [
//   'dn',
//   'uid',
//   'cn',
//   'name',
//   'sn', // last name
//   'mail',
//   'mobile',
//   'telephoneNumber',
// ];

  Future example() async {
    // var bindDN = 'cn=admin';
    // var password = 'Admin321!';
    var host = 'ldap.localhost.net';
    // var host = '172.20.20.137';
    // var bindDN = 'cn=janubavam,ou=people,dc=localhost,dc=net';
    var bindDN = 'cn=admin,dc=localhost,dc=net';
    var password = 'Admin321!';
    // var bindDN = 'cn=janubavam';
    // var password = 'Anubavam123!';

    var connection = LdapConnection(
        host: host, ssl: false, bindDN: bindDN, password: password);

    try {
      print('Connection to open');
      await connection.open();
      // Perform search operation
      print('Connection before bind');
      await connection.bind();
      print('Bind OK');

      print('******* before search');

      // await _modifyData(connection);

      await _doSearch(connection);

      print('******* after search');
    } catch (e, stacktrace) {
      print('********* Exception: $e $stacktrace');
    } finally {
      // Close the connection when finished with it
      print('Closing');
      await connection.close();
    }
  }

  Future<void> _doSearch(LdapConnection connection) async {
    print('inside search');
    // var searchResult = await connection.search(base, filter, attrs, sizeLimit: 2);
    var searchResult = await connection.query(base, '(objectclass=*)', []);
    print('Search returned ${searchResult.stream}');

    await for (var entry in searchResult.stream) {
      // Processing stream of SearchEntry
      print('dn: ${entry.dn}');

      // Getting all attributes returned

      for (var attr in entry.attributes.values) {
        String title = '';
        if (attr.name == 'givenName') title = attr.values.first;
        print('-----> title : $title');
        for (var value in attr.values) {
          // attr.values is a Set
          print('attrs ===>  ${attr.name}: $value');
          list.add(KeyValue(attr.name, value));
        }
        if (title != '') dataList.add(LdapModel(title, list));
      }
    }

    var sr = await searchResult.getLdapResult();
    print('===> LDAP result: $sr');
    setState(() {});
  }

  Future<void> _modifyData(LdapConnection connection) async {
    try {
      var mod1 = new Modification.replace("mail", ["testing1@gmail.com"]);
      await connection.modify(base, [mod1]);
    } on LdapResultObjectClassViolationException catch (_) {
      // cannot modify entry because it would violate the schema rules
      print('result exception');
    } on LdapException catch (e) {
      // some other problem
      print('exception : $e');
    }
  }
}

class LdapModel {
  String title;
  List<KeyValue> data;

  LdapModel(this.title, this.data);
}

class KeyValue {
  String key;
  String value;

  KeyValue(this.key, this.value);
}
