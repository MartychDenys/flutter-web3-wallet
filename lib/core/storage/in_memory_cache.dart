class InMemoryCache<T> {
  T? _data;

  T? get data => _data;

  void save(T data) {
    _data = data;
  }

  void clear() {
    _data = null;
  }
}
