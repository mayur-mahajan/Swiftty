public enum ProtocolFamily {
    case inet
    case inet6
}

public enum SocketType {
    case stream
    case datagram
}

public enum Protocol {
    case TCP
    case UDP
}

// Defining the space to which the address belongs
public enum AddressFamily {
    case inet
    case inet6
    case unspecified    
}

public protocol Address {
}

public typealias Port = UInt16

public typealias Byte = UInt8
