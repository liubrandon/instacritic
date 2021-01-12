class Tag {
  String displayName;
  String _logicalName;
  Tag(String tagName) {
    displayName = tagName.trim();
    _logicalName = normalize(tagName);
  }
  String normalize(String str) => str.replaceAll(RegExp(r"[^\w\s]"), '').trim();
  @override
  String toString() => this.displayName;

  @override
  int get hashCode => _logicalName.hashCode;
  
  @override
  bool operator ==(other) => other is Tag && other._logicalName == _logicalName; 
}