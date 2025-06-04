class EvaluationModel {
  final String fen;
  final int depth;
  final int knodes;
  final List<PvModel> pvs;

  EvaluationModel({
    required this.fen,
    required this.depth,
    required this.knodes,
    required this.pvs,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      fen: json['fen'] as String,
      depth: json['depth'] as int,
      knodes: json['knodes'] as int,
      pvs: (json['pvs'] as List<dynamic>)
          .map((e) => PvModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fen': fen,
      'depth': depth,
      'knodes': knodes,
      'pvs': pvs.map((e) => e.toJson()).toList(),
    };
  }
}

class PvModel {
  final int cp;
  final String moves;

  PvModel({
    required this.cp,
    required this.moves,
  });

  factory PvModel.fromJson(Map<String, dynamic> json) {
    return PvModel(
      cp: json['cp'] as int,
      moves: json['moves'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cp': cp,
      'moves': moves,
    };
  }
}
