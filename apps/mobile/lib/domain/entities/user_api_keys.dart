class UserApiKeys {
  final String? claude;
  final String? openai;
  final String? gemini;
  final String? qwen;

  const UserApiKeys({this.claude, this.openai, this.gemini, this.qwen});

  factory UserApiKeys.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserApiKeys();
    return UserApiKeys(
      claude: map['claude'] as String?,
      openai: map['openai'] as String?,
      gemini: map['gemini'] as String?,
      qwen: map['qwen'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (claude != null) 'claude': claude,
      if (openai != null) 'openai': openai,
      if (gemini != null) 'gemini': gemini,
      if (qwen != null) 'qwen': qwen,
    };
  }

  String? forProvider(String provider) {
    switch (provider) {
      case 'claude':
        return claude;
      case 'openai':
        return openai;
      case 'gemini':
        return gemini;
      case 'qwen':
        return qwen;
      default:
        return null;
    }
  }
}
