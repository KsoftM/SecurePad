import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/secure_storage_service.dart';
import '../../data/auth/auth_service.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthSignIn extends AuthEvent {
  final String email;
  final String password;
  AuthSignIn(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthRegister extends AuthEvent {
  final String email;
  final String password;
  AuthRegister(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthSignOut extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();
  final sessionStorage = SecureStorageService();
  AuthBloc() : super(AuthInitial()) {
    on<AuthStarted>((event, emit) async {
      emit(AuthLoading());
      final user = await _authService.userChanges.first;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });
    on<AuthSignIn>((event, emit) async {
      emit(AuthLoading());
      await _authService.signInWithEmail(event.email, event.password);
      final user = await _authService.userChanges.first;
      if (user != null) {
        sessionStorage.write('user_id', user.uid);
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });
    on<AuthRegister>((event, emit) async {
      emit(AuthLoading());
      await _authService.registerWithEmail(event.email, event.password);
      final user = await _authService.userChanges.first;
      if (user != null) {
        sessionStorage.write('user_id', user.uid);
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });
    on<AuthSignOut>((event, emit) async {
      await _authService.signOut();
      final userId = await sessionStorage.read('user_id');
      if (userId != null) {
        sessionStorage.delete('user_id');
      }
      await sessionStorage.delete('passphrase_key_$userId');
      emit(Unauthenticated());
    });
  }
}
