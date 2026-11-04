import '../models/course.dart';
import '../models/official_list.dart';
import '../services/course_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel de "Importar lista oficial".
class ImportListViewModel extends BaseViewModel {
  final CourseRepository _repo;
  final String courseId;

  ImportListViewModel(this._repo, this.courseId) {
    _loadCourse();
  }

  Course? course;
  ImportPreview? preview; // null hasta que se elige un archivo
  bool isReading = false;
  bool isImporting = false;
  String? error; // Error al leer el archivo o al guardar
  bool showErrors = true; // La sección "Filas con errores" se puede plegar

  /// Los primeros 3 estudiantes para la vista previa.
  List<OfficialListEntry> get previewRows {
    final rows = preview?.validRows ?? [];
    if (rows.length <= 3) return rows;
    return rows.sublist(0, 3);
  }

  Future<void> _loadCourse() async {
    course = await _repo.getCourse(courseId);
    notify();
  }

  /// Abre el selector de archivos y lee el Excel/CSV elegido.
  /// Si la persona cancela, se deja lo que había.
  Future<void> pickFile() async {
    isReading = true;
    error = null;
    notify();
    try {
      final result = await _repo.readOfficialListFile();
      if (result != null) preview = result;
    } catch (e) {
      error = errorMessage(e);
    }
    isReading = false;
    notify();
  }

  void toggleErrors() {
    showErrors = !showErrors;
    notify();
  }

  /// Guarda la lista. Devuelve cuántos estudiantes nuevos se agregaron,
  /// o null si falló (el mensaje queda en [error]).
  Future<int?> import() async {
    final current = preview;
    if (current == null) return 0;
    isImporting = true;
    error = null;
    notify();
    int? added;
    try {
      added = await _repo.importOfficialList(courseId, current.validRows);
    } catch (e) {
      error = errorMessage(e);
    }
    isImporting = false;
    notify();
    return added;
  }
}
