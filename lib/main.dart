import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (_) => PersonBloc(),
        child: const HomePage(),
      ),
    );
  }
}

// Abstract class for BLoc
@immutable
abstract class LoadAction {
  const LoadAction();
}

// Event Class which our BLoc will listen to
@immutable
class LoadPersonAction implements LoadAction {
  final PersonUrl url;
  const LoadPersonAction({required this.url}) : super();
}

enum PersonUrl {
  person1,
  person2,
}

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.person1:
        return "http://127.0.0.1:5500/api/person1.json";
      case PersonUrl.person2:
        return "http://127.0.0.1:5500/api/person2.json";
    }
  }
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

// Person model class
@immutable
class Person {
  final String name;
  final int age;

  const Person({
    required this.name,
    required this.age,
  });

  Person.fromJson(Map<String, dynamic> json)
      : name = json["name"] as String,
        age = json["age"] as int;
}

// Returning the Iterable of Persons
Future<Iterable<Person>> getPerson(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

// State Class which our BLoc will used to emit states
@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isCached;

  const FetchResult({
    required this.persons,
    required this.isCached,
  });

  @override
  String toString() {
    return "Fetchresult (is cached = $isCached , person  = $persons";
  }
}

// BLoc Implementation
class PersonBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<PersonUrl, Iterable<Person>> _cache = {};
  PersonBloc() : super(null) {
    on<LoadPersonAction>(
      (event, emit) async {
        final url = event.url;
        if (_cache.containsKey(url)) {
          // Data already cached
          final cachedpersons = _cache[url];
          final result = FetchResult(persons: cachedpersons!, isCached: true);
          emit(result);
        } else {
          final persons = await getPerson(url.urlString);
          _cache[url] = persons;
          final result = FetchResult(persons: persons, isCached: false);
          emit(result);
        }
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  // Triggers the event for the BLoc
                  context
                      .read<PersonBloc>()
                      .add(LoadPersonAction(url: PersonUrl.person1));
                },
                child: Text("Load Json #1"),
              ),
              TextButton(
                onPressed: () {
                  context
                      .read<PersonBloc>()
                      .add(LoadPersonAction(url: PersonUrl.person2));
                },
                child: Text("Load Json #2"),
              ),
            ],
          ),
          BlocBuilder<PersonBloc, FetchResult?>(
            buildWhen: ((previous, current) {
              return previous!.persons != current!.persons;
            }),
            builder: ((context, fetchResult) {
              final persons = fetchResult!.persons;
              if (persons == null) return SizedBox();
              return Expanded(
                child: ListView.builder(
                  itemCount: persons.length,
                  itemBuilder: ((context, index) {
                    final person = persons[index];
                    return ListTile(
                      title: Text(person!.name),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
