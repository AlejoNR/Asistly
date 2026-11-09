import '../models/app_user.dart';
import '../services/auth_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel de la pantalla principal (docente o estudiante):
/// guarda qué pestaña de la barra inferior está abierta.
class MainViewModel extends BaseViewModel {
  final AuthRepository _repo;
  MainViewModel(this._repo);

  int currentTab = 0;

  AppUser? get user => _repo.user;

  void selectTab(int index) {
    if (index == currentTab) return;
    currentTab = index;
    notify();
  }

  Future<void> signOut() => _repo.signOut();
}
