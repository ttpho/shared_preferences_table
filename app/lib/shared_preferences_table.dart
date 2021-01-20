import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:core';

// map menthod with index is 2nd param
// Source: https://stackoverflow.com/a/60502389
// By: https://stackoverflow.com/users/1321917/andrey-gordeev
extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}

class Item {
  final String key;
  final String value;
  final String type;
  const Item({this.key, this.value, this.type});
}

final headerTexts = ["key", "type", "value"];
final TextStyle bold = TextStyle(fontWeight: FontWeight.bold);
final String title = "Shared Preferences Table";

class SharedPreferencesTable extends StatefulWidget {
  SharedPreferencesTable({Key key}) : super(key: key);

  @override
  _SharedPreferencesTableState createState() => _SharedPreferencesTableState();
}

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
        title: Text(title),
        centerTitle: false,
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
                    .map<DataColumn>(
                        (text) => DataColumn(label: Text(text, style: bold)))
                    .toList(growable: false),
                rows: listItem
                    .mapIndexed<DataRow>((item, index) => DataRow(
                          color: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                            final isSelected =
                                states.contains(MaterialState.selected);
                            final colorRow = index % 2 == 0
                                ? Colors.grey.withOpacity(0.1)
                                : null;
                            return isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.08)
                                : colorRow;
                          }),
                          cells: <DataCell>[
                            DataCell(SelectableText(item.key)),
                            DataCell(SelectableText(item.type)),
                            DataCell(SelectableText(item.value)),
                          ],
                        ))
                    .toList(growable: false))));
  }
}
