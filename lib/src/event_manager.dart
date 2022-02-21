abstract class StoreEvent {
  onCreate();
  onInit();
  onReady();
  onDispose();
}

abstract class StateEvent {
  onCreate();
  onAttach();
  onReady();
  onDispose();
}

mixin StateEventNotification {}
