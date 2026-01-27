import 'package:ngomna_chat/data/models/feature_model.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';

class AppFeatures {
  static const List<Feature> homeFeatures = [
    Feature(
      id: 'payslips',
      title: 'Payslips',
      iconPath: AppAssets.payslips,
      route: AppRoutes.payslips,
    ),
    Feature(
      id: 'census',
      title: 'Census',
      iconPath: AppAssets.census,
      route: AppRoutes.census,
    ),
    Feature(
      id: 'information',
      title: 'Information',
      iconPath: AppAssets.information,
      route: AppRoutes.information,
    ),
    Feature(
      id: 'dgi',
      title: 'DGI',
      iconPath: AppAssets.dgi,
      route: AppRoutes.dgi,
    ),
  ];
}
