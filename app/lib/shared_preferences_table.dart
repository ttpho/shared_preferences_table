import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesTable extends StatefulWidget {
  SharedPreferencesTable({Key key}) : super(key: key);

  @override
  _SharedPreferencesTableState createState() => _SharedPreferencesTableState();
}

class Item {
  final String key;
  final String value;
  final String type;
  const Item({this.key, this.value, this.type});
}

final headerTexts = ["key", "type", "value"];

class _SharedPreferencesTableState extends State<SharedPreferencesTable> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<List<Item>> _futureReadAllPreference() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getKeys().map<Item>((key) {
      final value = prefs.get(key);
      return Item(
        key: key,
        value: value.toString(),
        type: value.runtimeType.toString(),
      );
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(),
        title: Text("Shared Preferences Table"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Item>>(
          future: _futureReadAllPreference(),
          builder: (BuildContext _, AsyncSnapshot<List<Item>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return ConstrainedBox(
                constraints: BoxConstraints.expand(
                    width: MediaQuery.of(context).size.width),
                child: DataTableWidget(
                  listItem: snapshot.data,
                ),
              );
            }
            return const CircularProgressIndicator();
          }),
    );
  }
}

class DataTableWidget extends StatelessWidget {
  final List<Item> listItem;
  DataTableWidget({Key key, @required this.listItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: SingleChildScrollView(
            child: DataTable(
                columns: headerTexts
                    .map<DataColumn>((text) => DataColumn(label: Text(text)))
                    .toList(growable: false),
                rows: listItem
                    .map<DataRow>((item) => DataRow(
                          cells: <DataCell>[
                            DataCell(SelectableText(item.key)),
                            DataCell(SelectableText(item.type)),
                            DataCell(SelectableText(item.value)),
                          ],
                        ))
                    .toList(growable: false))));
  }
}
