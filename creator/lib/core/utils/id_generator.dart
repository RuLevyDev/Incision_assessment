abstract class IdGenerator {
  String nextId();
}

class SequentialIdGenerator implements IdGenerator {
  int _current = 0;

  @override
  String nextId() {
    _current += 1;
    return _current.toString();
  }
}
