final class ContainerTypeRuleEntry {
  const ContainerTypeRuleEntry({
    required this.id,
    required this.parentContainerTypeId,
    required this.childContainerTypeId,
  });

  factory ContainerTypeRuleEntry.fromJson(Map<String, dynamic> json) {
    return ContainerTypeRuleEntry(
      id: json['id'] as String,
      parentContainerTypeId: json['parentContainerTypeId'] as String,
      childContainerTypeId: json['childContainerTypeId'] as String,
    );
  }

  final String id;
  final String parentContainerTypeId;
  final String childContainerTypeId;
}
