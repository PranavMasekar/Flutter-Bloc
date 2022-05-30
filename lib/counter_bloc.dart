import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_example/counter_state.dart';

class CounterBloc extends Cubit<CounterState> {
  CounterBloc()
      : super(
          CounterState(countValue: 0, wasIncremented: false),
        );

  void increment() => emit(
        CounterState(countValue: state.countValue + 1, wasIncremented: true),
      );
  void decrement() => emit(
        CounterState(countValue: state.countValue - 1, wasIncremented: false),
      );
}
