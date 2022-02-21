import 'package:flutter/material.dart';

import '../state_store.dart';

typedef StoreCreator<T extends Store> = T Function();

class _StoreDelegate<T extends Store> {
  final StoreCreator<T> creator;
  StoreProviderElement<T>? owner;

  _StoreDelegate(this.creator);
}

class StoreProvider<T extends Store> extends InheritedWidget {
  late final _StoreDelegate<T> delegate;

  StoreProvider({
    Key? key,
    required Widget child,
    required StoreCreator<T> create,
  })  : delegate = _StoreDelegate(create),
        super(key: key, child: child);

  static T of<T extends Store>(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<StoreProvider<T>>();

    return provider?.delegate.owner?.store as T;
  }

  @override
  bool updateShouldNotify(StoreProvider oldWidget) {
    return child != oldWidget.child;
  }

  @override
  StoreProviderElement<T> createElement() {
    return StoreProviderElement<T>(this);
  }
}

class StoreProviderElement<T extends Store> extends InheritedElement {
  StoreProviderElement(StoreProvider<T> widget) : super(widget);

  StoreProvider<T> get _ => widget as StoreProvider<T>;

  bool _mounted = false;
  late final T _store;

  T get store {
    _mountIfNotMounted();

    return _store;
  }

  _mountIfNotMounted() {
    if (!_mounted) {
      _store = _.delegate.creator();
      _mounted = true;
    }
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    _mountIfNotMounted();
    super.mount(parent, newSlot);

    _.delegate.owner = this;
  }

  @override
  void rebuild() {
    _.delegate.owner = this;
    super.rebuild();
  }

  @override
  void unmount() {
    store.dispose();
    super.unmount();
  }
}

class Observer extends StatefulWidget {
  final List<Observable> observe;
  final WidgetBuilder builder;

  const Observer({
    Key? key,
    required this.observe,
    required this.builder,
  }) : super(key: key);

  @override
  _ObserverState createState() => _ObserverState();
}

class _ObserverState extends State<Observer> {
  final _disposers = <RemoveListener>[];

  @override
  void initState() {
    for (var observer in widget.observe) {
      _disposers.add(observer.addListener((state) => _change()));
    }
    super.initState();
  }

  void _change() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void dispose() {
    for (var disposer in _disposers) {
      disposer();
    }
    super.dispose();
  }
}
