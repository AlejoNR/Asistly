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

  /// Elegir el archivo. POR AHORA ES SIMULADO: carga un archivo de ejemplo.
  /// Más adelante aquí se abrirá el selector de archivos y se leerá el Excel/CSV.
  Future<void> pickFile() async {
    isReading = true;
    notify();
    preview = await _repo.readSampleOfficialList();
    isReading = false;
    notify();
  }

  void toggleErrors() {
    showErrors = !showErrors;
    notify();
  }

  /// Guarda la lista. Devuelve cuántos estudiantes se agregaron como "Sin unirse".
  Future<int> import() async {
    final current = preview;
    if (current == null) return 0;
    isImporting = true;
    notify();
    final added = await _repo.importOfficialList(courseId, current.validRows);
    isImporting = false;
    notify();
    return added;
  }
}
