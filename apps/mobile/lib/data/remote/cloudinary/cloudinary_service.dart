/// Builds Cloudinary delivery URLs using on-the-fly transformations —
/// no server round trip needed for basic resizing/format conversion.
class CloudinaryService {
  final String cloudName;

  const CloudinaryService(this.cloudName);

  String thumbnailUrl(String publicId, {int width = 400}) {
    return 'https://res.cloudinary.com/$cloudName/image/upload/w_$width,q_auto,f_auto/$publicId';
  }

  String optimizedUrl(String publicId) {
    return 'https://res.cloudinary.com/$cloudName/image/upload/q_auto,f_auto/$publicId';
  }
}
