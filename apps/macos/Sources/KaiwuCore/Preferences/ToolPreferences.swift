import Foundation

/// 设置页与工具页面共用的键和默认值；不持久化 Secret。
public enum ToolPreferences {
    public static let probeURLKey = "network.probeURL"
    public static let defaultProbeURL = "https://www.baidu.com"
    public static let controllerEndpointKey = "proxy.controllerEndpoint"
    public static let defaultControllerEndpoint = "http://127.0.0.1:9090"
    public static let externalProbesKey = "network.externalProbes"
    public static let defaultExternalProbes = true
}
