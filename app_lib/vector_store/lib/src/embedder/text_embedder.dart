/// Interface for converting text into vector embeddings.
///
/// Implementations can range from simple TF-IDF to ML-based models
/// (TF-Lite, ONNX, platform channels).
abstract class TextEmbedder {
  /// The dimensionality of produced embeddings.
  int get dimension;

  /// Converts [text] into a fixed-length vector of doubles.
  List<double> embed(String text);

  /// Releases any resources held by this embedder.
  void dispose();
}
