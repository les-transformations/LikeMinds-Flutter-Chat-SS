import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_chat_ss_fl/src/service/likeminds_service.dart';
import 'package:likeminds_chat_ss_fl/src/service/service_locator.dart';
import 'package:likeminds_chat_ss_fl/src/utils/realtime/realtime.dart';
import 'package:likeminds_chat_fl/likeminds_chat_fl.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  static HomeBloc? _instance;
  static HomeBloc get instance => _instance ??= HomeBloc._();
  HomeBloc._() : super(HomeInitial()) {
    final DatabaseReference realTime = LMRealtime.instance.homeFeed();
    realTime.onValue.listen((event) {
      debugPrint(event.toString());
      add(UpdateHomeEvent());
    });
    on<HomeEvent>(
      (event, emit) async {
        if (event is InitHomeEvent) {
          emit(HomeLoading());

          final response =
              await locator<LikeMindsService>().getHomeFeed(event.request);

          if (response.success) {
            response.data?.conversationMeta?.forEach((key, value) {
              String? userId = value.userId == null
                  ? value.memberId?.toString()
                  : value.userId.toString();
              final user = response.data?.userMeta?[userId];
              value.member = user;
            });

            emit(HomeLoaded(
                response: response.data!, page: event.request.page!));
          } else {
            HomeError(response.errorMessage!);
          }
        }
        if (event is UpdateHomeEvent) {
          final response = await locator<LikeMindsService>()
              .getHomeFeed((GetHomeFeedRequestBuilder()
                    ..page(1)
                    ..pageSize(event.pageSize))
                  .build());
          if (response.success) {
            emit(UpdatedHomeFeed());
            response.data?.conversationMeta?.forEach((key, value) {
              String? userId = value.userId == null
                  ? value.memberId?.toString()
                  : value.userId.toString();
              final user = response.data?.userMeta?[userId];
              value.member = user;
            });
            emit(UpdateHomeFeed(response: response.data!));
          } else {
            emit(HomeError(response.errorMessage ?? "An error occured"));
          }
        }
      },
    );
  }
}
