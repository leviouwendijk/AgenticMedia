import Images
import MediaAV
import Schema
import Transcribe

extension MediaAssetInspection:
    @retroactive JSONSchemaProviding
{
    public static var jsonschema: JSONSchema {
        .object()
    }
}

extension ImageCompressionReport:
    @retroactive JSONSchemaProviding
{
    public static var jsonschema: JSONSchema {
        .object()
    }
}

extension Transcription:
    @retroactive JSONSchemaProviding
{
    public static var jsonschema: JSONSchema {
        .object()
    }
}

extension ImageDiscoveryOutput: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object()
    }
}

extension LTCProbeOutput: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object()
    }
}

extension TimecodeLTCRemuxOutput: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .object()
    }
}
