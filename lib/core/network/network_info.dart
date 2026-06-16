abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// A stub implementation for network checking.
/// In a real scenario, this would use a package like internet_connection_checker.
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected => Future.value(true);
}
