import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_store.dart';

class IdeaToolsScreen extends StatefulWidget {
  const IdeaToolsScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<IdeaToolsScreen> createState() => _IdeaToolsScreenState();
}

class _IdeaToolsScreenState extends State<IdeaToolsScreen> {
  Memo? _selectedMemo;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  String _currentCategoryLabel = '汎用';
  List<String> _currentQuestions = [];
  String _generatedIdea = '';
  bool _saving = false;

  static const int _questionCount = 6;

  static const List<String> _defaultQuestions = [
    'これは誰のためのアイデア？',
    '一番の価値は何？',
    '今の案の弱いところは？',
    'もっと極端にするとどうなる？',
    '逆の発想にするとどうなる？',
    '収益化するとしたら、どう成り立つ？',
  ];

  static const _QuestionCategory _genericCategory = _QuestionCategory(
    label: '汎用',
    keywords: [],
    questions: _defaultQuestions,
  );

  static final List<_QuestionCategory> _categories = [
    _QuestionCategory(
      label: '就活',
      keywords: [
        '就活',
        '面接',
        'es',
        'エントリーシート',
        '志望動機',
        '自己pr',
        'ガクチカ',
        '企業研究',
        'インターン',
        '選考',
      ],
      questions: [
        'この就活メモで一番伝えたい強みは何？',
        'その強みを示す具体的な経験は？',
        '企業側はどこを評価しそう？',
        '逆に弱く見えそうな点はどこ？',
        '面接で聞かれそうな深掘り質問は？',
        '最終的に一言でどう売り込む？',
      ],
    ),
    _QuestionCategory(
      label: '動画案',
      keywords: [
        '動画',
        'youtube',
        'ショート',
        'shorts',
        'リール',
        'reels',
        'tiktok',
        'サムネ',
        '配信',
        'vlog',
        '編集',
        '投稿動画',
      ],
      questions: [
        'この動画は誰に見てもらいたい？',
        '最初の3秒で何を見せる？',
        '最後まで見たくなる理由は何？',
        '一番盛り上がる場面はどこ？',
        'タイトルやサムネにするとしたら何を押し出す？',
        '短くするなら何を残す？',
      ],
    ),
    _QuestionCategory(
      label: 'ビジネス案',
      keywords: [
        'ビジネス',
        '事業',
        '起業',
        '収益',
        '売上',
        '顧客',
        '市場',
        '課金',
        'マネタイズ',
        '利益',
        '単価',
        '事業案',
      ],
      questions: [
        'この案は誰のどんな課題を解決する？',
        '競合や代替手段と比べた強みは？',
        '最初の顧客は誰になりそう？',
        '継続して使ってもらう理由は何？',
        '収益はどう発生する？',
        '実際に始めるなら最初の一歩は何？',
      ],
    ),
    _QuestionCategory(
      label: 'アプリ案',
      keywords: [
        'アプリ',
        'サービス',
        '個人開発',
        'プロダクト',
        'ui',
        'ux',
        '機能案',
        'webサービス',
        'mvp',
        '画面',
        '通知',
        'ボタン',
        '設定画面',
        'ホーム画面',
        '実装',
        '機能',
        '改善案',
        'ユーザー体験',
      ],
      questions: [
        'これは誰のどんな悩みを解決する？',
        '今ある方法の不満は何？',
        'この案の一番強い価値は何？',
        '継続して使いたくなる理由は？',
        '最小機能で作るなら何を残す？',
        '収益化するならどこでお金を生む？',
      ],
    ),
    _QuestionCategory(
      label: 'ゲーム案',
      keywords: [
        'ゲーム',
        'ゲーム案',
        'ゲーム企画',
        'レベルデザイン',
        '対戦',
        'パズル',
        'rpg',
        'ステージ',
        'プレイヤー',
      ],
      questions: [
        'このゲームの一番楽しい瞬間は？',
        'プレイヤーは何を達成すると気持ちいい？',
        '繰り返し遊びたくなる理由は？',
        '最小構成で作るなら何を残す？',
        '他のゲームと何が違う？',
        '収益化するとしたらどうする？',
      ],
    ),
    _QuestionCategory(
      label: '物語・小説',
      keywords: [
        '小説',
        '物語',
        'ストーリー',
        '創作',
        '脚本',
        '台本',
        'シナリオ',
        'プロット',
      ],
      questions: [
        '主人公は何に悩んでいる？',
        '一番面白い対立は何？',
        '読者が驚くポイントは？',
        '感情が動く場面はどこ？',
        '今の案をもっと尖らせると？',
        '最後に何が変わる物語？',
      ],
    ),
    _QuestionCategory(
      label: '漫画',
      keywords: [
        '漫画',
        'マンガ',
        'コミック',
        'ネーム',
        'コマ割り',
        '1話',
      ],
      questions: [
        'この漫画の一番見せ場は？',
        '読者が続き読みたくなる要素は？',
        'キャラ同士の関係性で面白い点は？',
        '1話の最後に何を起こす？',
        '絵で映える場面はどこ？',
        '他作品と違う特徴は何？',
      ],
    ),
    _QuestionCategory(
      label: 'キャラクター設定',
      keywords: [
        'キャラ',
        'キャラクター',
        '人物設定',
        '主人公設定',
        '登場人物',
        '性格設定',
      ],
      questions: [
        'このキャラの一番大きな欲求は？',
        '何に弱く、何に強い？',
        '過去にどんな出来事があった？',
        '他キャラとの関係で面白い点は？',
        '見た目や口調の印象は？',
        'このキャラが物語をどう動かす？',
      ],
    ),
    _QuestionCategory(
      label: '世界観設定',
      keywords: [
        '世界観',
        '舞台設定',
        '歴史設定',
        '異世界',
        '王国',
        '魔法',
        '未来世界',
        'ファンタジー',
        'sf',
      ],
      questions: [
        'この世界の一番面白いルールは？',
        '現実と違う点は何？',
        'そこに住む人の当たり前は？',
        'この世界で起こる対立は何？',
        '主人公にどんな影響を与える？',
        '一言で説明するとどんな世界？',
      ],
    ),
    _QuestionCategory(
      label: 'ブログ・記事',
      keywords: [
        'ブログ',
        '記事',
        'note',
        'コラム',
        '文章',
        'エッセイ',
        '見出し',
      ],
      questions: [
        'この記事は誰向け？',
        '読者が一番知りたいことは？',
        '最初に結論として何を書く？',
        '具体例は何を入れる？',
        '読後にどんな行動をしてほしい？',
        'タイトルにするなら何を押し出す？',
      ],
    ),
    _QuestionCategory(
      label: 'SNS投稿',
      keywords: [
        'sns',
        '投稿',
        'x',
        'twitter',
        'instagram',
        'インスタ',
        'threads',
        'ポスト',
      ],
      questions: [
        'この投稿は誰に届けたい？',
        '最初の一文で何を言う？',
        '一番共感されそうな点は？',
        '保存やシェアしたくなる要素は？',
        '短くするなら何を残す？',
        '投稿後にどんな反応がほしい？',
      ],
    ),
    _QuestionCategory(
      label: '勉強・学習',
      keywords: [
        '勉強',
        '学習',
        '授業',
        '試験',
        'テスト',
        'レポート',
        '研究',
        '課題',
        '講義',
        '復習',
      ],
      questions: [
        'このメモで一番大事なポイントは？',
        'どこがまだ理解できていない？',
        '具体例で言うとどうなる？',
        'テストで問われるなら何が出そう？',
        '一言で説明すると？',
        '次に何を覚えるべき？',
      ],
    ),
    _QuestionCategory(
      label: 'プレゼン',
      keywords: [
        'プレゼン',
        '発表',
        'スライド',
        '登壇',
        '説明資料',
      ],
      questions: [
        '一番伝えたい結論は何？',
        '聞き手は何を知りたい？',
        'どの順番なら分かりやすい？',
        '印象に残る具体例は何？',
        '弱い部分や突っ込まれそうな点は？',
        '最後に何を持ち帰ってほしい？',
      ],
    ),
    _QuestionCategory(
      label: '会議メモ・業務改善',
      keywords: [
        '会議',
        '議事録',
        '業務改善',
        '改善案',
        '仕事',
        'タスク改善',
        '運用改善',
      ],
      questions: [
        '今一番の問題は何？',
        'その原因はどこにある？',
        '誰が一番困っている？',
        '小さく試せる改善は何？',
        '改善後にどう変わる？',
        '優先順位をつけるなら何から？',
      ],
    ),
    _QuestionCategory(
      label: '習慣化・目標',
      keywords: [
        '習慣',
        '習慣化',
        '目標',
        '継続',
        '朝活',
        '挑戦',
        'ルーティン',
      ],
      questions: [
        'この目標を達成したい理由は？',
        '続かなくなる原因は何？',
        '最小の行動にすると何をやる？',
        '毎日続ける工夫は何？',
        '達成をどう測る？',
        '途中で崩れたときどう立て直す？',
      ],
    ),
    _QuestionCategory(
      label: '悩み整理',
      keywords: [
        '悩み',
        '不安',
        '迷い',
        'モヤモヤ',
        '相談',
        '心配',
      ],
      questions: [
        '何に一番引っかかっている？',
        'それはいつ強く感じる？',
        '最悪の場合、何が起こると思っている？',
        '逆に今すでにできていることは？',
        '誰かに相談するとしたら何を聞く？',
        '今できる一番小さい一歩は？',
      ],
    ),
    _QuestionCategory(
      label: '旅行・外出計画',
      keywords: [
        '旅行',
        '観光',
        'おでかけ',
        '外出',
        'プラン',
        '旅',
        'ホテル',
        '移動',
      ],
      questions: [
        '今回の一番の目的は何？',
        '絶対に外せない場所や体験は？',
        '移動や時間の制約は何？',
        '食事や買い物で優先したいことは？',
        '雨や混雑のときの代替案は？',
        'このプランで一番楽しみな点は？',
      ],
    ),
    _QuestionCategory(
      label: '買い物・比較検討',
      keywords: [
        '買い物',
        '購入',
        '比較',
        '検討',
        '欲しいもの',
        '候補',
        'レビュー',
      ],
      questions: [
        '何のために必要？',
        '絶対に外せない条件は？',
        '妥協できる条件は？',
        '候補ごとの大きな違いは？',
        '買わない場合の問題は？',
        '最終判断の決め手は何？',
      ],
    ),
    _QuestionCategory(
      label: '問題解決',
      keywords: [
        '問題',
        '課題',
        '解決',
        'トラブル',
        '原因',
        '不具合',
        'エラー',
      ],
      questions: [
        '今起きている問題を一言で言うと？',
        '直接の原因は何？',
        '根本原因は何？',
        '影響を受けているのは誰？',
        'すぐできる応急対応は何？',
        '再発防止のために何を変える？',
      ],
    ),
    _QuestionCategory(
      label: 'ブレスト',
      keywords: [
        'ブレスト',
        '発散',
        '案出し',
        'アイデア出し',
      ],
      questions: [
        '量を出すなら、どんな方向がある？',
        '普通のやり方を崩すとどうなる？',
        '一番変な案は何？',
        '現実的にやるならどれ？',
        '一番面白い案はどれ？',
        '次に深掘りするなら何を選ぶ？',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      _questionCount,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      _questionCount,
      (_) => FocusNode(),
    );

    _currentCategoryLabel = _genericCategory.label;
    _currentQuestions = List<String>.from(_genericCategory.questions);

    if (widget.store.memos.isNotEmpty) {
      _selectedMemo = widget.store.memos.first;
      final matched = _matchCategory(_selectedMemo!);
      _currentCategoryLabel = matched.label;
      _currentQuestions = List<String>.from(matched.questions);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  _QuestionCategory _categoryByLabel(String label) {
    if (label == _genericCategory.label) return _genericCategory;
    return _categories.firstWhere(
      (category) => category.label == label,
      orElse: () => _genericCategory,
    );
  }

  _QuestionCategory _matchCategory(Memo memo) {
    final tags = memo.tags.map((e) => e.toLowerCase()).toList();
    final title = memo.title.toLowerCase();
    final body = memo.body.toLowerCase();
    final text = '$title $body';

    int scoreCategory(_QuestionCategory category) {
      int score = 0;

      for (final keyword in category.keywords) {
        final lowerKeyword = keyword.toLowerCase();

        if (tags.any((tag) => tag == lowerKeyword)) {
          score += 5;
        } else if (tags.any((tag) => tag.contains(lowerKeyword))) {
          score += 3;
        }

        if (title.contains(lowerKeyword)) {
          score += 3;
        }

        if (body.contains(lowerKeyword)) {
          score += 1;
        }
      }

      if (category.label == 'アプリ案') {
        if (text.contains('アプリ')) score += 2;
        if (text.contains('画面')) score += 1;
        if (text.contains('通知')) score += 1;
        if (text.contains('機能')) score += 1;
        if (text.contains('改善')) score += 1;
      }

      if (category.label == '世界観設定') {
        final strongWorldKeywords = [
          '世界観',
          '異世界',
          '王国',
          '魔法',
          'ファンタジー',
          '未来世界',
          '舞台設定',
        ];
        final matchedStrong = strongWorldKeywords.any((k) => text.contains(k));
        if (!matchedStrong) {
          score = 0;
        }
      }

      return score;
    }

    _QuestionCategory bestCategory = _genericCategory;
    int bestScore = 0;

    for (final category in _categories) {
      final score = scoreCategory(category);
      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    }

    return bestScore == 0 ? _genericCategory : bestCategory;
  }

  void _applyCategory(_QuestionCategory category, {bool clearAnswers = true}) {
    setState(() {
      _currentCategoryLabel = category.label;
      _currentQuestions = List<String>.from(category.questions);
      _generatedIdea = '';

      if (clearAnswers) {
        for (final controller in _controllers) {
          controller.clear();
        }
      }
    });
  }

  void _updateQuestionsForSelectedMemo({bool clearAnswers = true}) {
    final memo = _selectedMemo;
    final matched = memo == null ? _genericCategory : _matchCategory(memo);
    _applyCategory(matched, clearAnswers: clearAnswers);
  }

  void _onCategoryChanged(String? label) {
    if (label == null) return;
    final selectedCategory = _categoryByLabel(label);
    _applyCategory(selectedCategory, clearAnswers: true);
  }

  void _fillHintsFromMemo() {
    final memo = _selectedMemo;
    if (memo == null) return;

    final titleOrBody = memo.title.trim().isNotEmpty
        ? memo.title.trim()
        : memo.body.trim().split('\n').firstWhere(
              (e) => e.trim().isNotEmpty,
              orElse: () => '無題のアイデア',
            );

    final firstTag = memo.tags.isNotEmpty ? memo.tags.first : '';
    final allTags = memo.tags.isNotEmpty ? memo.tags.join(' / ') : 'タグなし';

    for (int i = 0; i < _currentQuestions.length; i++) {
      if (_controllers[i].text.trim().isNotEmpty) continue;

      final q = _currentQuestions[i];

      if (q.contains('誰')) {
        _controllers[i].text = firstTag.isNotEmpty ? '$firstTag に関心がある人' : '';
      } else if (q.contains('価値') || q.contains('大事') || q.contains('強み')) {
        _controllers[i].text = '$titleOrBody の体験をより良くすること';
      } else if (q.contains('弱') || q.contains('不満')) {
        _controllers[i].text = '現状では強みや対象がまだ曖昧';
      } else if (q.contains('極端') || q.contains('尖')) {
        _controllers[i].text = '特徴を1つに絞ってもっと際立たせる';
      } else if (q.contains('逆')) {
        _controllers[i].text = '足すのではなく減らす方向で考える';
      } else if (q.contains('収益')) {
        _controllers[i].text = '必要な人向けの有料機能や広告につなげる';
      } else if (q.contains('対立')) {
        _controllers[i].text = '理想と現実がぶつかる構図を作る';
      } else if (q.contains('驚')) {
        _controllers[i].text = '予想外の展開を1つ入れる';
      } else if (q.contains('感情')) {
        _controllers[i].text = '感情が大きく動く場面を作る';
      } else if (q.contains('理解')) {
        _controllers[i].text = '言葉は分かるが、自分の言葉で説明しきれない';
      } else if (q.contains('具体例')) {
        _controllers[i].text = '日常の場面に置き換えて考える';
      } else if (q.contains('面接')) {
        _controllers[i].text = 'なぜその行動をしたのかを深掘りされそう';
      } else if (q.contains('企業')) {
        _controllers[i].text = '主体性や再現性のある行動を評価されそう';
      } else if (q.contains('最初の3秒')) {
        _controllers[i].text = '結論や一番気になる場面を最初に出す';
      } else if (q.contains('最後まで')) {
        _controllers[i].text = '続きが気になる流れにする';
      } else if (q.contains('タイトル') || q.contains('サムネ')) {
        _controllers[i].text = '一番変化が大きい部分を押し出す';
      } else if (q.contains('顧客')) {
        _controllers[i].text = 'まず困りごとが強い少人数から始める';
      } else if (q.contains('一歩')) {
        _controllers[i].text = '最小の形で1回試して反応を見る';
      } else if (q.contains('主人公')) {
        _controllers[i].text = '強い願望と弱さを1つずつ持たせる';
      } else if (q.contains('見せ場')) {
        _controllers[i].text = '一番感情や状況が大きく動く場面';
      } else if (q.contains('読者')) {
        _controllers[i].text = '先が気になる疑問を残す';
      } else if (q.contains('ルール')) {
        _controllers[i].text = '現実とは違う当たり前を1つ明確にする';
      } else if (q.contains('結論')) {
        _controllers[i].text = '最初に一番伝えたいことを置く';
      } else if (q.contains('問題')) {
        _controllers[i].text = '何が起きていて何に困っているのかを整理する';
      } else if (q.contains('原因')) {
        _controllers[i].text = '表面ではなく根本の理由を探す';
      } else if (q.contains('続か')) {
        _controllers[i].text = '負担が大きすぎると続きにくい';
      } else if (q.contains('目的')) {
        _controllers[i].text = '何を得たいのかを先に決める';
      } else {
        _controllers[i].text = titleOrBody;
      }
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「$allTags」を参考に下書きを補いました'),
      ),
    );
  }

  void _clearAnswers() {
    for (final controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _generatedIdea = '';
    });
  }

  String _categorySpecificIdeaSection({
    required String categoryLabel,
    required List<String> answers,
  }) {
    final filled = answers.where((e) => e.isNotEmpty).toList();
    String pick(int index, String fallback) {
      if (index < filled.length) return filled[index];
      return fallback;
    }

    switch (categoryLabel) {
      case 'アプリ案':
        return '''
発展アイデア
・最初のターゲットは「${pick(0, '悩みが強い少人数')}」に絞る
・価値は「${pick(1, '不満の解消')}」に集中させる
・初期版では機能を絞り、「${pick(2, '最小機能')}」を中心に試す
・継続利用の理由を1つ明確にして、あとから機能を足す
''';
      case 'ビジネス案':
        return '''
発展アイデア
・まずは「${pick(0, '課題が強い顧客')}」に届く形へ具体化する
・競合との差は「${pick(1, '分かりやすい強み')}」として言語化する
・収益の流れは「${pick(2, '小さく始められる課金導線')}」を軸に組む
・最初の顧客検証を早く回して需要を確かめる
''';
      case '就活':
        return '''
発展アイデア
・一番伝える軸は「${pick(0, '強み')}」に絞る
・その強みを示す経験を1つ決め、数字や行動で補強する
・面接では「${pick(1, '深掘りされる点')}」への答えを先に準備する
・最後は一言で印象が残る自己PRにまとめる
''';
      case '動画案':
        return '''
発展アイデア
・最初の3秒で「${pick(0, '気になる場面')}」を見せる構成にする
・視聴維持のために「${pick(1, '続きが気になる要素')}」を早めに置く
・見どころは「${pick(2, '一番盛り上がる場面')}」に集中させる
・タイトルとサムネも同じ軸で揃えて、期待値を一致させる
''';
      case 'ゲーム案':
        return '''
発展アイデア
・一番楽しい瞬間を「${pick(0, '達成感')}」として先に決める
・その体験を最短で味わえる最小版を考える
・差別化要素は「${pick(1, '独自の遊び')}」に絞る
・繰り返し遊びたくなる理由を1つ強く作る
''';
      case '物語・小説':
        return '''
発展アイデア
・主人公の軸は「${pick(0, '悩みや願い')}」に置く
・対立は「${pick(1, '一番強い衝突')}」を中心に組み立てる
・読者を引っ張る要素として「${pick(2, '驚きや感情の動き')}」を前に出す
・終盤で最初と何が変わるかを明確にすると物語が締まる
''';
      case '漫画':
        return '''
発展アイデア
・1話のフックは「${pick(0, '一番見せたい場面')}」に集約する
・読者が続きを読みたくなる疑問を残す
・キャラ関係の面白さは「${pick(1, '関係性の衝突')}」として見せる
・絵で映える場面を1つ決めて印象を強くする
''';
      case 'キャラクター設定':
        return '''
発展アイデア
・このキャラの核は「${pick(0, '欲求')}」として定める
・弱さと強さを対にして魅力を作る
・過去や関係性を「${pick(1, '人物背景')}」として活用する
・物語や場面を動かす役割を明確にする
''';
      case '世界観設定':
        return '''
発展アイデア
・世界の核は「${pick(0, '面白いルール')}」として整理する
・現実との違いを1つ強く打ち出す
・住人にとっての当たり前を作ると世界が立つ
・対立や事件が自然に起こる構造を入れる
''';
      case 'ブログ・記事':
        return '''
発展アイデア
・読者像は「${pick(0, '具体的な読者')}」として決める
・最初に結論を出し、途中で「${pick(1, '具体例')}」を入れる
・最後は読者の次の行動につながる形で締める
・タイトルは一番知りたいことが伝わる形にする
''';
      case 'SNS投稿':
        return '''
発展アイデア
・最初の一文で「${pick(0, '一番刺さる要素')}」を見せる
・共感や保存につながる点を1つに絞る
・長い説明ではなく、印象の強い言葉でまとめる
・投稿後の反応として欲しいものを先に決める
''';
      case '勉強・学習':
        return '''
発展アイデア
・核となる理解は「${pick(0, '一番大事なポイント')}」に置く
・曖昧な部分は「${pick(1, '理解不足の点')}」として整理する
・具体例を使って自分の言葉で説明できる状態を目指す
・次に覚える範囲を決めて学習順をはっきりさせる
''';
      case 'プレゼン':
        return '''
発展アイデア
・最重要メッセージは「${pick(0, '結論')}」として固定する
・聞き手視点で順番を組み直す
・印象に残る具体例を1つ入れる
・最後に持ち帰ってほしい内容を明確に締める
''';
      case '会議メモ・業務改善':
        return '''
発展アイデア
・問題は「${pick(0, '今の課題')}」として一言で定義する
・原因と影響範囲を切り分ける
・まずは「${pick(1, '小さく試せる改善')}」から着手する
・改善後の変化を測れる形にしておく
''';
      case '習慣化・目標':
        return '''
発展アイデア
・目標の理由を「${pick(0, '続ける意味')}」として確認する
・最小行動に落とし込み、始めるハードルを下げる
・続かない原因を先に潰す
・達成の指標を1つ決めて進捗を見える化する
''';
      case '悩み整理':
        return '''
発展アイデア
・今の悩みの中心は「${pick(0, '一番引っかかる点')}」として整理する
・不安の正体を言葉にする
・今すでにできていることも拾い直す
・次の一歩を小さく決めて、考えすぎを止める
''';
      case '旅行・外出計画':
        return '''
発展アイデア
・目的は「${pick(0, '今回の主目的')}」としてはっきりさせる
・絶対に外せない体験を先に固定する
・制約と代替案を用意して崩れにくい計画にする
・最後に一番楽しみたい時間帯を中心に組み立てる
''';
      case '買い物・比較検討':
        return '''
発展アイデア
・判断軸は「${pick(0, '外せない条件')}」を最優先にする
・妥協点と絶対条件を分ける
・候補ごとの差を見える形で比べる
・最後は「${pick(1, '決め手')}」で決断する
''';
      case '問題解決':
        return '''
発展アイデア
・問題の定義は「${pick(0, '今起きていること')}」として明確にする
・直接原因と根本原因を分ける
・まずは応急対応、その後に再発防止を考える
・影響を受ける人を基準に優先順位を決める
''';
      case 'ブレスト':
        return '''
発展アイデア
・まず量を出し、その中から「${pick(0, '面白い方向')}」を残す
・変な案や極端な案も一度採用候補に置く
・現実的にやれる案と尖った案を分けて考える
・次に深掘りする案を1つ選んで具体化する
''';
      default:
        return '''
発展アイデア
・このメモは「${pick(0, '価値の明確化')}」を軸に育てる
・今の案をそのまま広げるのではなく、対象と強みを絞って方向性をはっきりさせる
・回答の中で出てきた要素を組み合わせて、より具体的な形に落とし込む
''';
    }
  }

  List<String> _categorySpecificNextActions({
    required String categoryLabel,
    required List<String> answers,
  }) {
    final filled = answers.where((e) => e.isNotEmpty).toList();
    String pick(int index, String fallback) {
      if (index < filled.length) return filled[index];
      return fallback;
    }

    switch (categoryLabel) {
      case 'アプリ案':
        return [
          '・対象ユーザーを1種類に絞る',
          '・初期版に入れる機能を3つ以内にする',
          '・「${pick(0, '一番強い価値')}」が伝わる画面を考える',
        ];
      case 'ビジネス案':
        return [
          '・最初の顧客候補を具体的に1種類決める',
          '・競合との違いを1文で言えるようにする',
          '・収益が発生する流れを図にする',
        ];
      case '就活':
        return [
          '・強みを示す具体エピソードを1つ完成させる',
          '・深掘り質問への答えを短くまとめる',
          '・最後に印象が残る一言を作る',
        ];
      case '動画案':
        return [
          '・最初の3秒の内容を決める',
          '・サムネとタイトルの方向性を1つに絞る',
          '・一番盛り上がる場面を中盤までに置く',
        ];
      case '物語・小説':
      case '漫画':
      case 'キャラクター設定':
      case '世界観設定':
        return [
          '・一番面白い軸を1つに絞る',
          '・読者が気になる疑問を1つ作る',
          '・最初と最後で何が変わるか決める',
        ];
      case '勉強・学習':
        return [
          '・一番大事なポイントを一言で言い直す',
          '・曖昧な部分を具体例で説明する',
          '・次に復習する範囲を決める',
        ];
      default:
        return [
          '・元メモの強みを1つに絞る',
          '・対象ユーザーを明確にする',
          '・次に試す小さな形を決める',
        ];
    }
  }

  void _generateIdea() {
    final memo = _selectedMemo;
    if (memo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先にメモを選択してください')),
      );
      return;
    }

    final answers = _controllers.map((e) => e.text.trim()).toList();
    final hasAnyAnswer = answers.any((e) => e.isNotEmpty);

    if (!hasAnyAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('少なくとも1つは回答を入れてください')),
      );
      return;
    }

    final title = memo.title.trim().isNotEmpty ? memo.title.trim() : '無題';
    final body = memo.body.trim().isNotEmpty ? memo.body.trim() : '本文なし';
    final tagsText = memo.tags.isEmpty ? 'タグなし' : memo.tags.join(' / ');

    final deepDive = List.generate(_currentQuestions.length, (i) {
      final answer = answers[i].isEmpty ? '未入力' : answers[i];
      return '${i + 1}. ${_currentQuestions[i]}\n$answer';
    }).join('\n\n');

    final ideaSection = _categorySpecificIdeaSection(
      categoryLabel: _currentCategoryLabel,
      answers: answers,
    );

    final nextActions = _categorySpecificNextActions(
      categoryLabel: _currentCategoryLabel,
      answers: answers,
    );

    final result = '''
元メモ
タイトル: $title
タグ: $tagsText
質問タイプ: $_currentCategoryLabel

元の内容
$body

深掘り結果
$deepDive

$ideaSection

次に詰めるべきこと
${nextActions.join('\n')}
''';

    setState(() {
      _generatedIdea = result;
    });
  }

  Future<void> _saveGeneratedIdea() async {
    final memo = _selectedMemo;
    if (memo == null || _generatedIdea.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先にアイデアを生成してください')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final now = DateTime.now();
    final newMemo = Memo(
      id: now.microsecondsSinceEpoch.toString(),
      title: '発展: ${memo.title.trim().isEmpty ? '無題' : memo.title.trim()}',
      body: _generatedIdea.trim(),
      tags: [
        ...memo.tags,
        '発展案',
        _currentCategoryLabel,
      ].toSet().toList(),
      createdAt: now,
      updatedAt: now,
    );

    try {
      await widget.store.addMemo(newMemo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('発展アイデアを新しいメモとして保存しました')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildSelectedMemoPreview(Memo memo) {
    final title = memo.title.trim().isNotEmpty ? memo.title.trim() : '無題';
    final preview = memo.body.trim().isNotEmpty ? memo.body.trim() : '本文なし';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              preview,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: memo.tags.isEmpty
                  ? const [Chip(label: Text('タグなし'))]
                  : memo.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${index + 1}. ${_currentQuestions[index]}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              minLines: 2,
              maxLines: 4,
              textInputAction: index == _currentQuestions.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              onSubmitted: (_) {
                if (index < _focusNodes.length - 1) {
                  _focusNodes[index + 1].requestFocus();
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'ここに入力',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _allCategoryLabels => [
        _genericCategory.label,
        ..._categories.map((e) => e.label),
      ];

  @override
  Widget build(BuildContext context) {
    final memos = widget.store.memos;

    return Scaffold(
      appBar: AppBar(title: const Text('アイデア拡張')),
      body: SafeArea(
        child: memos.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('メモがまだありません。先にメモを作成してください。'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '1. メモを選ぶ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Memo>(
                    value: memos.contains(_selectedMemo) ? _selectedMemo : null,
                    items: memos
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m.title.trim().isEmpty ? '無題' : m.title.trim(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      _selectedMemo = value;
                      _updateQuestionsForSelectedMemo(clearAnswers: true);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '元にするメモ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedMemo != null) _buildSelectedMemoPreview(_selectedMemo!),
                  const SizedBox(height: 20),
                  Text(
                    '2. 質問タイプを確認・変更する',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '自動判定されたカテゴリを、必要なら手動で変更できます。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _allCategoryLabels.contains(_currentCategoryLabel)
                        ? _currentCategoryLabel
                        : _genericCategory.label,
                    items: _allCategoryLabels
                        .map(
                          (label) => DropdownMenuItem<String>(
                            value: label,
                            child: Text(label),
                          ),
                        )
                        .toList(),
                    onChanged: _onCategoryChanged,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '質問タイプ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '3. 深掘り質問に答える',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _fillHintsFromMemo,
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('下書き補助'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(_currentCategoryLabel)),
                  const SizedBox(height: 12),
                  ...List.generate(_currentQuestions.length, _buildQuestionCard),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearAnswers,
                          child: const Text('入力をクリア'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _generateIdea,
                          child: const Text('4. アイデア生成'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '生成結果',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _generatedIdea.trim().isEmpty
                          ? const Text(
                              '回答を入れて「アイデア生成」を押すと、ここに発展案が表示されます。',
                            )
                          : SelectableText(_generatedIdea),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveGeneratedIdea,
                    icon: const Icon(Icons.save),
                    label: Text(_saving ? '保存中...' : '5. 新しいメモとして保存'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _QuestionCategory {
  const _QuestionCategory({
    required this.label,
    required this.keywords,
    required this.questions,
  });

  final String label;
  final List<String> keywords;
  final List<String> questions;
}