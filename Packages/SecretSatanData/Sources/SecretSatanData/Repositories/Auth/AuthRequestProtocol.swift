import Foundation

/// Public data the app must provide to call the Auth repository.
/// Declare here the fields the services need; AuthRequestDAO turns them into the wire format.
public protocol AuthRequestProtocol: Sendable {}
