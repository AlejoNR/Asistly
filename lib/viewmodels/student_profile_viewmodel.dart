import '../services/course_repository.dart';
import 'profile_viewmodel.dart';

/// ViewModel del Perfil del estudiante: lo común del perfil, su asistencia
/// global y el celular vinculado.
class StudentProfileViewModel extends ProfileViewModel {
  final CourseRepository _courseRepo;

  StudentProfileViewModel(super.authRepo, this._courseRepo) {
    load();
  }

  int _present = 0;
  int _total = 0;
  bool _isLinkedDevice = true;

  bool get hasClasses => _total > 0;
  int get globalPercent => hasClasses ? (_present * 100 / _total).round() : 0;
  bool get isAtRisk => hasClasses && globalPercent < 75;

  /// Solo los últimos caracteres: el id completo no le sirve a nadie en pantalla.
  String get deviceLabel {
    final id = user?.deviceId ?? '';
    if (id.isEmpty) return 'Sin vincular';
    final end = id.length <= 6 ? id : id.substring(id.length - 6);
    return '${_isLinkedDevice ? 'Este celular' : 'Otro celular'} · ID …$end';
  }

  Future<void> load() async {
    // Si falla, el perfil se muestra igual, sin el porcentaje.
    try {
      _isLinkedDevice = await authRepo.isLinkedDevice();
      var present = 0;
      var total = 0;
      for (final item in await _courseRepo.getStudentCourses()) {
        present += item.presentCount;
        total += item.totalCount;
      }
      _present = present;
      _total = total;
    } catch (e) {
      errorMessage(e);
    }
    notify();
  }
}
