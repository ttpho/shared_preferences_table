import 'dart:developer';

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

final _headerTexts = ["key", "type", "value"];
final TextStyle _bold = TextStyle(fontWeight: FontWeight.bold);
final String _title = "Shared Preferences Table";
final String _empty = "Empty";

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

  Future<bool> _clearAllPreferences() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.clear();
  }

  _clearAll() {
    _clearAllPreferences().then((_isCleared) => {setState(() {})});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(),
        title: Text(_title),
        centerTitle: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'clear all',
            onPressed: () => _clearAll(),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
          future: _futureReadAllPreference(),
          builder: (BuildContext _, AsyncSnapshot<List<Item>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              final listItem = snapshot.data;

              return listItem.isEmpty
                  ? Center(child: Text(_empty))
                  : DataTableWidget(
                      listItem: listItem,
                    );
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            return Center(child: const CircularProgressIndicator());
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
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
                columns: _headerTexts
                    .map<DataColumn>(
                        (text) => DataColumn(label: Text(text, style: _bold)))
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
