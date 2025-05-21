part of 'create_post_cubit.dart';

abstract class CreatePostState extends Equatable {
  const CreatePostState();

  @override
  List<Object?> get props => [];
}

class CreatePostInitial extends CreatePostState {}

class CreatePostInProgress extends CreatePostState {}

class CreatePostSuccess extends CreatePostState {
  final Post newPost; // The successfully created post

  const CreatePostSuccess(this.newPost);

  @override
  List<Object?> get props => [newPost];
}

class CreatePostFailure extends CreatePostState {
  final String errorMessage;

  const CreatePostFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}