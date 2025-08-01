// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Control de Gastos';

  @override
  String get overview => 'Resumen';

  @override
  String get stats => 'Estadísticas';

  @override
  String get addExpense => 'Agregar Gasto';

  @override
  String get editExpense => 'Editar Gasto';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get title => 'Título';

  @override
  String get description => 'Descripción';

  @override
  String get amount => 'Cantidad';

  @override
  String get category => 'Categoría';

  @override
  String get type => 'Tipo';

  @override
  String get date => 'Fecha';

  @override
  String get recurring => 'Recurrente';

  @override
  String get frequency => 'Frecuencia';

  @override
  String get nextOccurrence => 'Próxima ocurrencia';

  @override
  String get endDate => 'Fecha de finalización (opcional)';

  @override
  String get income => 'Ingreso';

  @override
  String get expense => 'Gasto';

  @override
  String get noExpenses => 'Aún no hay gastos';

  @override
  String get addFirstExpense => 'Agrega tu primer gasto para comenzar';

  @override
  String get deleteExpense => 'Eliminar Gasto';

  @override
  String get deleteExpenseConfirm => '¿Seguro que deseas eliminar este gasto?';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Cerrar';

  @override
  String get manageCategories => 'Gestionar Categorías';

  @override
  String get addCategory => 'Agregar nueva categoría';

  @override
  String get duplicateCategory => 'Nombre de categoría duplicado.';

  @override
  String get categoryInUse => 'No se puede eliminar: la categoría está en uso.';

  @override
  String get categoryNameEmpty => 'El nombre de la categoría no puede estar vacío.';

  @override
  String get enterTitle => 'Ingrese un título';

  @override
  String get enterAmount => 'Ingrese una cantidad válida';

  @override
  String get selectCategory => 'Por favor seleccione una categoría válida.';

  @override
  String get invalidAmount => 'Ingrese una cantidad positiva válida (máx \$1,000,000).';

  @override
  String get incomeNegative => 'El ingreso no puede ser negativo.';

  @override
  String get selectFrequency => 'Seleccione una frecuencia recurrente.';

  @override
  String get selectNextOccurrence => 'Seleccione la próxima fecha de ocurrencia.';

  @override
  String get nextOccurrenceAfterDate => 'La próxima ocurrencia debe ser igual o posterior a la fecha principal.';

  @override
  String get endDateAfterNext => 'La fecha de finalización debe ser posterior a la próxima ocurrencia.';

  @override
  String get invalidData => 'Datos inválidos. Por favor revise todos los campos.';

  @override
  String failedAdd(Object error) {
    return 'No se pudo agregar el gasto: $error';
  }

  @override
  String failedEdit(Object error) {
    return 'No se pudo editar el gasto: $error';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get errorLoadingExpenses => 'Error al cargar los gastos';

  @override
  String get smartTips => 'Consejos Inteligentes';

  @override
  String get noData => 'No hay datos para mostrar';

  @override
  String get daily => 'Diario';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensual';

  @override
  String get custom => 'Personalizado';

  @override
  String get dailyTrend => 'Tendencia diaria de flujo de efectivo';

  @override
  String get expensesByCategory => 'Gastos por categoría';

  @override
  String get incomeByCategory => 'Ingresos por categoría';

  @override
  String get tipHighSpending => 'Estás gastando más del 80% de tus ingresos. Considera ahorrar más este mes.';

  @override
  String get tipNoIncome => 'No se registraron ingresos este mes. Agrega tus ingresos para rastrear tu balance.';

  @override
  String tipCategorySpike(Object category) {
    return 'Gasto elevado en \'$category\'. Considera revisar esta categoría.';
  }

  @override
  String get tipNegativeBalance => 'Tu balance es negativo. Intenta reducir gastos o aumentar ingresos.';

  @override
  String get tipFewExpenses => 'Agrega más gastos para obtener mejores consejos e información.';

  @override
  String get tipAllGood => '¡Buen trabajo! Tu gasto está bajo control este mes.';

  @override
  String get receiptPhotos => 'Fotos de Recibos';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get photoCapturedSuccessfully => '¡Foto capturada exitosamente!';

  @override
  String get photoDeletedSuccessfully => '¡Foto eliminada exitosamente!';

  @override
  String get failedToCapturePhoto => 'Error al capturar la foto';

  @override
  String get failedToDeletePhoto => 'Error al eliminar la foto';

  @override
  String get fileSizeTooLarge => 'El archivo es demasiado grande. El tamaño máximo es 10MB.';

  @override
  String get unsupportedFileType => 'Tipo de archivo no soportado. Por favor selecciona una imagen JPEG o PNG.';

  @override
  String get noPhotos => 'No hay fotos adjuntas';

  @override
  String photosAttached(Object count) {
    return '$count fotos adjuntas';
  }
}
