//
// Copyright 2022 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

extension Bundle {

    private enum InfoPlistKey: String {
        case bundleIdPrefix = "OWSBundleIDPrefix"
        case merchantId = "OWSMerchantID"
        case applicationGroupIdentifier = "OWSApplicationGroupIdentifier"
        case applicationGroupIdentifierStaging = "OWSApplicationGroupIdentifierStaging"
    }

    private func infoPlistString(for key: InfoPlistKey) -> String? {
        object(forInfoDictionaryKey: key.rawValue) as? String
    }

    /// Returns the value of the OWSBundleIDPrefix from current executable's Info.plist
    /// Note: This does not parse the executable's bundleID. This only returns the value of OWSBundleIDPrefix
    /// (which the bundleID should be derived from)
    public var bundleIdPrefix: String {
        if let prefix = infoPlistString(for: Self.InfoPlistKey.bundleIdPrefix) {
            return prefix
        } else {
            owsFailDebug("Missing Info.plist entry for OWSBundleIDPrefix")
            return "org.whispersystems"
        }
    }

    /// Returns the value of the OWSMerchantID from current executable's Info.plist
    public var merchantId: String {
        if let prefix = infoPlistString(for: Self.InfoPlistKey.merchantId) {
            return prefix
        } else {
            owsFailDebug("Missing Info.plist entry for OWSMerchantID")
            return "org.signalfoundation"
        }
    }

    /// Returns the value of OWSApplicationGroupIdentifier from the current executable's Info.plist.
    ///
    /// This lets a personal/forked build point at an App Group ID it actually owns (e.g. one granted
    /// by a non-Signal provisioning profile), by overriding the SIGNAL_APP_GROUP build setting, without
    /// touching this default. Every target that shares the app's data (Signal, SignalNSE,
    /// SignalShareExtension) must be built with the same value, since they read this from their own
    /// Info.plist rather than the container app's.
    public var applicationGroupIdentifier: String {
        if let value = infoPlistString(for: Self.InfoPlistKey.applicationGroupIdentifier) {
            return value
        } else {
            owsFailDebug("Missing Info.plist entry for OWSApplicationGroupIdentifier")
            return "group." + bundleIdPrefix + ".signal.group"
        }
    }

    /// Returns the value of OWSApplicationGroupIdentifierStaging from the current executable's Info.plist.
    /// See `applicationGroupIdentifier` above.
    public var applicationGroupIdentifierStaging: String {
        if let value = infoPlistString(for: Self.InfoPlistKey.applicationGroupIdentifierStaging) {
            return value
        } else {
            owsFailDebug("Missing Info.plist entry for OWSApplicationGroupIdentifierStaging")
            return "group." + bundleIdPrefix + ".signal.group.staging"
        }
    }
}
