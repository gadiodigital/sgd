class Project {
  Project({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'].toString(),
        name: json['name'].toString(),
        slug: json['slug'].toString(),
        description: (json['description'] ?? '').toString(),
      );

  final String id;
  final String name;
  final String slug;
  final String description;
}

class NodeTypeItem {
  NodeTypeItem({
    required this.id,
    required this.projectId,
    required this.code,
    required this.name,
    required this.description,
    required this.root,
    required this.acceptsDocs,
    required this.iconKey,
    required this.attributes,
    required this.order,
  });

  factory NodeTypeItem.fromJson(Map<String, dynamic> json) => NodeTypeItem(
        id: json['id'].toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        code: json['code'].toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        root: json['root'] == true,
        acceptsDocs: (json['acceptsDocs'] ?? json['acceptsdocs']) == true,
        iconKey: (json['iconKey'] ?? json['iconkey'] ?? 'folder').toString(),
        attributes: ((json['attributes'] as List?) ?? const [])
            .map((item) => AttributeItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
            .toList(),
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String projectId;
  final String code;
  final String name;
  final String description;
  final bool root;
  final bool acceptsDocs;
  final String iconKey;
  final List<AttributeItem> attributes;
  final int order;
}

class DocumentTypeItem {
  DocumentTypeItem({
    required this.id,
    required this.projectId,
    required this.code,
    required this.name,
    required this.description,
    required this.attributes,
  });

  factory DocumentTypeItem.fromJson(Map<String, dynamic> json) => DocumentTypeItem(
        id: json['id'].toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        code: json['code'].toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        attributes: ((json['attributes'] as List?) ?? const [])
            .map((item) => AttributeItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
            .toList(),
      );

  final String id;
  final String projectId;
  final String code;
  final String name;
  final String description;
  final List<AttributeItem> attributes;
}

class RuleItem {
  RuleItem({
    required this.id,
    required this.projectId,
    required this.parentTypeId,
    required this.childTypeId,
  });

  factory RuleItem.fromJson(Map<String, dynamic> json) => RuleItem(
        id: (json['id'] ?? '${json['parentTypeId'] ?? json['parenttypeid']}|${json['childTypeId'] ?? json['childtypeid']}')
            .toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        parentTypeId: (json['parentTypeId'] ?? json['parenttypeid']).toString(),
        childTypeId: (json['childTypeId'] ?? json['childtypeid']).toString(),
      );

  final String id;
  final String projectId;
  final String parentTypeId;
  final String childTypeId;
}

class NodeItem {
  NodeItem({
    required this.id,
    required this.projectId,
    required this.typeId,
    required this.parentId,
    required this.code,
    required this.name,
    required this.description,
    required this.values,
    required this.depth,
    required this.order,
  });

  factory NodeItem.fromJson(Map<String, dynamic> json) => NodeItem(
        id: json['id'].toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        typeId: (json['typeId'] ?? json['typeid']).toString(),
        parentId:
            ((json['parentId'] ?? json['parentid']) as String?)?.isEmpty == true ? null : (json['parentId'] ?? json['parentid'])?.toString(),
        code: (json['code'] ?? '').toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        values: ((json['values'] as Map?) ?? const {}).map((key, value) => MapEntry(key.toString(), value.toString())),
        depth: (json['depth'] as num?)?.toInt() ?? 0,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String projectId;
  final String typeId;
  final String? parentId;
  final String code;
  final String name;
  final String description;
  final Map<String, String> values;
  final int depth;
  final int order;
}

class NodeDocumentSummary {
  const NodeDocumentSummary({
    required this.id,
    required this.title,
    required this.documentTypeName,
    required this.currentVersionNumber,
    required this.pageCount,
    required this.updatedAtLabel,
  });

  factory NodeDocumentSummary.fromJson(Map<String, dynamic> json) => NodeDocumentSummary(
        id: json['id'].toString(),
        title: (json['title'] ?? '').toString(),
        documentTypeName: (json['documentTypeName'] ?? '').toString(),
        currentVersionNumber: (json['currentVersionNumber'] as num?)?.toInt() ?? 1,
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        updatedAtLabel: formatDateTimeLabel((json['updatedAt'] ?? '').toString()),
      );

  final String id;
  final String title;
  final String documentTypeName;
  final int currentVersionNumber;
  final int pageCount;
  final String updatedAtLabel;
}

class AttributeItem {
  AttributeItem({
    required this.id,
    required this.name,
    required this.code,
    required this.dataType,
    required this.extension,
    required this.regex,
    required this.options,
  });

  factory AttributeItem.fromJson(Map<String, dynamic> json) => AttributeItem(
        id: json['id'].toString(),
        name: json['name'].toString(),
        code: json['code'].toString(),
        dataType: (json['dataType'] ?? json['datatype']).toString(),
        extension: (json['extension'] ?? '').toString(),
        regex: (json['regex'] ?? '').toString(),
        options: ((json['options'] as List?) ?? const [])
            .map((item) => AttributeOptionItem.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
            .toList(),
      );

  final String id;
  final String name;
  final String code;
  final String dataType;
  final String extension;
  final String regex;
  final List<AttributeOptionItem> options;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'dataType': dataType,
        'extension': extension,
        'regex': regex,
        'options': options.map((item) => item.toJson()).toList(),
      };
}

class AttributeOptionItem {
  const AttributeOptionItem({
    required this.id,
    required this.code,
    required this.label,
  });

  factory AttributeOptionItem.fromJson(Map<String, dynamic> json) => AttributeOptionItem(
        id: json['id'].toString(),
        code: json['code'].toString(),
        label: json['label'].toString(),
      );

  final String id;
  final String code;
  final String label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'label': label,
      };
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.loginName,
    required this.isPlatformAdmin,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
        id: json['id'].toString(),
        displayName: (json['displayName'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        loginName: (json['loginName'] ?? '').toString(),
        isPlatformAdmin: json['isPlatformAdmin'] == true,
      );

  final String id;
  final String displayName;
  final String email;
  final String loginName;
  final bool isPlatformAdmin;
}

class ProjectMembershipAccess {
  const ProjectMembershipAccess({
    required this.projectId,
    required this.profileId,
    required this.profileCode,
    required this.profileName,
    required this.permissionCodes,
  });

  factory ProjectMembershipAccess.fromJson(Map<String, dynamic> json) => ProjectMembershipAccess(
        projectId: json['projectId'].toString(),
        profileId: json['profileId'].toString(),
        profileCode: json['profileCode'].toString(),
        profileName: json['profileName'].toString(),
        permissionCodes: ((json['permissionCodes'] as List?) ?? const []).map((item) => item.toString()).toList(),
      );

  final String projectId;
  final String profileId;
  final String profileCode;
  final String profileName;
  final List<String> permissionCodes;
}

class AuthSessionState {
  const AuthSessionState({
    required this.token,
    required this.user,
    required this.memberships,
    required this.allPermissionCodes,
  });

  factory AuthSessionState.fromJson(Map<String, dynamic> json, {required String token}) => AuthSessionState(
        token: token,
        user: CurrentUser.fromJson(Map<String, dynamic>.from((json['user'] as Map).cast<String, dynamic>())),
        memberships: ((json['memberships'] as List?) ?? const [])
            .map((item) => ProjectMembershipAccess.fromJson(Map<String, dynamic>.from((item as Map).cast<String, dynamic>())))
            .toList(),
        allPermissionCodes: ((json['allPermissions'] as List?) ?? const []).map((item) => item.toString()).toList(),
      );

  final String token;
  final CurrentUser user;
  final List<ProjectMembershipAccess> memberships;
  final List<String> allPermissionCodes;
}

class PermissionDefinition {
  const PermissionDefinition({
    required this.code,
    required this.name,
    required this.description,
    required this.accessKind,
  });

  factory PermissionDefinition.fromJson(Map<String, dynamic> json) => PermissionDefinition(
        code: json['code'].toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        accessKind: (json['accessKind'] ?? json['accesskind'] ?? '').toString(),
      );

  final String code;
  final String name;
  final String description;
  final String accessKind;
}

class ProjectProfileItem {
  const ProjectProfileItem({
    required this.id,
    required this.projectId,
    required this.code,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.isActive,
    required this.permissionCodes,
  });

  factory ProjectProfileItem.fromJson(Map<String, dynamic> json) => ProjectProfileItem(
        id: json['id'].toString(),
        projectId: (json['projectId'] ?? json['projectid']).toString(),
        code: json['code'].toString(),
        name: json['name'].toString(),
        description: (json['description'] ?? '').toString(),
        isSystem: (json['isSystem'] ?? json['issystem']) == true,
        isActive: (json['isActive'] ?? json['isactive']) != false,
        permissionCodes: ((json['permissionCodes'] as List?) ?? const []).map((item) => item.toString()).toList(),
      );

  final String id;
  final String projectId;
  final String code;
  final String name;
  final String description;
  final bool isSystem;
  final bool isActive;
  final List<String> permissionCodes;
}

class ProjectUserMembershipItem {
  const ProjectUserMembershipItem({
    required this.userId,
    required this.profileId,
    required this.profileCode,
    required this.profileName,
    required this.displayName,
    required this.loginName,
    required this.email,
    required this.isActive,
    this.userActive = true,
  });

  factory ProjectUserMembershipItem.fromJson(Map<String, dynamic> json) => ProjectUserMembershipItem(
        userId: (json['userId'] ?? json['userid']).toString(),
        profileId: (json['profileId'] ?? json['profileid']).toString(),
        profileCode: (json['profileCode'] ?? json['profilecode']).toString(),
        profileName: (json['profileName'] ?? json['profilename']).toString(),
        displayName: (json['displayName'] ?? json['displayname']).toString(),
        loginName: (json['loginName'] ?? json['loginname']).toString(),
        email: (json['email'] ?? '').toString(),
        isActive: (json['isActive'] ?? json['isactive']) != false,
        userActive: (json['userActive'] ?? json['useractive']) != false,
      );

  final String userId;
  final String profileId;
  final String profileCode;
  final String profileName;
  final String displayName;
  final String loginName;
  final String email;
  final bool isActive;
  final bool userActive;
}

String formatDateTimeLabel(String value) {
  if (value.trim().isEmpty) {
    return 'sin fecha';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  final local = parsed.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}
