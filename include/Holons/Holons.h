#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Default transport URI when --listen is omitted.
extern NSString *const HOLDefaultURI;

@interface HOLParsedURI : NSObject

@property(nonatomic, copy) NSString *raw;
@property(nonatomic, copy) NSString *scheme;
@property(nonatomic, copy, nullable) NSString *host;
@property(nonatomic, strong, nullable) NSNumber *port;
@property(nonatomic, copy, nullable) NSString *path;
@property(nonatomic, assign) BOOL secure;

@end

@interface HOLTransportListener : NSObject
@end

@interface HOLTcpListener : HOLTransportListener
@property(nonatomic, assign) int fd;
@property(nonatomic, copy) NSString *host;
@property(nonatomic, assign) int port;
@end

@interface HOLUnixListener : HOLTransportListener
@property(nonatomic, assign) int fd;
@property(nonatomic, copy) NSString *path;
@end

@interface HOLStdioListener : HOLTransportListener
@property(nonatomic, copy) NSString *address;
@property(nonatomic, assign) BOOL consumed;
@end

@interface HOLMemListener : HOLTransportListener
@property(nonatomic, copy) NSString *address;
@property(nonatomic, assign) int serverFD;
@property(nonatomic, assign) int clientFD;
@property(nonatomic, assign) BOOL serverConsumed;
@property(nonatomic, assign) BOOL clientConsumed;
@end

@interface HOLWSListener : HOLTransportListener
@property(nonatomic, copy) NSString *host;
@property(nonatomic, assign) int port;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, assign) BOOL secure;
@end

@interface HOLConnection : NSObject
@property(nonatomic, assign) int readFD;
@property(nonatomic, assign) int writeFD;
@property(nonatomic, copy) NSString *scheme;
@property(nonatomic, assign) BOOL ownsReadFD;
@property(nonatomic, assign) BOOL ownsWriteFD;
@end

@interface GRPCChannel : NSObject
@property(nonatomic, copy, readonly) NSString *target;
@property(nonatomic, copy, readonly) NSString *transport;
@end

typedef NSDictionary<NSString *, id> *_Nonnull (^HOLHolonRPCHandler)(
    NSDictionary<NSString *, id> *_Nonnull params);

@interface HOLHolonRPCClient : NSObject <NSURLSessionWebSocketDelegate, NSURLSessionTaskDelegate>

- (instancetype)init;

- (instancetype)initWithHeartbeatIntervalMS:(NSInteger)heartbeatIntervalMS
                         heartbeatTimeoutMS:(NSInteger)heartbeatTimeoutMS
                        reconnectMinDelayMS:(NSInteger)reconnectMinDelayMS
                        reconnectMaxDelayMS:(NSInteger)reconnectMaxDelayMS
                            reconnectFactor:(double)reconnectFactor
                            reconnectJitter:(double)reconnectJitter
                           connectTimeoutMS:(NSInteger)connectTimeoutMS
                           requestTimeoutMS:(NSInteger)requestTimeoutMS NS_DESIGNATED_INITIALIZER;

- (BOOL)connect:(NSString *)url error:(NSError *_Nullable *_Nullable)error;

- (nullable NSDictionary<NSString *, id> *)invoke:(NSString *)method
                                            params:
                                                (nullable NSDictionary<NSString *, id> *)params
                                           timeout:(NSTimeInterval)timeout
                                             error:(NSError *_Nullable *_Nullable)error;

- (nullable NSDictionary<NSString *, id> *)invoke:(NSString *)method
                                            params:
                                                (nullable NSDictionary<NSString *, id> *)params
                                             error:(NSError *_Nullable *_Nullable)error;

- (void)registerMethod:(NSString *)method handler:(HOLHolonRPCHandler)handler;

- (void)close;

@end

@interface HOLHolonIdentity : NSObject
@property(nonatomic, copy) NSString *uuid;
@property(nonatomic, copy) NSString *givenName;
@property(nonatomic, copy) NSString *familyName;
@property(nonatomic, copy) NSString *motto;
@property(nonatomic, copy) NSString *composer;
@property(nonatomic, copy) NSString *clade;
@property(nonatomic, copy) NSString *status;
@property(nonatomic, copy) NSString *born;
@property(nonatomic, copy) NSString *lang;
@property(nonatomic, copy) NSArray<NSString *> *parents;
@property(nonatomic, copy) NSString *reproduction;
@property(nonatomic, copy) NSString *generatedBy;
@property(nonatomic, copy) NSString *protoStatus;
@property(nonatomic, copy) NSArray<NSString *> *aliases;
@end

@interface HOLHolonBuild : NSObject
@property(nonatomic, copy) NSString *runner;
@property(nonatomic, copy) NSString *main;
@end

@interface HOLHolonArtifacts : NSObject
@property(nonatomic, copy) NSString *binary;
@property(nonatomic, copy) NSString *primary;
@end

@interface HOLHolonManifest : NSObject
@property(nonatomic, copy) NSString *kind;
@property(nonatomic, strong) HOLHolonBuild *build;
@property(nonatomic, strong) HOLHolonArtifacts *artifacts;
@end

@interface HOLHolonEntry : NSObject
@property(nonatomic, copy) NSString *slug;
@property(nonatomic, copy) NSString *uuid;
@property(nonatomic, copy) NSString *dir;
@property(nonatomic, copy) NSString *relativePath;
@property(nonatomic, copy) NSString *origin;
@property(nonatomic, strong) HOLHolonIdentity *identity;
@property(nonatomic, strong, nullable) HOLHolonManifest *manifest;
@end

@interface HolonsConnectOptions : NSObject
@property(nonatomic) NSTimeInterval timeout;
@property(nonatomic, copy) NSString *transport;
@property(nonatomic) BOOL start;
@property(nonatomic, copy, nullable) NSString *portFile;
@end

typedef NS_ENUM(NSInteger, HOLFieldLabel) {
  HOLFieldLabelUnspecified = 0,
  HOLFieldLabelOptional = 1,
  HOLFieldLabelRepeated = 2,
  HOLFieldLabelMap = 3,
  HOLFieldLabelRequired = 4,
};

@interface HOLDescribeRequest : NSObject
@end

@interface HOLEnumValueDoc : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) NSInteger number;
@property(nonatomic, copy) NSString *docDescription;
@end

@interface HOLFieldDoc : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *type;
@property(nonatomic, assign) NSInteger number;
@property(nonatomic, copy) NSString *docDescription;
@property(nonatomic, assign) HOLFieldLabel label;
@property(nonatomic, copy) NSString *mapKeyType;
@property(nonatomic, copy) NSString *mapValueType;
@property(nonatomic, copy) NSArray<HOLFieldDoc *> *nestedFields;
@property(nonatomic, copy) NSArray<HOLEnumValueDoc *> *enumValues;
@property(nonatomic, assign) BOOL required;
@property(nonatomic, copy) NSString *example;
@end

@interface HOLMethodDoc : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *docDescription;
@property(nonatomic, copy) NSString *inputType;
@property(nonatomic, copy) NSString *outputType;
@property(nonatomic, copy) NSArray<HOLFieldDoc *> *inputFields;
@property(nonatomic, copy) NSArray<HOLFieldDoc *> *outputFields;
@property(nonatomic, assign) BOOL clientStreaming;
@property(nonatomic, assign) BOOL serverStreaming;
@property(nonatomic, copy) NSString *exampleInput;
@end

@interface HOLServiceDoc : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *docDescription;
@property(nonatomic, copy) NSArray<HOLMethodDoc *> *methods;
@end

@interface HOLDescribeResponse : NSObject
@property(nonatomic, copy) NSString *slug;
@property(nonatomic, copy) NSString *motto;
@property(nonatomic, copy) NSArray<HOLServiceDoc *> *services;
@end

typedef HOLDescribeResponse *_Nullable (^HOLDescribeHandler)(HOLDescribeRequest *_Nonnull request);

@interface HOLHolonMetaRegistration : NSObject
@property(nonatomic, copy) NSString *serviceName;
@property(nonatomic, copy) NSString *methodName;
@property(nonatomic, copy) HOLDescribeHandler handler;
@end

@interface Holons : NSObject
+ (nullable GRPCChannel *)connect:(NSString *)target;
+ (nullable GRPCChannel *)connect:(NSString *)target options:(HolonsConnectOptions *)options;
+ (void)disconnect:(nullable GRPCChannel *)channel;
@end

/// Extract the scheme from a transport URI.
NSString *HOLScheme(NSString *uri);

/// Parse a transport URI into a normalized structure.
HOLParsedURI *HOLParseURI(NSString *uri);

/// Parse a transport URI and return a listener variant.
HOLTransportListener *_Nullable HOLListen(NSString *uri, NSError *_Nullable *_Nullable error);

/// Accept one runtime connection from a listener.
HOLConnection *_Nullable HOLAccept(HOLTransportListener *listener,
                                   NSError *_Nullable *_Nullable error);

/// Dial the client side of a `mem://` listener.
HOLConnection *_Nullable HOLMemDial(HOLTransportListener *listener,
                                    NSError *_Nullable *_Nullable error);

/// Read bytes from a runtime connection.
ssize_t HOLConnectionRead(HOLConnection *connection, void *buffer, size_t count);

/// Write bytes to a runtime connection.
ssize_t HOLConnectionWrite(HOLConnection *connection, const void *buffer, size_t count);

/// Close file descriptors held by a runtime connection.
void HOLCloseConnection(HOLConnection *connection);

/// Parse --listen or --port from command-line args.
NSString *HOLParseFlags(NSArray<NSString *> *args);

/// Parse a holon.yaml identity mapping.
HOLHolonIdentity *_Nullable HOLParseHolon(NSString *path,
                                          NSError *_Nullable *_Nullable error);

/// Discover holons under a filesystem root.
NSArray<HOLHolonEntry *> *_Nullable HOLDiscover(NSString *root,
                                                NSError *_Nullable *_Nullable error);

/// Discover holons from the current working directory.
NSArray<HOLHolonEntry *> *_Nullable HOLDiscoverLocal(NSError *_Nullable *_Nullable error);

/// Discover holons from the current working directory, $OPBIN, and cache.
NSArray<HOLHolonEntry *> *_Nullable HOLDiscoverAll(NSError *_Nullable *_Nullable error);

/// Find a holon by slug across local, $OPBIN, and cache search roots.
HOLHolonEntry *_Nullable HOLFindBySlug(NSString *slug, NSError *_Nullable *_Nullable error);

/// Find a holon by UUID prefix across local, $OPBIN, and cache search roots.
HOLHolonEntry *_Nullable HOLFindByUUID(NSString *prefix, NSError *_Nullable *_Nullable error);

/// Build a HolonMeta Describe response from local proto files and holon.yaml.
HOLDescribeResponse *_Nullable HOLBuildDescribeResponse(
    NSString *protoDir,
    NSString *holonYamlPath,
    NSError *_Nullable *_Nullable error);

/// Create a manual HolonMeta registration for SDKs without a full serve runner.
HOLHolonMetaRegistration *HOLMakeHolonMetaRegistration(NSString *protoDir,
                                                       NSString *holonYamlPath);

/// Close any open descriptors associated with a listener.
void HOLCloseListener(HOLTransportListener *listener);

NS_ASSUME_NONNULL_END
