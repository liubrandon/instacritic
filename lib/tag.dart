class Tag {
  String displayName;
  String _logicalName;
  Tag(String tagName) {
    String tagName1 = tagName.trim();
    if(tagName == 'Lisbon') // Idk why the trailing n is cut off on mobile
      tagName1 = 'Lisbon ';
    displayName = tagName1;
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