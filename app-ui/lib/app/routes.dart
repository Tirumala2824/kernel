/// Route locations. Tab routes live inside the bottom-nav shell; the rest
/// are pushed on the root navigator.
abstract final class Routes {
  static const start = '/start';
  static const role = '/role';
  static const switchRole = '/role?switch=1';

  // Bottom navigation tabs.
  static const home = '/home';
  static const scan = '/scan';
  static const inventory = '/inventory';
  static const reports = '/reports';

  static const settings = '/settings';
  static const queue = '/queue';
  static const newLot = '/lots/new';

  static String newItem({String? locationId, String? lotId}) =>
      _withQuery('/items/new', {'locationId': ?locationId, 'lotId': ?lotId});

  static String item(String itemId) => '/items/$itemId';
  static String scanItem(String itemId) => '/items/$itemId/scan';
  static String result(String itemId, String scanId) =>
      '/items/$itemId/scans/$scanId';
  static String inspect(String itemId, {String? scanId}) =>
      _withQuery('/items/$itemId/inspect', {'scanId': ?scanId});

  static String newLocation({String? parentId}) =>
      _withQuery('/locations/new', {'parentId': ?parentId});
  static String location(String locationId) => '/locations/$locationId';
  static String lot(String lotId) => '/lots/$lotId';

  static String _withQuery(String path, Map<String, String> query) =>
      query.isEmpty ? path : Uri(path: path, queryParameters: query).toString();
}
