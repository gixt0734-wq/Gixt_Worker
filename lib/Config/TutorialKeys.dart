import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialKeys {
  static final GlobalKey jobsKey = GlobalKey();
  static final GlobalKey configKey = GlobalKey();
  static final GlobalKey homeKey = GlobalKey();
  static final GlobalKey agendaKey = GlobalKey();
  static final GlobalKey workerKey = GlobalKey();
  static final GlobalKey colorkey = GlobalKey();
  static final GlobalKey walletkey = GlobalKey();
  static final GlobalKey modekey = GlobalKey();
  static final GlobalKey reportskey = GlobalKey();
  static final GlobalKey infokey = GlobalKey();

static List<_TutorialStep> get tutorialSteps => [
  _TutorialStep(
    id: 'home',
    key: TutorialKeys.homeKey,
    title: 'Inicio',
    description:
        'Desde aquí puedes acceder rápidamente a tus servicios, consultar información importante y revisar los trabajos que tienes actualmente en curso.',
  ),
  _TutorialStep(
    id: 'agenda',
    key: TutorialKeys.agendaKey,
    title: 'Mis servicios',
    description:
        'Consulta todos tus servicios y revisa el progreso de cada trabajo. Podrás conocer su estado y mantenerte al tanto de cada etapa hasta que el servicio sea finalizado.',
  ),
  _TutorialStep(
    id: 'Trabajos',
    key: TutorialKeys.jobsKey,
    title: 'Trabajos disponibles',
    description:
        'Aquí encontrarás nuevos trabajos disponibles para ti. Revisa los detalles de cada solicitud, acepta los trabajos que te interesen y comunícate con el cliente durante el servicio.',
  ),
  _TutorialStep(
    id: 'info',
    key: TutorialKeys.workerKey,
    title: 'Información del trabajador',
    description:
        'Administra la información de tu perfil como trabajador. Puedes actualizar tus tarifas, zona y rango de trabajo, categorías de servicio y otros datos relacionados con los servicios que ofreces.',
  ),
  _TutorialStep(
    id: 'config',
    key: TutorialKeys.configKey,
    title: 'Configuración',
    description:
        'Personaliza y administra tu cuenta desde un solo lugar. Aquí encontrarás opciones relacionadas con tu perfil, billetera, reportes, apariencia y otras preferencias de Gixt Worker.',
  ),
  _TutorialStep(
    id: 'modekey',
    key: TutorialKeys.modekey,
    title: 'Modo Activo / Inactivo',
    description:
        'Controla tu disponibilidad para recibir nuevos trabajos. Activa este modo cuando estés disponible para trabajar o desactívalo cuando no quieras recibir nuevas solicitudes de servicio.',
  ),
  _TutorialStep(
    id: 'colorkey',
    key: TutorialKeys.colorkey,
    title: 'Apariencia',
    description:
        'Personaliza la apariencia de Gixt Worker cambiando entre el modo claro y oscuro. Elige el estilo que te resulte más cómodo para utilizar la aplicación.',
  ),
  _TutorialStep(
    id: 'walletkey',
    key: TutorialKeys.walletkey,
    title: 'Mi billetera',
    description:
        'Consulta y administra los movimientos de tu billetera. Revisa tus ingresos, salidas, saldo disponible y las operaciones relacionadas con los servicios que has realizado.',
  ),
  _TutorialStep(
    id: 'infokey',
    key: TutorialKeys.infokey,
    title: 'Mi información',
    description:
        'Consulta y mantén actualizada la información de tu perfil. Estos datos forman parte de tu cuenta y ayudan a mantener correcta la información utilizada durante tus servicios.',
  ),
  _TutorialStep(
    id: 'reportskey',
    key: TutorialKeys.reportskey,
    title: 'Reportes',
    description:
        '¿Tuviste algún problema con un servicio? Desde aquí puedes crear un nuevo reporte, explicar lo sucedido y consultar el estado de los reportes que hayas enviado anteriormente.',
  ),
];
} 
// Colors.grey.withOpacity(0.6)
class _TutorialStep {
  const _TutorialStep({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    this.shape = ShapeLightFocus.Circle,
    this.paddingFocus,
  });

  final String id;
  final GlobalKey key;
  final String title;
  final String description;

  /// ⚠️ `Circle` solo sirve para targets chicos y cuadrados (los íconos del
  /// nav): el paquete calcula el RADIO como `ladoMayor * 0.6 + paddingFocus`,
  /// así que en un widget ancho —una sección completa— el círculo sale más
  /// grande que la pantalla. Para esos usa `RRect`, que sí respeta el alto y
  /// el ancho reales del widget.
  final ShapeLightFocus shape;

  /// Padding propio del target. En RRect el paquete suma `padding * 2` por
  /// lado, así que en secciones anchas conviene bajarlo.
  final double? paddingFocus;
}
