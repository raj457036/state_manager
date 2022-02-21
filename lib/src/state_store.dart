import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

/// A listener that can be added to a [StateHolder] using
/// [StateHolder.addListener].
///
/// This callback receives the current [StateHolder.state] as a parameter.
typedef Listener<T> = void Function(T state);
typedef StateUpdater<T> = T Function(T prev);
typedef RemoveListener<T> = void Function();

class _StemStateListenerEntry<T>
    extends LinkedListEntry<_StemStateListenerEntry<T>> {
  final Listener<T> listener;

  _StemStateListenerEntry(this.listener);
}

abstract class StateHolder<T> {
  StateHolder({
    required T initial,
  }) : _state = initial;

  // A [LinkedList] that is holding the [Listener]s
  final _listeners = LinkedList<_StemStateListenerEntry<T>>();

  T _state;
  bool _mounted = true;

  /// Whether [dispose] was called or not.
  bool get isMounted => _mounted;

  /// Current state of this [StateHolder]
  T get state => _state;
  bool get hasListeners => _listeners.isNotEmpty;

  // Debug checks
  bool _debugIsMounted() {
    assert(() {
      if (!_mounted) {
        throw StateError('''
Tried to use $runtimeType after `dispose` was called.
Consider checking `mounted`.
''');
      }
      return true;
    }(), '');
    return true;
  }

  /// Subscribes to this object.
  ///
  /// The [listener] callback will be called immediately on addition and
  /// synchronously whenever [state] changes.
  ///
  /// Set [addLastState] to true if you want to execute the listener with the
  /// current state once subscription completes.
  ///
  /// To remove this [listener], call the function returned by [addListener]:
  ///
  /// ```dart
  /// final stem = Stem(0);
  /// final removeStem = stem.addListener((value) => ...);
  /// removeStem();
  /// ```
  ///
  /// Listeners should not add other listeners.
  ///
  /// Adding and removing listeners has a constant time-complexity.
  RemoveListener<T> addListener(Listener<T> listener,
      {bool addLastState = false}) {
    final entry = _StemStateListenerEntry<T>(listener);

    _listeners.add(entry);

    if (addLastState) {
      listener(_state);
    }

    return () {
      if (entry.list != null) {
        // Remove this listener
        entry.unlink();
      }
    };
  }

  /// Whether to notify listeners or not when [state] changes
  @protected
  bool stateChanged(
    T old,
    T current,
  ) =>
      !identical(old, current);

  /// Notify all the listeners of this [StateHolder]
  /// with the last [state]
  void notifyListeners() {
    assert(_debugIsMounted(), '');
    for (final entry in _listeners) {
      try {
        entry.listener(_state);
      } catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
    }
  }

  /// This method will change the state of this [StateHolder]
  /// if the `newState` returned by the `update` are not identical.
  ///
  /// Note: This method won't notifies the listeners about this change,
  /// To notify listeners call [notifyListeners] after this method.
  @mustCallSuper
  @protected
  void setState(StateUpdater<T> update) {
    assert(_debugIsMounted(), '');

    final _prevState = _state;
    final _newState = update(_prevState);

    if (!stateChanged(_prevState, _newState)) {
      return;
    }

    _state = _newState;
  }

  /// Removes all the listeners and mark this StateHolder unmounted.
  @mustCallSuper
  void dispose() {
    assert(_debugIsMounted(), '');
    _listeners.clear();
    _mounted = false;
  }
}

class StoreContext {
  StoreContext._();

  final List<StoreState> _detachedStates = [];

  void newState(StoreState state) {
    _detachedStates.add(state);
  }

  void newStore(BaseStore store) {
    for (var state in _detachedStates) {
      store._attachState(state);
    }
    _detachedStates.clear();
  }
}

/// An instance of global store context
final storeContext = StoreContext._();

abstract class StoreState<T> extends StateHolder<T> {
  StoreState({required T initial}) : super(initial: initial) {
    storeContext.newState(this);
  }
}

abstract class BaseStore {
  BaseStore() {
    storeContext.newStore(this);
    awake();
  }

  void awake();

  void init();

  void ready();

  @mustCallSuper
  void dispose() {
    for (var element in _states) {
      element.dispose();
    }
  }

  final List<StateHolder> _states = [];

  void _attachState(StoreState state) {
    _states.add(state);
  }
}

class Store extends BaseStore {
  @override
  void awake() {}

  @override
  void init() {}

  @override
  void ready() {}
}

class Observable<T> extends StoreState<T> {
  final String name;
  Observable(this.name, T initial) : super(initial: initial);

  /// Current state of this [StateHolder]
  call() => state;

  /// Apply changes to this state using the [StateAction] object
  ///
  /// ```dart
  /// final loading = State('Loading', false);
  ///
  /// loading.apply(Action("Start Loading", (lastState) => true));
  ///
  /// ```
  ///
  apply(StateAction<T> action) {
    setState(action.change);
    notifyListeners();
  }
}

class LazyAction<T> {
  final String name;
  final StateUpdater<T> change;
  final Observable<T> on;

  LazyAction(this.name,
      {required this.on, required this.change, bool lazy = true}) {
    if (!lazy) {
      this();
    }
  }

  void call() => on
    // ignore: invalid_use_of_protected_member
    ..setState(change)
    ..notifyListeners();
}

typedef ActionDispatcher = void Function();

class StateAction<T> {
  final String name;
  final StateUpdater<T> change;

  StateAction(this.name, this.change);
}
