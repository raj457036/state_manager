import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:state_manager/state_manager.dart';

void main() {
  runApp(const MyApp());
}

class CounterActions {
  static final incrementAction = StateAction<int>(
    'Increment',
    (last) => last + 1,
  );
}

class CounterStore extends Store {
  final counter = Observable('counter', 0);

  void increment() => counter.apply(CounterActions.incrementAction);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      create: () => CounterStore(),
      child: MaterialApp(
        title: 'Flutter Demo',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<CounterStore>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Observer(
              observe: [store.counter],
              builder: (context) => Text(
                '${store.counter()}',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: store.increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
