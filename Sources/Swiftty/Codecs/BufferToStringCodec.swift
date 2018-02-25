import Foundation

open class BufferToStringCodec: Codec<Data, String> {
    public override func encode(_ data: String) -> Data {
        return data.data(using: .utf8) ?? Data()
    }
    
    public override func decode(_ data: Data) -> String {
        return String(data: data, encoding: .utf8) ?? ""
    }
}
