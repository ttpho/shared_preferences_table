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
  @override
  String toString() {
    return key + "#" + type + "#" + value;
  }

  Item copyWith({
    String key,
    String value,
    String type,
  }) =>
      Item(
        key: key ?? this.key,
        value: value ?? this.value,
        type: type ?? this.type,
      );

  Item clone() => Item(key: this.key, value: this.value, type: this.type);
}

final _headerTexts = ["key", "type", "value"];
final TextStyle _bold = TextStyle(fontWeight: FontWeight.bold);
final String _title = "Shared Preferences Table";
final String _empty = "Empty";
final _itemDefault = Item(key: '', value: '', type: 'String');
final _mapRunTimeTypeTextInputType = <String, TextInputType>{
  'String': TextInputType.text,
  'double': TextInputType.number,
  'int': TextInputType.number,
  'bool': TextInputType.text,
  'List<String>': TextInputType.multiline,
};

final _mapRunTimeTypeDefaultValue = <String, String>{
  'String': '',
  'double': '1.0',
  'int': '1',
  'bool': 'false',
  'List<String>': '',
};

enum Manipulation { add, edit, delete, deleteAll }

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
    return SharedPreferencesManipulationFactory.run(
        Manipulation.deleteAll, prefs, null);
  }

  _onClearAll() {
    _clearAllPreferences().then((_isCleared) => {setState(() {})});
  }

  _onAddNew(BuildContext context) async {
    final addItem = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SharedPreferencesForm(
                title: 'Add new',
                item: null,
              )),
    );
    if (addItem == null) return;
    final SharedPreferences prefs = await _prefs;

    SharedPreferencesManipulationFactory.run(Manipulation.add, prefs, addItem)
        .then((value) => setState(() {}));
  }

  _onEditItem(final BuildContext context, final Item item) async {
    final editItem = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SharedPreferencesForm(
                title: 'Edit',
                item: item,
              )),
    );
    if (editItem == null) return;

    final SharedPreferences prefs = await _prefs;

    SharedPreferencesManipulationFactory.run(Manipulation.edit, prefs, editItem)
        .then((value) => setState(() {}));
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
            icon: const Icon(Icons.add),
            tooltip: 'add new',
            onPressed: () => _onAddNew(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'clear all',
            onPressed: () => _onClearAll(),
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
                      onSelectedItem: (item) => {_onEditItem(context, item)},
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
  final Function(Item) onSelectedItem;
  const DataTableWidget(
      {Key key, @required this.listItem, @required this.onSelectedItem})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
                showCheckboxColumn: false,
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
                          onSelectChanged: (selected) {
                            if (selected) {
                              onSelectedItem.call(item);
                            }
                          },
                          cells: <DataCell>[
                            DataCell(SelectableText(item.key)),
                            DataCell(SelectableText(item.type)),
                            DataCell(SelectableText(item.value)),
                          ],
                        ))
                    .toList(growable: false))));
  }
}

class SharedPreferencesForm extends StatefulWidget {
  final Item item;
  final String title;
  const SharedPreferencesForm(
      {Key key, @required this.title, @required this.item})
      : super(key: key);
  @override
  _SharedPreferencesFromState createState() => _SharedPreferencesFromState();
}

class _SharedPreferencesFromState extends State<SharedPreferencesForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllerKey = TextEditingController();
  final _controllerValue = TextEditingController();
  bool newBoolValue = false;
  Item _itemUpdated;

  _onTypeSelected(final String newType) {
    setState(() {
      _itemUpdated = _itemUpdated.copyWith(
          type: newType, value: _mapRunTimeTypeDefaultValue[newType]);
    });
  }

  _onValueChanged(final String value) {
    setState(() {
      _itemUpdated = _itemUpdated.copyWith(value: value);
    });
  }

  _onKeyChanged(final String value) {
    setState(() {
      _itemUpdated = _itemUpdated.copyWith(key: value);
    });
  }

  _getKeyboardType() =>
      _mapRunTimeTypeTextInputType[_itemUpdated.type] ?? TextInputType.text;
  _getMaxLines() => _itemUpdated.type == 'List<String>' ? 5 : 1;

  bool _isValid() {
    return _itemUpdated.key.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _itemUpdated = widget.item != null ? widget.item.clone() : _itemDefault;
    _controllerKey.text = _itemUpdated.key ?? "";
    _controllerKey.addListener(() => _onKeyChanged(_controllerKey.text));
    _controllerValue.text = _itemUpdated.value ?? "";
    _controllerValue.addListener(() => _onValueChanged(_controllerValue.text));
    newBoolValue = _itemUpdated.key == 'bool' && _itemUpdated.value == 'true';
  }

  @override
  void dispose() {
    _controllerKey.dispose();
    _controllerValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: CloseButton(),
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: _isValid()
                  ? const Icon(Icons.save)
                  : const Icon(
                      Icons.save,
                      color: Colors.grey,
                    ),
              tooltip: 'save',
              onPressed: () =>
                  {if (_isValid()) Navigator.pop(context, _itemUpdated)},
            ),
          ],
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Key',
                        style: _bold,
                      ),
                      TextField(
                        controller: _controllerKey,
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      Text(
                        'Runtime Type',
                        style: _bold,
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      RuntimeTypeWidget(
                          initType: _itemUpdated.type,
                          allRunTimeType: _mapRunTimeTypeTextInputType.keys
                              .toList(growable: false),
                          onTypeSelected: _onTypeSelected),
                      const SizedBox(
                        height: 16.0,
                      ),
                      Text(
                        'Value',
                        style: _bold,
                      ),
                      _itemUpdated.type != 'bool'
                          ? TextField(
                              controller: _controllerValue,
                              maxLines: _getMaxLines(),
                              keyboardType: _getKeyboardType())
                          : Row(
                              children: [
                                Container(
                                  width: 48.0,
                                  child: Text(newBoolValue.toString()),
                                ),
                                Switch(
                                  value: newBoolValue,
                                  onChanged: (bool newValue) {
                                    setState(() {
                                      newBoolValue = newValue;
                                    });
                                    _onValueChanged(newValue.toString());
                                  },
                                )
                              ],
                            ),
                    ]))));
  }
}

class RuntimeTypeWidget extends StatefulWidget {
  final List<String> allRunTimeType;
  final String initType;
  final Function(String) onTypeSelected;
  RuntimeTypeWidget(
      {Key key,
      @required this.allRunTimeType,
      @required this.initType,
      @required this.onTypeSelected})
      : super(key: key);

  @override
  _RuntimeTypeWidgetState createState() => _RuntimeTypeWidgetState();
}

class _RuntimeTypeWidgetState extends State<RuntimeTypeWidget> {
  String _dropdownValue = 'String';
  @override
  void initState() {
    super.initState();
    _dropdownValue = widget.initType;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> list = widget.allRunTimeType;
    return DropdownButton<String>(
      isExpanded: true,
      value: _dropdownValue,
      underline: Container(
        height: 2,
        color: Theme.of(context).primaryColor,
      ),
      onChanged: (String newValue) {
        widget.onTypeSelected?.call(newValue);
        setState(() {
          _dropdownValue = newValue;
        });
      },
      items: list.map<DropdownMenuItem<String>>((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}

class SharedPreferencesFactory {
  static Map<String, Operator> _mapRunTimeType = <String, Operator>{
    'String': StringOperator(),
    'double': DoubleOperator(),
    'int': IntOperator(),
    'bool': BoolOperator(),
    'List<String>': ListStringOperator(),
  };
  static Operator makeOperator(final String type) => _mapRunTimeType[type];

  static Future<bool> setValue(final SharedPreferences prefs, final String key,
      final String type, final String value) {
    final Operator op = makeOperator(type);
    if (op != null) {
      return op.setValue(prefs, key, value);
    }
    throw 'Error::No Operator implement';
  }
}

class SharedPreferencesManipulationFactory {
  static Future<bool> run(final Manipulation manipulation,
      final SharedPreferences prefs, final Item item) async {
    switch (manipulation) {
      case Manipulation.add:
        return add(prefs, item.key, item.type, item.value);
      case Manipulation.edit:
        return edit(prefs, item.key, item.type, item.value);
      case Manipulation.delete:
        return delete(prefs, item.key);
      case Manipulation.deleteAll:
        return deleteAll(prefs);
      default:
        return false;
    }
  }

  static Future<bool> add(final SharedPreferences prefs, final String key,
      final String type, final String value) {
    return SharedPreferencesFactory.setValue(prefs, key, type, value);
  }

  static Future<bool> delete(
    final SharedPreferences prefs,
    final String key,
  ) =>
      prefs.remove(key);

  static Future<bool> edit(final SharedPreferences prefs, final String key,
      final String type, final String value) async {
    final isDeleteSuccess = await delete(prefs, key);
    return isDeleteSuccess ? add(prefs, key, type, value) : false;
  }

  static Future<bool> deleteAll(final SharedPreferences prefs) => prefs.clear();
}

abstract class Operator {
  Future<bool> setValue(
      final SharedPreferences prefs, final String key, final String value);
}

class StringOperator extends Operator {
  @override
  Future<bool> setValue(SharedPreferences prefs, String key, String value) {
    return prefs.setString(key, value);
  }
}

class IntOperator extends Operator {
  @override
  Future<bool> setValue(SharedPreferences prefs, String key, String value) {
    return prefs.setInt(key, int.parse(value));
  }
}

class DoubleOperator extends Operator {
  @override
  Future<bool> setValue(SharedPreferences prefs, String key, String value) {
    return prefs.setDouble(key, double.parse(value));
  }
}

class BoolOperator extends Operator {
  @override
  Future<bool> setValue(SharedPreferences prefs, String key, String value) {
    return prefs.setBool(key, value == 'true');
  }
}

class ListStringOperator extends Operator {
  @override
  Future<bool> setValue(SharedPreferences prefs, String key, String value) {
    final listStringValue = value.split('\n').toList(growable: false);
    return prefs.setStringList(key, listStringValue);
  }
}
