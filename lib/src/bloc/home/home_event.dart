part of 'home_bloc.dart';

@immutable
abstract class HomeEvent extends Equatable {}

class InitHomeEvent extends HomeEvent {
  final int page;
  final int pageSize;

  InitHomeEvent({required this.page, required this.pageSize});

  @override
  List<Object?> get props => [page];
}

class GetHomeFeedPage extends HomeEvent {
  @override
  List<Object?> get props => [];
}

class ReloadHomeEvent extends HomeEvent {
  final GetHomeFeedResponse response;

  ReloadHomeEvent({required this.response});
  @override
  List<Object?> get props => [response];
}

class UpdateHomeEvent extends HomeEvent {
  UpdateHomeEvent();
  @override
  List<Object?> get props => [];
}
