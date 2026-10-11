import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../agents/agents.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../theme/tokens.dart';
import 'chat_copy.dart';
import 'chat_response_view.dart';

class _ChatTurn {
  _ChatTurn(this.id, this.task)
    : fileNames = [
        for (final media in [task.audioMedia, task.visualMedia])
          if (media != null) media.fileName,
      ];
  final int id;
  OrchestratorTask task;
  final List<String> fileNames;
  OrchestratorResponse? response;
  bool retryAvailable = false;
  bool retried = false;

  void releaseSuccessfulMedia() {
    task = OrchestratorTask(
      userMessage: task.userMessage,
      contextAnalysis: task.contextAnalysis,
      languageTag: task.languageTag,
    );
  }
}

enum _ChatMenu { tools, settings, clear }

enum _Attachment { photo, audio }

class KernelChatScreen extends ConsumerStatefulWidget {
  const KernelChatScreen({super.key});
  @override
  ConsumerState<KernelChatScreen> createState() => _KernelChatScreenState();
}

class _KernelChatScreenState extends ConsumerState<KernelChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_ChatTurn>[];
  _ChatTurn? _retryTurn;
  Timer? _retryExpiry;
  late final MediaPickerService _picker;
  PickedMedia? _audio;
  PickedMedia? _photo;
  PestAnalysis? _contextAnalysis;
  bool _busy = false;
  bool _picking = false;
  String? _pickerError;
  int _nextId = 0;
  int _mediaEpoch = 0;

  bool get _canSend =>
      !_busy &&
      !_picking &&
      (_text.text.trim().isNotEmpty || _audio != null || _photo != null);

  @override
  void initState() {
    super.initState();
    _picker = ref.read(mediaPickerServiceProvider);
    _text.addListener(_draftChanged);
  }

  void _draftChanged() {
    if (mounted) setState(() {});
  }

  void _releaseTurn(_ChatTurn turn) {
    unawaited(_picker.release(turn.task.audioMedia));
    unawaited(_picker.release(turn.task.visualMedia));
    turn.retryAvailable = false;
    turn.releaseSuccessfulMedia();
  }

  void _releaseDraft() {
    unawaited(_picker.release(_audio));
    unawaited(_picker.release(_photo));
    _audio = null;
    _photo = null;
  }

  @override
  void dispose() {
    _retryExpiry?.cancel();
    for (final turn in _turns) {
      _releaseTurn(turn);
    }
    _releaseDraft();
    _turns.clear();
    _audio = null;
    _photo = null;
    _retryTurn = null;
    _text.removeListener(_draftChanged);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _nearBottom =>
      !_scroll.hasClients || _scroll.position.extentAfter < 120;

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pick(_Attachment kind) async {
    if (_busy || _picking) return;
    final epoch = _mediaEpoch;
    setState(() {
      _picking = true;
      _pickerError = null;
    });
    try {
      final media = kind == _Attachment.audio
          ? await _picker.pickAudioFile()
          : await _picker.pickImage();
      if (media == null) return;
      if (!mounted || epoch != _mediaEpoch) {
        await _picker.release(media);
        return;
      }
      final previous = kind == _Attachment.audio ? _audio : _photo;
      if (!identical(previous, media)) unawaited(_picker.release(previous));
      setState(() {
        if (kind == _Attachment.audio) {
          _audio = media;
        } else {
          _photo = media;
        }
      });
    } on Object {
      if (mounted && epoch == _mediaEpoch) {
        setState(() => _pickerError = ChatCopy.pickerError);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit({_ChatTurn? retry}) async {
    if (!mounted ||
        _busy ||
        _picking ||
        (retry == null && !_canSend) ||
        (retry != null && !retry.retryAvailable)) {
      return;
    }
    final turn =
        retry ??
        _ChatTurn(
          _nextId++,
          OrchestratorTask(
            userMessage: _text.text.trim(),
            audioMedia: _audio,
            visualMedia: _photo,
            contextAnalysis: _audio == null && _photo == null
                ? _contextAnalysis
                : null,
            languageTag: Localizations.localeOf(context).languageCode,
          ),
        );
    _retryExpiry?.cancel();
    setState(() {
      _busy = true;
      if (retry != null) {
        turn.retried = true;
        turn.retryAvailable = false;
      }
      _pickerError = null;
      turn.response = null;
      if (retry == null) {
        if (_retryTurn != null) _releaseTurn(_retryTurn!);
        _retryTurn = null;
        _turns.add(turn);
        _audio = null;
        _photo = null;
      }
    });
    if (retry == null) _text.clear();
    _scrollDown();
    OrchestratorResponse response;
    try {
      response = await ref.read(orchestratorAgentProvider).execute(turn.task);
    } on Object {
      response = const OrchestratorResponse(
        notices: {ChatNotice.requestFailed},
        retryable: true,
      );
    }
    if (!mounted) {
      _releaseTurn(turn);
      return;
    }
    final follow = _nearBottom;
    setState(() {
      turn.response = response;
      _busy = false;
      _contextAnalysis =
          (turn.task.visualMedia != null || turn.task.audioMedia != null)
          ? response.analysis
          : response.analysis ?? _contextAnalysis;
      // One explicit retry, at most five minutes, in memory/private cache.
      // Completed turns retain display names/results, not raw media.
      final mediaBytes =
          (turn.task.audioMedia?.bytes.length ?? 0) +
          (turn.task.visualMedia?.bytes.length ?? 0);
      turn.retryAvailable =
          response.retryable && !turn.retried && mediaBytes <= 24 * 1024 * 1024;
      _retryTurn = turn.retryAvailable ? turn : null;
      if (!turn.retryAvailable) {
        _releaseTurn(turn);
      } else {
        _retryExpiry = Timer(const Duration(minutes: 5), () {
          if (!mounted || _busy || _retryTurn != turn) return;
          setState(() {
            _releaseTurn(turn);
            _retryTurn = null;
          });
        });
      }
    });
    if (follow) _scrollDown();
  }

  Future<void> _clear() async {
    if (_busy || _turns.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(ChatCopy.clear),
        content: const Text(ChatCopy.clearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(ChatCopy.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(ChatCopy.clear),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _mediaEpoch++;
    _retryExpiry?.cancel();
    setState(() {
      for (final turn in _turns) {
        _releaseTurn(turn);
      }
      _releaseDraft();
      _pickerError = null;
      _text.clear();
      _turns.clear();
      _retryTurn = null;
      _contextAnalysis = null;
    });
  }

  Widget _attachment(PickedMedia media, VoidCallback remove) => Container(
    constraints: const BoxConstraints(maxWidth: 260),
    margin: const EdgeInsets.only(right: 8, bottom: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Tooltip(
            message: media.fileName,
            child: Text(
              media.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          tooltip: '${ChatCopy.remove} ${media.fileName}',
          onPressed: _busy || _picking ? null : remove,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );

  Widget _userTurn(_ChatTurn turn) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KernelColors.sage,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (turn.task.userMessage.isNotEmpty)
            SelectableText(turn.task.userMessage),
          for (final name in turn.fileNames)
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        titleSpacing: 0,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(child: Text(ChatCopy.title)),
                  PopupMenuButton<_ChatMenu>(
                    tooltip: ChatCopy.menu,
                    onSelected: (action) {
                      switch (action) {
                        case _ChatMenu.tools:
                          context.push(Routes.home);
                        case _ChatMenu.settings:
                          context.push(Routes.settings);
                        case _ChatMenu.clear:
                          _clear();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _ChatMenu.tools,
                        child: Text(ChatCopy.tools),
                      ),
                      const PopupMenuItem(
                        value: _ChatMenu.settings,
                        child: Text(ChatCopy.settings),
                      ),
                      if (_turns.isNotEmpty)
                        PopupMenuItem(
                          value: _ChatMenu.clear,
                          enabled: !_busy,
                          child: const Text(ChatCopy.clear),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: LayoutBuilder(
              builder: (context, viewport) => Column(
                children: [
                  Expanded(
                    child: ListView(
                      key: const Key('chat-transcript'),
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        if (_turns.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ChatCopy.emptyTitle,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  ChatCopy.emptyBody,
                                  style: TextStyle(fontSize: 16, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        for (final turn in _turns)
                          Column(
                            key: ValueKey('turn-${turn.id}'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _userTurn(turn),
                              if (turn.response != null) ...[
                                ChatResponseView(response: turn.response!),
                                if (turn.response!.retryable &&
                                    !turn.retryAvailable)
                                  const Text(ChatCopy.retryExpired),
                                if (turn.retryAvailable)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _submit(retry: turn),
                                      child: const Text(ChatCopy.retry),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (_busy)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Semantics(
                        liveRegion: true,
                        child: const Text(ChatCopy.working),
                      ),
                    ),
                  if (_pickerError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _pickerError!,
                          style: const TextStyle(color: KernelColors.danger),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: KernelColors.paper,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KernelColors.outline),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_audio != null || _photo != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                              child: Wrap(
                                children: [
                                  if (_audio != null)
                                    _attachment(
                                      _audio!,
                                      () => setState(() {
                                        unawaited(_picker.release(_audio));
                                        _audio = null;
                                      }),
                                    ),
                                  if (_photo != null)
                                    _attachment(
                                      _photo!,
                                      () => setState(() {
                                        unawaited(_picker.release(_photo));
                                        _photo = null;
                                      }),
                                    ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                PopupMenuButton<_Attachment>(
                                  key: const Key('chat-attach'),
                                  tooltip: ChatCopy.attach,
                                  enabled: !_busy && !_picking,
                                  icon: const Icon(Icons.add),
                                  onSelected: _pick,
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: _Attachment.photo,
                                      child: Text(ChatCopy.photo),
                                    ),
                                    PopupMenuItem(
                                      value: _Attachment.audio,
                                      child: Text(ChatCopy.audio),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: viewport.maxHeight * 0.35,
                                    ),
                                    child: TextField(
                                      key: const Key('chat-input'),
                                      controller: _text,
                                      minLines: 1,
                                      maxLines: 5,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: ChatCopy.hint,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton.filled(
                                  key: const Key('chat-send'),
                                  tooltip: ChatCopy.send,
                                  onPressed: _canSend ? () => _submit() : null,
                                  icon: const Icon(Icons.arrow_upward_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
