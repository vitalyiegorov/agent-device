/*
 * Request validation for the private Simulator AX reader, shared by the guest server
 * (SnapshotBridge.m) and the XCTest runner, which serves the same reader without a guest process.
 */

#import "SnapshotBridgeRequest.h"
#import "SnapshotBridgeRuntime.h"

#import <limits.h>
#import <math.h>

NSDictionary *failureResponse(NSString *requestId,
                              NSString *kind,
                              NSString *code,
                              NSString *message)
{
  return @{
    kProtocolVersionKey : @(kProtocolVersion),
    kSourceVersionKey : kSourceVersion,
    kRequestIdKey : requestId ?: @"",
    @"ok" : @NO,
    @"error_kind" : kind ?: @"reader_unavailable",
    @"error_code" : code ?: @"unknown",
    @"error" : message ?: @"snapshot bridge request failed",
  };
}

static BOOL validBoundInteger(id value, NSUInteger minimum, NSUInteger maximum, NSUInteger *output)
{
  if (![value isKindOfClass:NSNumber.class]) return NO;
  NSNumber *number = value;
  if (number.doubleValue != floor(number.doubleValue)) return NO;
  if (number.unsignedIntegerValue < minimum || number.unsignedIntegerValue > maximum) return NO;
  if (output) *output = number.unsignedIntegerValue;
  return YES;
}

NSDictionary *SnapshotBridgeHandleRequest(NSDictionary *request)
{
  NSString *requestId = [request[kRequestIdKey] isKindOfClass:NSString.class] ? request[kRequestIdKey] : @"";
  id verb = request[@"verb"];
  if (![verb isKindOfClass:NSString.class] || ![verb isEqualToString:@"describe"]) {
    return failureResponse(requestId, @"bad_request", @"verb-not-supported", @"snapshot bridge accepts describe requests only");
  }
  NSNumber *pidValue = request[@"pid"];
  if (!validBoundInteger(pidValue, 1, INT_MAX, NULL)) {
    return failureResponse(requestId, @"bad_request", @"pid-required", @"describe requires a positive target pid");
  }
  NSString *generation = [request[@"generation"] isKindOfClass:NSString.class] ? request[@"generation"] : @"";
  if (generation.length == 0) {
    return failureResponse(requestId, @"bad_request", @"generation-required", @"describe requires an opaque target generation");
  }
  id snapshotTree = request[@"snapshotTree"];
  if (![snapshotTree isKindOfClass:NSNumber.class] || ![snapshotTree boolValue]) {
    return failureResponse(requestId, @"bad_request", @"snapshot-tree-required", @"snapshotTree must be enabled");
  }
  id automationMode = request[@"automationMode"];
  if (![automationMode isKindOfClass:NSNumber.class] || ![automationMode boolValue]) {
    return failureResponse(requestId, @"bad_request", @"automation-mode-required", @"automationMode must be enabled");
  }
  NSUInteger maxDepth = 0;
  NSUInteger maxNodes = 0;
  NSUInteger maxDurationMs = 0;
  NSUInteger maxResponseBytes = 0;
  if (!validBoundInteger(request[@"maxDepth"], 0, kMaximumDepth, &maxDepth) ||
      !validBoundInteger(request[@"maxNodes"], 1, kMaximumNodes, &maxNodes) ||
      !validBoundInteger(request[@"maxDurationMs"], 1, kMaximumDurationMs, &maxDurationMs) ||
      !validBoundInteger(request[@"maxResponseBytes"], 1024, kMaximumFrameBytes, &maxResponseBytes)) {
    return failureResponse(requestId, @"bad_request", @"bounds-invalid", @"snapshot bridge request bounds are outside the bridge limits");
  }
  NSUInteger nativeLevelsHint = 0;
  if (request[@"nativeLevelsHint"] != nil &&
      !validBoundInteger(request[@"nativeLevelsHint"], 1, kMaximumDepth + 1, &nativeLevelsHint)) {
    return failureResponse(requestId, @"bad_request", @"bounds-invalid", @"nativeLevelsHint is outside the bridge depth limits");
  }

  NSString *setupError = nil;
  BridgeRuntime *runtime = sharedRuntime(&setupError);
  if (!runtime) {
    NSMutableDictionary *unavailable = [failureResponse(requestId, @"unsupported", @"runtime-unavailable", setupError) mutableCopy];
    unavailable[@"pid"] = pidValue;
    unavailable[@"generation"] = generation;
    return unavailable;
  }
  NSDictionary *error = nil;
  NSDictionary *response = [runtime snapshotForProcess:pidValue.intValue
                                               maxDepth:maxDepth
                                               maxNodes:maxNodes
                                       nativeLevelsHint:nativeLevelsHint
                                             requestId:requestId
                                           generation:generation
                                         maxDurationMs:maxDurationMs
                                                 error:&error];
  if (response) return response;
  if (error) {
    NSMutableDictionary *annotated = [error mutableCopy];
    annotated[@"pid"] = pidValue;
    annotated[@"generation"] = generation;
    return annotated;
  }
  return failureResponse(requestId, @"reader_unavailable", @"empty-response", @"AX bridge returned no response");
}
