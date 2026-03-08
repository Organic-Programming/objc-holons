#import <Holons/Holons.h>

static NSString *const HOLMetaErrorDomain = @"org.organicprogramming.holons.meta";
static NSString *const HOLMetaServiceName = @"holonmeta.v1.HolonMeta";

@implementation HOLDescribeRequest
@end

@implementation HOLEnumValueDoc
@synthesize name = _name;
@synthesize number = _number;
@synthesize docDescription = _docDescription;
@end

@implementation HOLFieldDoc
@synthesize name = _name;
@synthesize type = _type;
@synthesize number = _number;
@synthesize docDescription = _docDescription;
@synthesize label = _label;
@synthesize mapKeyType = _mapKeyType;
@synthesize mapValueType = _mapValueType;
@synthesize nestedFields = _nestedFields;
@synthesize enumValues = _enumValues;
@synthesize required = _required;
@synthesize example = _example;
@end

@implementation HOLMethodDoc
@synthesize name = _name;
@synthesize docDescription = _docDescription;
@synthesize inputType = _inputType;
@synthesize outputType = _outputType;
@synthesize inputFields = _inputFields;
@synthesize outputFields = _outputFields;
@synthesize clientStreaming = _clientStreaming;
@synthesize serverStreaming = _serverStreaming;
@synthesize exampleInput = _exampleInput;
@end

@implementation HOLServiceDoc
@synthesize name = _name;
@synthesize docDescription = _docDescription;
@synthesize methods = _methods;
@end

@implementation HOLDescribeResponse
@synthesize slug = _slug;
@synthesize motto = _motto;
@synthesize services = _services;
@end

@implementation HOLHolonMetaRegistration
@synthesize serviceName = _serviceName;
@synthesize methodName = _methodName;
@synthesize handler = _handler;
@end

@interface HOLMetaComment : NSObject
@property(nonatomic, copy) NSString *docDescription;
@property(nonatomic, assign) BOOL required;
@property(nonatomic, copy) NSString *example;
+ (instancetype)parse:(NSArray<NSString *> *)lines;
@end

@implementation HOLMetaComment
@synthesize docDescription = _docDescription;
@synthesize required = _required;
@synthesize example = _example;

+ (instancetype)parse:(NSArray<NSString *> *)lines {
  HOLMetaComment *comment = [HOLMetaComment new];
  NSMutableArray<NSString *> *descriptionLines = [NSMutableArray array];
  comment.docDescription = @"";
  comment.example = @"";

  for (NSString *raw in lines) {
    NSString *line = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([line isEqualToString:@"@required"]) {
      comment.required = YES;
      continue;
    }
    if ([line hasPrefix:@"@example "]) {
      comment.example = [[line substringFromIndex:9]
          stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      continue;
    }
    if (line.length > 0) {
      [descriptionLines addObject:line];
    }
  }

  comment.docDescription = [descriptionLines componentsJoinedByString:@" "];
  return comment;
}

@end

@interface HOLMetaEnumValueDef : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) NSInteger number;
@property(nonatomic, strong) HOLMetaComment *comment;
@end

@implementation HOLMetaEnumValueDef
@synthesize name = _name;
@synthesize number = _number;
@synthesize comment = _comment;
@end

typedef NS_ENUM(NSInteger, HOLMetaCardinality) {
  HOLMetaCardinalityOptional = 0,
  HOLMetaCardinalityRepeated = 1,
  HOLMetaCardinalityMap = 2,
};

@interface HOLMetaFieldDef : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *typeName;
@property(nonatomic, copy) NSString *rawType;
@property(nonatomic, assign) NSInteger number;
@property(nonatomic, strong) HOLMetaComment *comment;
@property(nonatomic, assign) HOLMetaCardinality cardinality;
@property(nonatomic, copy) NSString *packageName;
@property(nonatomic, copy) NSArray<NSString *> *scope;
@property(nonatomic, copy) NSString *mapKeyType;
@property(nonatomic, copy) NSString *mapValueType;
- (HOLFieldLabel)label;
@end

@implementation HOLMetaFieldDef
@synthesize name = _name;
@synthesize typeName = _typeName;
@synthesize rawType = _rawType;
@synthesize number = _number;
@synthesize comment = _comment;
@synthesize cardinality = _cardinality;
@synthesize packageName = _packageName;
@synthesize scope = _scope;
@synthesize mapKeyType = _mapKeyType;
@synthesize mapValueType = _mapValueType;

- (HOLFieldLabel)label {
  if (self.cardinality == HOLMetaCardinalityMap) {
    return HOLFieldLabelMap;
  }
  if (self.cardinality == HOLMetaCardinalityRepeated) {
    return HOLFieldLabelRepeated;
  }
  if (self.comment.required) {
    return HOLFieldLabelRequired;
  }
  return HOLFieldLabelOptional;
}

@end

@interface HOLMetaMessageDef : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *fullName;
@property(nonatomic, copy) NSString *packageName;
@property(nonatomic, copy) NSArray<NSString *> *scope;
@property(nonatomic, strong) HOLMetaComment *comment;
@property(nonatomic, copy) NSMutableArray<HOLMetaFieldDef *> *fields;
- (NSString *)simpleKey;
- (NSArray<NSString *> *)scopeWithSelf;
@end

@implementation HOLMetaMessageDef
@synthesize name = _name;
@synthesize fullName = _fullName;
@synthesize packageName = _packageName;
@synthesize scope = _scope;
@synthesize comment = _comment;
@synthesize fields = _fields;

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  _fields = [[NSMutableArray alloc] init];
  _scope = [[NSArray alloc] init];
  return self;
}

- (NSString *)simpleKey {
  NSMutableArray<NSString *> *parts = [NSMutableArray array];
  if (self.packageName.length > 0) {
    [parts addObject:self.packageName];
  }
  [parts addObjectsFromArray:self.scope ?: @[]];
  if (self.name.length > 0) {
    [parts addObject:self.name];
  }
  return [parts componentsJoinedByString:@"."];
}

- (NSArray<NSString *> *)scopeWithSelf {
  NSMutableArray<NSString *> *scope = [NSMutableArray arrayWithArray:self.scope ?: @[]];
  if (self.name.length > 0) {
    [scope addObject:self.name];
  }
  return scope;
}

@end

@interface HOLMetaEnumDef : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *fullName;
@property(nonatomic, copy) NSString *packageName;
@property(nonatomic, copy) NSArray<NSString *> *scope;
@property(nonatomic, strong) HOLMetaComment *comment;
@property(nonatomic, copy) NSMutableArray<HOLMetaEnumValueDef *> *values;
- (NSString *)simpleKey;
@end

@implementation HOLMetaEnumDef
@synthesize name = _name;
@synthesize fullName = _fullName;
@synthesize packageName = _packageName;
@synthesize scope = _scope;
@synthesize comment = _comment;
@synthesize values = _values;

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  _values = [[NSMutableArray alloc] init];
  _scope = [[NSArray alloc] init];
  return self;
}

- (NSString *)simpleKey {
  NSMutableArray<NSString *> *parts = [NSMutableArray array];
  if (self.packageName.length > 0) {
    [parts addObject:self.packageName];
  }
  [parts addObjectsFromArray:self.scope ?: @[]];
  if (self.name.length > 0) {
    [parts addObject:self.name];
  }
  return [parts componentsJoinedByString:@"."];
}

@end

@interface HOLMetaMethodDef : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *inputType;
@property(nonatomic, copy) NSString *outputType;
@property(nonatomic, assign) BOOL clientStreaming;
@property(nonatomic, assign) BOOL serverStreaming;
@property(nonatomic, strong) HOLMetaComment *comment;
@end

@implementation HOLMetaMethodDef
@synthesize name = _name;
@synthesize inputType = _inputType;
@synthesize outputType = _outputType;
@synthesize clientStreaming = _clientStreaming;
@synthesize serverStreaming = _serverStreaming;
@synthesize comment = _comment;
@end

@interface HOLMetaServiceDef : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *fullName;
@property(nonatomic, strong) HOLMetaComment *comment;
@property(nonatomic, copy) NSMutableArray<HOLMetaMethodDef *> *methodDefs;
@end

@implementation HOLMetaServiceDef
@synthesize name = _name;
@synthesize fullName = _fullName;
@synthesize comment = _comment;
@synthesize methodDefs = _methodDefs;

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  _methodDefs = [[NSMutableArray alloc] init];
  return self;
}

@end

@interface HOLMetaProtoIndex : NSObject
@property(nonatomic, copy) NSMutableArray<HOLMetaServiceDef *> *services;
@property(nonatomic, copy) NSMutableDictionary<NSString *, HOLMetaMessageDef *> *messages;
@property(nonatomic, copy) NSMutableDictionary<NSString *, HOLMetaEnumDef *> *enums;
@property(nonatomic, copy) NSMutableDictionary<NSString *, NSString *> *simpleTypes;
@end

@implementation HOLMetaProtoIndex
@synthesize services = _services;
@synthesize messages = _messages;
@synthesize enums = _enums;
@synthesize simpleTypes = _simpleTypes;

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  _services = [[NSMutableArray alloc] init];
  _messages = [[NSMutableDictionary alloc] init];
  _enums = [[NSMutableDictionary alloc] init];
  _simpleTypes = [[NSMutableDictionary alloc] init];
  return self;
}

@end

@interface HOLMetaBlock : NSObject
@property(nonatomic, copy) NSString *kind;
@property(nonatomic, strong, nullable) HOLMetaServiceDef *service;
@property(nonatomic, strong, nullable) HOLMetaMessageDef *message;
@property(nonatomic, strong, nullable) HOLMetaEnumDef *enumDef;
@end

@implementation HOLMetaBlock
@synthesize kind = _kind;
@synthesize service = _service;
@synthesize message = _message;
@synthesize enumDef = _enumDef;
@end

static NSError *HOLMetaMakeError(NSInteger code, NSString *message) {
  return [NSError errorWithDomain:HOLMetaErrorDomain
                             code:code
                         userInfo:@{NSLocalizedDescriptionKey : message ?: @"HolonMeta error"}];
}

static NSString *HOLMetaTrim(NSString *value) {
  return [value ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSRegularExpression *HOLMetaRegex(NSString *pattern) {
  static NSMutableDictionary<NSString *, NSRegularExpression *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSMutableDictionary alloc] init];
  });

  @synchronized(cache) {
    NSRegularExpression *regex = cache[pattern];
    if (regex != nil) {
      return regex;
    }
    regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    cache[pattern] = regex;
    return regex;
  }
}

static NSTextCheckingResult *HOLMetaFirstMatch(NSString *line, NSString *pattern) {
  NSRegularExpression *regex = HOLMetaRegex(pattern);
  return [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
}

static NSString *HOLMetaMatchGroup(NSString *line, NSTextCheckingResult *match, NSUInteger index) {
  if (match == nil || index >= match.numberOfRanges) {
    return nil;
  }
  NSRange range = [match rangeAtIndex:index];
  if (range.location == NSNotFound) {
    return nil;
  }
  return [line substringWithRange:range];
}

static NSString *HOLMetaQualify(NSString *packageName, NSString *name) {
  if (packageName.length == 0) {
    return name ?: @"";
  }
  return [NSString stringWithFormat:@"%@.%@", packageName, name ?: @""];
}

static NSString *HOLMetaQualifyScope(NSArray<NSString *> *scope, NSString *name) {
  if (scope.count == 0) {
    return name ?: @"";
  }
  NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithArray:scope];
  if (name.length > 0) {
    [parts addObject:name];
  }
  return [parts componentsJoinedByString:@"."];
}

static NSArray<NSString *> *HOLMetaMessageScope(NSArray<HOLMetaBlock *> *stack) {
  NSMutableArray<NSString *> *scope = [NSMutableArray array];
  for (HOLMetaBlock *block in stack) {
    if ([block.kind isEqualToString:@"message"] && block.message.name.length > 0) {
      [scope addObject:block.message.name];
    }
  }
  return scope;
}

static void HOLMetaTrimClosedBlocks(NSString *line, NSMutableArray<HOLMetaBlock *> *stack) {
  NSUInteger closeCount = 0;
  for (NSUInteger index = 0; index < line.length; index++) {
    if ([line characterAtIndex:index] == '}') {
      closeCount++;
    }
  }
  while (closeCount > 0 && stack.count > 0) {
    [stack removeLastObject];
    closeCount--;
  }
}

static HOLMetaServiceDef *HOLMetaCurrentService(NSArray<HOLMetaBlock *> *stack) {
  for (HOLMetaBlock *block in [stack reverseObjectEnumerator]) {
    if ([block.kind isEqualToString:@"service"]) {
      return block.service;
    }
  }
  return nil;
}

static HOLMetaMessageDef *HOLMetaCurrentMessage(NSArray<HOLMetaBlock *> *stack) {
  for (HOLMetaBlock *block in [stack reverseObjectEnumerator]) {
    if ([block.kind isEqualToString:@"message"]) {
      return block.message;
    }
  }
  return nil;
}

static HOLMetaEnumDef *HOLMetaCurrentEnum(NSArray<HOLMetaBlock *> *stack) {
  for (HOLMetaBlock *block in [stack reverseObjectEnumerator]) {
    if ([block.kind isEqualToString:@"enum"]) {
      return block.enumDef;
    }
  }
  return nil;
}

static NSString *HOLMetaResolveType(NSString *typeName,
                                    NSString *packageName,
                                    NSArray<NSString *> *scope,
                                    HOLMetaProtoIndex *index) {
  static NSSet<NSString *> *scalarTypes;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    scalarTypes = [[NSSet alloc] initWithArray:@[
      @"double", @"float", @"int64", @"uint64", @"int32", @"fixed64",
      @"fixed32", @"bool", @"string", @"bytes", @"uint32", @"sfixed32",
      @"sfixed64", @"sint32", @"sint64"
    ]];
  });

  NSString *trimmed = HOLMetaTrim(typeName);
  if (trimmed.length == 0) {
    return @"";
  }
  if ([trimmed hasPrefix:@"."]) {
    return [trimmed substringFromIndex:1];
  }
  if ([scalarTypes containsObject:trimmed]) {
    return trimmed;
  }

  NSMutableArray<NSString *> *searchScope = [NSMutableArray arrayWithArray:scope ?: @[]];
  while (searchScope.count > 0) {
    NSString *candidate = HOLMetaQualify(packageName, HOLMetaQualifyScope(searchScope, trimmed));
    if (index.messages[candidate] != nil || index.enums[candidate] != nil) {
      return candidate;
    }
    [searchScope removeLastObject];
  }

  NSString *packageCandidate = HOLMetaQualify(packageName, trimmed);
  if (index.messages[packageCandidate] != nil || index.enums[packageCandidate] != nil) {
    return packageCandidate;
  }

  NSString *simple = index.simpleTypes[trimmed];
  return simple ?: packageCandidate;
}

static NSString *HOLMetaSlugForIdentity(HOLHolonIdentity *identity) {
  NSString *givenName = HOLMetaTrim(identity.givenName);
  NSString *familyName = HOLMetaTrim(identity.familyName);
  NSMutableArray<NSString *> *parts = [NSMutableArray array];
  if (givenName.length > 0) {
    [parts addObject:givenName];
  }
  if (familyName.length > 0) {
    [parts addObject:familyName];
  }
  return [[parts componentsJoinedByString:@"-"] lowercaseString];
}

static HOLMetaProtoIndex *HOLMetaParseProtoDirectory(NSString *protoDir, NSError **error);
static HOLFieldDoc *HOLMetaBuildFieldDoc(HOLMetaFieldDef *field,
                                         HOLMetaProtoIndex *index,
                                         NSMutableSet<NSString *> *seen);

static NSArray<HOLEnumValueDoc *> *HOLMetaEnumValueDocs(NSString *typeName,
                                                        HOLMetaProtoIndex *index) {
  HOLMetaEnumDef *enumDef = index.enums[typeName];
  if (enumDef == nil) {
    return @[];
  }

  NSMutableArray<HOLEnumValueDoc *> *docs = [NSMutableArray array];
  for (HOLMetaEnumValueDef *value in enumDef.values) {
    HOLEnumValueDoc *doc = [HOLEnumValueDoc new];
    doc.name = value.name ?: @"";
    doc.number = value.number;
    doc.docDescription = value.comment.docDescription ?: @"";
    [docs addObject:doc];
  }
  return docs;
}

static NSArray<HOLFieldDoc *> *HOLMetaNestedFieldDocs(NSString *typeName,
                                                      HOLMetaProtoIndex *index,
                                                      NSMutableSet<NSString *> *seen) {
  HOLMetaMessageDef *message = index.messages[typeName];
  if (message == nil || [seen containsObject:message.fullName]) {
    return @[];
  }
  [seen addObject:message.fullName];

  NSMutableArray<HOLFieldDoc *> *docs = [NSMutableArray array];
  for (HOLMetaFieldDef *field in message.fields) {
    NSMutableSet<NSString *> *nextSeen = [seen mutableCopy];
    [docs addObject:HOLMetaBuildFieldDoc(field, index, nextSeen)];
  }
  return docs;
}

static HOLFieldDoc *HOLMetaBuildFieldDoc(HOLMetaFieldDef *field,
                                         HOLMetaProtoIndex *index,
                                         NSMutableSet<NSString *> *seen) {
  NSString *resolvedType = nil;
  if (field.cardinality == HOLMetaCardinalityMap) {
    resolvedType = HOLMetaResolveType(field.mapValueType, field.packageName, field.scope, index);
  } else {
    resolvedType = HOLMetaResolveType(field.rawType, field.packageName, field.scope, index);
  }

  HOLFieldDoc *doc = [HOLFieldDoc new];
  doc.name = field.name ?: @"";
  doc.type = field.typeName ?: @"";
  doc.number = field.number;
  doc.docDescription = field.comment.docDescription ?: @"";
  doc.label = [field label];
  doc.mapKeyType = field.mapKeyType ?: @"";
  doc.mapValueType = field.mapValueType ?: @"";
  doc.nestedFields = HOLMetaNestedFieldDocs(resolvedType, index, [seen mutableCopy]);
  doc.enumValues = HOLMetaEnumValueDocs(resolvedType, index);
  doc.required = field.comment.required;
  doc.example = field.comment.example ?: @"";
  return doc;
}

static HOLMethodDoc *HOLMetaBuildMethodDoc(HOLMetaMethodDef *method,
                                           HOLMetaProtoIndex *index) {
  HOLMethodDoc *doc = [HOLMethodDoc new];
  doc.name = method.name ?: @"";
  doc.docDescription = method.comment.docDescription ?: @"";
  doc.inputType = method.inputType ?: @"";
  doc.outputType = method.outputType ?: @"";
  doc.clientStreaming = method.clientStreaming;
  doc.serverStreaming = method.serverStreaming;
  doc.exampleInput = method.comment.example ?: @"";

  HOLMetaMessageDef *input = index.messages[method.inputType];
  if (input != nil) {
    NSMutableArray<HOLFieldDoc *> *fields = [NSMutableArray array];
    for (HOLMetaFieldDef *field in input.fields) {
      [fields addObject:HOLMetaBuildFieldDoc(field, index, [NSMutableSet set])];
    }
    doc.inputFields = fields;
  } else {
    doc.inputFields = @[];
  }

  HOLMetaMessageDef *output = index.messages[method.outputType];
  if (output != nil) {
    NSMutableArray<HOLFieldDoc *> *fields = [NSMutableArray array];
    for (HOLMetaFieldDef *field in output.fields) {
      [fields addObject:HOLMetaBuildFieldDoc(field, index, [NSMutableSet set])];
    }
    doc.outputFields = fields;
  } else {
    doc.outputFields = @[];
  }
  return doc;
}

static HOLServiceDoc *HOLMetaBuildServiceDoc(HOLMetaServiceDef *service,
                                             HOLMetaProtoIndex *index) {
  HOLServiceDoc *doc = [HOLServiceDoc new];
  doc.name = service.fullName ?: @"";
  doc.docDescription = service.comment.docDescription ?: @"";
  NSMutableArray<HOLMethodDoc *> *methods = [NSMutableArray array];
  for (HOLMetaMethodDef *method in service.methodDefs) {
    [methods addObject:HOLMetaBuildMethodDoc(method, index)];
  }
  doc.methods = methods;
  return doc;
}

static HOLMetaProtoIndex *HOLMetaParseProtoDirectory(NSString *protoDir, NSError **error) {
  HOLMetaProtoIndex *index = [HOLMetaProtoIndex new];
  BOOL isDirectory = NO;
  if (![[NSFileManager defaultManager] fileExistsAtPath:protoDir isDirectory:&isDirectory] ||
      !isDirectory) {
    return index;
  }

  NSMutableArray<NSString *> *files = [NSMutableArray array];
  NSDirectoryEnumerator *enumerator =
      [[NSFileManager defaultManager] enumeratorAtPath:protoDir];
  for (NSString *path in enumerator) {
    if ([[path pathExtension] isEqualToString:@"proto"]) {
      [files addObject:[protoDir stringByAppendingPathComponent:path]];
    }
  }
  [files sortUsingSelector:@selector(compare:)];

  NSString *packagePattern = @"^package\\s+([A-Za-z0-9_.]+)\\s*;$";
  NSString *servicePattern = @"^service\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\{?";
  NSString *messagePattern = @"^message\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\{?";
  NSString *enumPattern = @"^enum\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\{?";
  NSString *rpcPattern =
      @"^rpc\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\(\\s*(stream\\s+)?([.A-Za-z0-9_]+)\\s*\\)\\s*returns\\s*\\(\\s*(stream\\s+)?([.A-Za-z0-9_]+)\\s*\\)\\s*;?";
  NSString *mapFieldPattern =
      @"^(repeated\\s+)?map\\s*<\\s*([.A-Za-z0-9_]+)\\s*,\\s*([.A-Za-z0-9_]+)\\s*>\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*(\\d+)\\s*;";
  NSString *fieldPattern =
      @"^(optional\\s+|repeated\\s+)?([.A-Za-z0-9_]+)\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*(\\d+)\\s*;";
  NSString *enumValuePattern =
      @"^([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*(-?\\d+)\\s*;";

  for (NSString *path in files) {
    NSError *readError = nil;
    NSString *text = [NSString stringWithContentsOfFile:path
                                               encoding:NSUTF8StringEncoding
                                                  error:&readError];
    if (text == nil) {
      if (error != NULL) {
        *error = readError ?: HOLMetaMakeError(1, [NSString stringWithFormat:@"failed to read %@", path]);
      }
      return nil;
    }

    __block NSString *packageName = @"";
    NSMutableArray<HOLMetaBlock *> *stack = [NSMutableArray array];
    NSMutableArray<NSString *> *pendingComments = [NSMutableArray array];

    [text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
      NSString *trimmed = HOLMetaTrim(line);
      if ([trimmed hasPrefix:@"//"]) {
        [pendingComments addObject:HOLMetaTrim([trimmed substringFromIndex:2])];
        return;
      }
      if (trimmed.length == 0) {
        return;
      }

      NSTextCheckingResult *match = HOLMetaFirstMatch(trimmed, packagePattern);
      if (match != nil) {
        packageName = HOLMetaMatchGroup(trimmed, match, 1) ?: @"";
        [pendingComments removeAllObjects];
        return;
      }

      match = HOLMetaFirstMatch(trimmed, servicePattern);
      if (match != nil) {
        HOLMetaServiceDef *service = [HOLMetaServiceDef new];
        service.name = HOLMetaMatchGroup(trimmed, match, 1) ?: @"";
        service.fullName = HOLMetaQualify(packageName, service.name);
        service.comment = [HOLMetaComment parse:pendingComments];
        [pendingComments removeAllObjects];
        [index.services addObject:service];

        HOLMetaBlock *block = [HOLMetaBlock new];
        block.kind = @"service";
        block.service = service;
        [stack addObject:block];
        HOLMetaTrimClosedBlocks(trimmed, stack);
        return;
      }

      match = HOLMetaFirstMatch(trimmed, messagePattern);
      if (match != nil) {
        NSArray<NSString *> *scope = HOLMetaMessageScope(stack);
        HOLMetaMessageDef *message = [HOLMetaMessageDef new];
        message.name = HOLMetaMatchGroup(trimmed, match, 1) ?: @"";
        message.fullName = HOLMetaQualify(packageName, HOLMetaQualifyScope(scope, message.name));
        message.packageName = packageName ?: @"";
        message.scope = scope ?: @[];
        message.comment = [HOLMetaComment parse:pendingComments];
        [pendingComments removeAllObjects];
        index.messages[message.fullName] = message;
        index.simpleTypes[message.simpleKey] = message.fullName;

        HOLMetaBlock *block = [HOLMetaBlock new];
        block.kind = @"message";
        block.message = message;
        [stack addObject:block];
        HOLMetaTrimClosedBlocks(trimmed, stack);
        return;
      }

      match = HOLMetaFirstMatch(trimmed, enumPattern);
      if (match != nil) {
        NSArray<NSString *> *scope = HOLMetaMessageScope(stack);
        HOLMetaEnumDef *enumDef = [HOLMetaEnumDef new];
        enumDef.name = HOLMetaMatchGroup(trimmed, match, 1) ?: @"";
        enumDef.fullName = HOLMetaQualify(packageName, HOLMetaQualifyScope(scope, enumDef.name));
        enumDef.packageName = packageName ?: @"";
        enumDef.scope = scope ?: @[];
        enumDef.comment = [HOLMetaComment parse:pendingComments];
        [pendingComments removeAllObjects];
        index.enums[enumDef.fullName] = enumDef;
        index.simpleTypes[enumDef.simpleKey] = enumDef.fullName;

        HOLMetaBlock *block = [HOLMetaBlock new];
        block.kind = @"enum";
        block.enumDef = enumDef;
        [stack addObject:block];
        HOLMetaTrimClosedBlocks(trimmed, stack);
        return;
      }

      match = HOLMetaFirstMatch(trimmed, rpcPattern);
      if (match != nil) {
        HOLMetaServiceDef *service = HOLMetaCurrentService(stack);
        if (service != nil) {
          HOLMetaMethodDef *method = [HOLMetaMethodDef new];
          method.name = HOLMetaMatchGroup(trimmed, match, 1) ?: @"";
          method.inputType = HOLMetaResolveType(HOLMetaMatchGroup(trimmed, match, 3) ?: @"",
                                                packageName,
                                                @[],
                                                index);
          method.outputType = HOLMetaResolveType(HOLMetaMatchGroup(trimmed, match, 5) ?: @"",
                                                 packageName,
                                                 @[],
                                                 index);
          method.clientStreaming = [HOLMetaMatchGroup(trimmed, match, 2) length] > 0;
          method.serverStreaming = [HOLMetaMatchGroup(trimmed, match, 4) length] > 0;
          method.comment = [HOLMetaComment parse:pendingComments];
          [service.methodDefs addObject:method];
        }
        [pendingComments removeAllObjects];
        HOLMetaTrimClosedBlocks(trimmed, stack);
        return;
      }

      match = HOLMetaFirstMatch(trimmed, mapFieldPattern);
      if (match != nil) {
        HOLMetaMessageDef *message = HOLMetaCurrentMessage(stack);
        if (message != nil) {
          HOLMetaFieldDef *field = [HOLMetaFieldDef new];
          field.name = HOLMetaMatchGroup(trimmed, match, 4) ?: @"";
          field.typeName =
              [NSString stringWithFormat:@"map<%@,%@>",
                                         HOLMetaMatchGroup(trimmed, match, 2) ?: @"",
                                         HOLMetaMatchGroup(trimmed, match, 3) ?: @""];
          field.rawType = @"map";
          field.number = [HOLMetaMatchGroup(trimmed, match, 5) integerValue];
          field.comment = [HOLMetaComment parse:pendingComments];
          field.cardinality = HOLMetaCardinalityMap;
          field.packageName = packageName ?: @"";
          field.scope = [message scopeWithSelf] ?: @[];
          field.mapKeyType = HOLMetaMatchGroup(trimmed, match, 2) ?: @"";
          field.mapValueType = HOLMetaMatchGroup(trimmed, match, 3) ?: @"";
          [message.fields addObject:field];
        }
        [pendingComments removeAllObjects];
        HOLMetaTrimClosedBlocks(trimmed, stack);
        return;
      }

      match = HOLMetaFirstMatch(trimmed, fieldPattern);
      if (match != nil) {
        HOLMetaMessageDef *message = HOLMetaCurrentMessage(stack);
        if (message != nil) {
          HOLMetaFieldDef *field = [HOLMetaFieldDef new];
          NSString *qualifier = HOLMetaTrim(HOLMetaMatchGroup(trimmed, match, 1) ?: @"");
          NSString *rawType = HOLMetaMatchGroup(trimmed, match, 2) ?: @"";
          field.name = HOLMetaMatchGroup(trimmed, match, 3) ?: @"";
          field.typeName = HOLMetaResolveType(rawType, packageName, [message scopeWithSelf], index);
          field.rawType = rawType;
          field.number = [HOLMetaMatchGroup(trimmed, match, 4) integerValue];
          field.comment = [HOLMetaComment parse:pendingComments];
          field.cardinality = [qualifier isEqualToString:@"repeated"] ? HOLMetaCardinalityRepeated
                                                                      : HOLMetaCardinalityOptional;
          field.packageName = packageName ?: @"";
          field.scope = [message scopeWithSelf] ?: @[];
          field.mapKeyType = @"";
          field.mapValueType = @"";
          [message.fields addObject:field];
        }
        [pendingComments removeAllObjects];
        HOLMetaTrimClosedBlocks(trimmed, stack);
        return;
      }

      match = HOLMetaFirstMatch(trimmed, enumValuePattern);
      if (match != nil) {
        HOLMetaEnumDef *enumDef = HOLMetaCurrentEnum(stack);
        if (enumDef != nil) {
          HOLMetaEnumValueDef *value = [HOLMetaEnumValueDef new];
          value.name = HOLMetaMatchGroup(trimmed, match, 1) ?: @"";
          value.number = [HOLMetaMatchGroup(trimmed, match, 2) integerValue];
          value.comment = [HOLMetaComment parse:pendingComments];
          [enumDef.values addObject:value];
        }
        [pendingComments removeAllObjects];
        HOLMetaTrimClosedBlocks(trimmed, stack);
        return;
      }

      if (![trimmed isEqualToString:@"}"]) {
        [pendingComments removeAllObjects];
      }
      HOLMetaTrimClosedBlocks(trimmed, stack);
    }];
  }

  return index;
}

HOLDescribeResponse *HOLBuildDescribeResponse(NSString *protoDir,
                                             NSString *holonYamlPath,
                                             NSError **error) {
  NSError *identityError = nil;
  HOLHolonIdentity *identity = HOLParseHolon(holonYamlPath, &identityError);
  if (identity == nil) {
    if (error != NULL) {
      *error = identityError ?: HOLMetaMakeError(2, @"failed to parse holon.yaml");
    }
    return nil;
  }

  NSError *parseError = nil;
  HOLMetaProtoIndex *index = HOLMetaParseProtoDirectory(protoDir, &parseError);
  if (index == nil) {
    if (error != NULL) {
      *error = parseError ?: HOLMetaMakeError(3, @"failed to parse proto directory");
    }
    return nil;
  }

  HOLDescribeResponse *response = [HOLDescribeResponse new];
  response.slug = HOLMetaSlugForIdentity(identity);
  response.motto = identity.motto ?: @"";

  NSMutableArray<HOLServiceDoc *> *services = [NSMutableArray array];
  for (HOLMetaServiceDef *service in index.services) {
    if ([service.fullName isEqualToString:HOLMetaServiceName]) {
      continue;
    }
    [services addObject:HOLMetaBuildServiceDoc(service, index)];
  }
  response.services = services;
  return response;
}

HOLHolonMetaRegistration *HOLMakeHolonMetaRegistration(NSString *protoDir,
                                                       NSString *holonYamlPath) {
  HOLHolonMetaRegistration *registration = [HOLHolonMetaRegistration new];
  registration.serviceName = HOLMetaServiceName;
  registration.methodName = @"Describe";
  registration.handler = ^HOLDescribeResponse *_Nullable(HOLDescribeRequest *_Nonnull request) {
    (void)request;
    return HOLBuildDescribeResponse(protoDir, holonYamlPath, nil);
  };
  return registration;
}
