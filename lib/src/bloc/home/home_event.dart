part of 'home_bloc.dart';

@immutable
abstract class HomeEvent extends Equatable {}

class InitHomeEvent extends HomeEvent {
  final GetHomeFeedRequest request;

  InitHomeEvent({
    required this.request,
  });

  @override
  List<Object?> get props => [request];
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
  final int pageSize;
  UpdateHomeEvent({this.pageSize = 50});
  @override
  List<Object?> get props => [];
}
