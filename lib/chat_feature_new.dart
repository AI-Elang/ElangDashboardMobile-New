import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'dart:convert';

part 'chat_feature_new.g.dart';

// --- Enums ---
@HiveType(typeId: 2)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  loading,
}

@HiveType(typeId: 3)
enum AiFlow {
  @HiveField(0)
  none,
  @HiveField(1)
  defaultChat, // Model lama (Flowise)
  @HiveField(2)
  gemma3_27b_it, // google/gemma-3-27b-it:free
  @HiveField(3)
  qwen3_235b_a22b, // qwen/qwen3-235b-a22b:free
}

// Helper untuk nama Flow dan URL API serta KEY API
var baseURLAI = dotenv.env['baseURLAI'];
var openRouterAPI = dotenv.env['openRouterAPI'];

final Map<AiFlow, ModelInfo> aiModelDetails = {
  AiFlow.defaultChat: ModelInfo(
    id: "flowise_default_model", // ID placeholder, karena API-nya beda
    displayName: "Default Chat (1000 limit)",
    flow: AiFlow.defaultChat,
    dailyLimit: 1000,
  ),
  AiFlow.gemma3_27b_it: ModelInfo(
    id: "google/gemma-3-27b-it:free",
    displayName: "Gemma3 27B",
    flow: AiFlow.gemma3_27b_it,
    dailyLimit: 7,
    hasThinkingMode: false, // Gemma TIDAK memiliki output 'reasoning'
    isHybridThinking: false,
  ),
  AiFlow.qwen3_235b_a22b: ModelInfo(
    id: "qwen/qwen3-235b-a22b:free",
    displayName: "Qwen3 235B",
    flow: AiFlow.qwen3_235b_a22b,
    dailyLimit: 7,
    hasThinkingMode: true,
    isHybridThinking: true, // Qwen bisa di-toggle thinkingnya
  ),
};

String getFlowName(AiFlow flow) {
  return aiModelDetails[flow]?.displayName ?? "Unknown Model";
}

String? getApiUrlForFlow(AiFlow flow) {
  switch (flow) {
    case AiFlow.defaultChat:
      return "$baseURLAI/api/v1/prediction/857539b8-6b33-4607-859b-68bb28935c39";
    case AiFlow.gemma3_27b_it:
    case AiFlow.qwen3_235b_a22b:
      return "https://openrouter.ai/api/v1/chat/completions"; // URL OpenRouter
    default:
      return null;
  }
}

String? getModelIdentifier(AiFlow flow) {
  return aiModelDetails[flow]?.id;
}

// --- Models ---
@HiveType(typeId: 0) // typeId unik untuk class ini
class ChatMessage extends HiveObject {
  // Extend HiveObject jika butuh fitur Hive lebih lanjut (opsional)
  @HiveField(0) // index unik untuk field ini
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final bool isSentByUser;

  @HiveField(3)
  final DateTime timestamp;

  // MessageType tidak perlu @HiveField karena kita tidak akan simpan 'loading'
  // Jika mau disimpan juga, tambahkan @HiveField(4) dan typeId di enum
  final MessageType
      type; // Tidak disimpan ke Hive, karena 'loading' itu state sementara

  // Untuk memisahkan thinking dan content saat rendering, jika ada
  // Tidak disimpan di Hive, tapi bisa di-parse dari 'text'
  String? get thinkingPart {
    if (text.startsWith("Thinking:\n") &&
        text.contains("\n----------------------\n")) {
      return text
          .split("\n----------------------\n")[0]
          .substring("Thinking:\n".length)
          .trim();
    }
    return null;
  }

  String get contentPart {
    if (text.startsWith("Thinking:\n") &&
        text.contains("\n----------------------\n")) {
      final parts = text.split("\n----------------------\n");
      return parts.length > 1
          ? parts[1].trim()
          : text; // Fallback jika format salah
    }
    return text;
  }

  ChatMessage({
    required this.id,
    required this.isSentByUser,
    required this.timestamp,
    this.text = "",
    this.type = MessageType.text,
  });
}

@HiveType(typeId: 1) // typeId unik untuk class ini
class ChatHistoryItem extends HiveObject {
  // Extend HiveObject
  @HiveField(0)
  String id; // This is the conversation ID

  @HiveField(1)
  String contactName;

  @HiveField(2)
  String lastMessage;

  @HiveField(3)
  DateTime lastMessageTime;

  @HiveField(4)
  // Hive bisa simpan List<ChatMessage> jika ChatMessage juga HiveType
  List<ChatMessage> messages;

  @HiveField(5)
  AiFlow aiFlow;

  @HiveField(6) // New field for session ID
  String sessionId;

  @HiveField(7) // Field baru
  bool
      isThinkingModeExplicitlyEnabled; // Untuk Qwen, status dari user (/think atau toggle)

  ChatHistoryItem({
    required this.id,
    required this.contactName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.messages = const [],
    this.aiFlow = AiFlow.none,
    required this.sessionId,
    this.isThinkingModeExplicitlyEnabled = false, // Default false
  });
}

// --- Custom Page Transition for Chat Detail ---
// Animasi masuk yang sleek: Fade + Slide Up
Route createChatDetailRoute({
  required String chatId,
  required String contactName,
  required bool isNewChat,
  required ChatController chatController,
  AiFlow selectedFlow = AiFlow.none,
  required String sessionId,
  String? initialMessage, // Add this parameter
}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => ChatDetailPage(
      chatId: chatId,
      contactName: contactName,
      isNewChat: isNewChat,
      chatController: chatController,
      selectedFlow: selectedFlow,
      sessionId: sessionId,
      initialMessage: initialMessage, // Pass it to ChatDetailPage
    ),
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
      ));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

// --- Arguments untuk Chat Detail Page ---
class ChatDetailArguments {
  final String chatId;
  final String contactName;
  final bool isNewChat;
  final ChatController chatController;
  final AiFlow selectedFlow;
  final String sessionId;
  final String? initialMessage;

  ChatDetailArguments({
    required this.chatId,
    required this.contactName,
    required this.isNewChat,
    required this.chatController,
    required this.selectedFlow,
    required this.sessionId,
    this.initialMessage,
  });
}

// --- Model Info untuk API Calls ---
class ModelInfo {
  final String id; // ID untuk API call (e.g., "google/gemma-3-27b-it:free")
  final String displayName;
  final AiFlow flow;
  final int dailyLimit;
  final bool hasThinkingMode;
  final bool
      isHybridThinking; // True jika model bisa on/off thinking via prompt

  ModelInfo({
    required this.id,
    required this.displayName,
    required this.flow,
    required this.dailyLimit,
    this.hasThinkingMode = false,
    this.isHybridThinking = false,
  });
}

// --- State Management Helper ---
class ChatController extends ChangeNotifier {
  final ChatPersistenceService _persistenceService; // Inject service

  List<ChatHistoryItem> _chatHistory = []; // Tetap pakai list in-memory
  List<ChatHistoryItem> get chatHistory => _chatHistory;

  final Map<AiFlow, int> _modelUsageCount = {};
  final Map<AiFlow, DateTime> _modelLastUsageDate = {};
  final Map<AiFlow, bool> _modelLimitReachedState = {};

  // Key: chatId, Value: bool (apakah thinking mode aktif untuk Qwen di chat itu)
  final Map<String, bool> _qwenChatThinkingMode = {};
  Map<AiFlow, bool> get modelLimitReachedState => _modelLimitReachedState;

  ChatController(this._persistenceService); // Terima service via constructor

  bool getAreAllModelsLimited() {
    if (_modelLimitReachedState.isEmpty && aiModelDetails.isNotEmpty) {
      // Jika state belum diinisialisasi, anggap belum ada yang limit (akan di-load)
      // Kecuali jika memang tidak ada model sama sekali (aiModelDetails kosong)
      return false;
    }
    return aiModelDetails.keys
        .where(
            (flow) => flow != AiFlow.none) // Hanya cek model yang bisa dipilih
        .every((flow) => _modelLimitReachedState[flow] ?? false);
  }

  // Fungsi baru untuk load data awal
  Future<void> loadInitialData() async {
    await _persistenceService.resetAllModelUsageIfNecessary();
    _chatHistory = await _persistenceService.loadChatHistory();

    for (var flow in AiFlow.values) {
      if (flow == AiFlow.none) continue;
      final usage = await _persistenceService.getModelUsage(flow);
      _modelUsageCount[flow] = usage['count'] as int? ?? 0;
      _modelLastUsageDate[flow] = usage['date'] != null
          ? DateTime.parse(usage['date'] as String)
          : DateTime.now();
      _updateLimitStatusForFlow(flow);

      // Load thinking mode state untuk Qwen dari history
      for (var item in _chatHistory) {
        if (item.aiFlow == AiFlow.qwen3_235b_a22b) {
          _qwenChatThinkingMode[item.id] = item.isThinkingModeExplicitlyEnabled;
        }
      }
    }
    notifyListeners();
    print(
        "ChatController: Initial data loaded. History: ${_chatHistory.length}. Usage data processed.");
  }

  Future<void> incrementModelUsage(AiFlow flow) async {
    if (flow == AiFlow.none || (aiModelDetails[flow]?.dailyLimit ?? 0) == 0) {
      return; // Jangan increment jika tidak ada limit
    }

    final now = DateTime.now();
    int currentCount = _modelUsageCount[flow] ?? 0;
    DateTime lastDate = _modelLastUsageDate[flow] ??
        now.subtract(const Duration(days: 1)); // Anggap kemarin jika null

    // Cek reset harian (jam 5 pagi)
    const resetHour = 5;
    DateTime lastResetPointForToday =
        DateTime(now.year, now.month, now.day, resetHour);

    if (now.isAfter(lastResetPointForToday) &&
        lastDate.isBefore(lastResetPointForToday)) {
      // Jika penggunaan terakhir sebelum jam 5 hari ini, dan sekarang sudah lewat jam 5 hari ini
      currentCount = 0;
    } else if (lastDate.day != now.day ||
        lastDate.month != now.month ||
        lastDate.year != now.year) {
      // Jika beda hari (dan belum dihandle oleh kondisi di atas, misal penggunaan kemarin setelah jam 5)
      // Dan sekarang sudah lewat jam 5 pagi HARI INI
      if (now.isAfter(lastResetPointForToday)) {
        currentCount = 0;
      } else {
        // Beda hari, tapi sekarang BELUM jam 5 pagi.
        // Jika lastDate juga sebelum jam 5 paginya, count sudah benar (dari hari kemarin).
        // Jika lastDate setelah jam 5 paginya, maka count adalah dari hari kemarin.
        // Ini seharusnya sudah dihandle oleh resetAllModelUsageIfNecessary.
        // Untuk safety, jika beda hari absolut, dan belum jam 5, maka count direset untuk hari baru ini.
        if (lastDate.isBefore(now.copyWith(
            hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0))) {
          currentCount = 0;
        }
      }
    }

    currentCount++;
    _modelUsageCount[flow] = currentCount;
    _modelLastUsageDate[flow] = now;
    await _persistenceService.saveModelUsage(flow, currentCount, now);
    _updateLimitStatusForFlow(flow);

    notifyListeners();

    print(
        "ChatController: Usage incremented for $flow. Count: $currentCount. Limit reached: ${_modelLimitReachedState[flow]}");
  }

  // Service untuk save
  Future<void> addOrUpdateChatHistory(ChatHistoryItem item) async {
    final index = _chatHistory.indexWhere((h) => h.id == item.id);
    if (index != -1) {
      _chatHistory[index] = item;
    } else {
      _chatHistory.insert(0, item);
    }
    _chatHistory.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    await _persistenceService.saveChatHistoryItem(item);
    notifyListeners();
  }

  // Service untuk delete
  Future<void> removeChatHistory(String id) async {
    _chatHistory.removeWhere((item) => item.id == id);
    await _persistenceService.deleteChatHistoryItem(id);
    _qwenChatThinkingMode.remove(id); // Hapus juga state thinking mode
    notifyListeners();
  }

  // getChatById tetap sama (bekerja dengan list in-memory)
  ChatHistoryItem? getChatById(String id) {
    try {
      return _chatHistory.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  // (Opsional) Method untuk clear semua history
  Future<void> clearAllHistory() async {
    await _persistenceService.clearAllHistory(); // Hapus dari Hive dulu
    _chatHistory.clear();
    _qwenChatThinkingMode.clear();
    // Reset usage count juga? Tergantung kebutuhan. Untuk sekarang tidak.
    notifyListeners();
  }

  void _updateLimitStatusForFlow(AiFlow flow) {
    final modelDetail = aiModelDetails[flow];
    if (modelDetail == null) {
      _modelLimitReachedState[flow] =
          false; // Anggap tidak limit jika tidak ada detail
      return;
    }
    final limit = modelDetail.dailyLimit;
    final currentCount = _modelUsageCount[flow] ?? 0;
    _modelLimitReachedState[flow] = currentCount >= limit;
  }

  // Helper untuk memastikan data penggunaan (count, date, limit status) up-to-date sebelum diakses
  void _ensureUsageDataIsCurrent(AiFlow flow) {
    if (flow == AiFlow.none) return;

    final now = DateTime.now();
    final lastDate = _modelLastUsageDate[flow];
    final modelDetail = aiModelDetails[flow];
    if (modelDetail == null || lastDate == null) {
      return; // Tidak bisa proses jika tidak ada data
    }

    const resetHour = 5;
    DateTime resetPointForToday =
        DateTime(now.year, now.month, now.day, resetHour);

    bool needsReset = false;
    // 1. Jika tanggal terakhir adalah hari kemarin atau lebih lama, DAN sekarang sudah jam 5 pagi atau lebih
    if ((lastDate.year < now.year ||
            lastDate.month < now.month ||
            lastDate.day < now.day) &&
        now.isAfter(resetPointForToday)) {
      needsReset = true;
    }
    // 2. Jika tanggal terakhir adalah hari ini TAPI sebelum jam 5 pagi, DAN sekarang sudah jam 5 pagi atau lebih
    else if (lastDate.day == now.day &&
        lastDate.month == now.month &&
        lastDate.year == now.year &&
        lastDate.isBefore(resetPointForToday) &&
        now.isAfter(resetPointForToday)) {
      needsReset = true;
    }

    if (needsReset) {
      print(
          "ChatController._ensureUsageDataIsCurrent: Resetting usage for $flow on the fly.");
      _modelUsageCount[flow] = 0;
      // _modelLastUsageDate[flow] = now; // Tanggal akan diupdate saat saveModelUsage jika ada increment
      _persistenceService.saveModelUsage(
          flow, 0, now); // Simpan reset ke persistence
      _updateLimitStatusForFlow(flow); // Update status limit
      // Tidak perlu notifyListeners() di sini karena ini helper internal, pemanggil yang akan notify jika perlu.
    }
  }

  int getModelUsageCount(AiFlow flow) {
    // Panggil _ensureUsageDataIsCurrent sebelum return untuk memastikan data ter-update
    _ensureUsageDataIsCurrent(flow);
    return _modelUsageCount[flow] ?? 0;
  }

  bool isModelLimitReached(AiFlow flow) {
    _ensureUsageDataIsCurrent(flow); // Pastikan status limit up-to-date
    return _modelLimitReachedState[flow] ?? false;
  }

  // Untuk Qwen Thinking Mode
  bool isQwenThinkingModeActive(String chatId) {
    return _qwenChatThinkingMode[chatId] ?? false;
  }

  void setQwenThinkingMode(String chatId, bool isActive) {
    _qwenChatThinkingMode[chatId] = isActive;
    // Update juga di ChatHistoryItem agar persisten
    final chatItem = getChatById(chatId);
    if (chatItem != null && chatItem.aiFlow == AiFlow.qwen3_235b_a22b) {
      chatItem.isThinkingModeExplicitlyEnabled = isActive;
      // Tidak perlu save explisit ke history di sini, akan tersimpan saat _updateHistory
      // atau saat navigasi jika ada perubahan.
      // Untuk memastikan persisten, bisa panggil:
      // addOrUpdateChatHistory(chatItem); // Ini akan save
    }
    notifyListeners();
    print("ChatController: Qwen thinking mode for $chatId set to $isActive");
  }
}

// --- Buat Kelas Persistence Service ---
class ChatPersistenceService {
  static const String _historyBoxName = 'chatHistoryBox';
  static const String _usageBoxName =
      'aiModelUsageBox'; // Box untuk data penggunaan model

  // Fungsi untuk mendapatkan box history
  Future<Box<ChatHistoryItem>> _getHistoryBox() async {
    if (!Hive.isBoxOpen(_historyBoxName)) {
      return await Hive.openBox<ChatHistoryItem>(_historyBoxName);
    }
    return Hive.box<ChatHistoryItem>(_historyBoxName);
  }

  Future<Box> _getUsageBox() async {
    if (!Hive.isBoxOpen(_usageBoxName)) {
      return await Hive.openBox(_usageBoxName);
    }
    return Hive.box(_usageBoxName);
  }

  // Load semua history dari Hive
  Future<List<ChatHistoryItem>> loadChatHistory() async {
    final box = await _getHistoryBox();
    final history = box.values.toList();
    history.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    print("ChatPersistenceService: Loaded ${history.length} items from Hive.");
    return history;
  }

  // Simpan atau update satu item history
  Future<void> saveChatHistoryItem(ChatHistoryItem item) async {
    item.messages =
        item.messages.where((m) => m.type != MessageType.loading).toList();
    final box = await _getHistoryBox();
    await box.put(item.id, item);
    print(
        "ChatPersistenceService: Saved/Updated item with id: ${item.id} to Hive.");
  }

  // Hapus satu item history berdasarkan ID
  Future<void> deleteChatHistoryItem(String id) async {
    final box = await _getHistoryBox();
    await box.delete(id);
    print("ChatPersistenceService: Deleted item with id: $id from Hive.");
  }

  // (Opsional) Hapus semua history
  Future<void> clearAllHistory() async {
    final box = await _getHistoryBox();
    await box.clear();
    print("ChatPersistenceService: Cleared all chat history from Hive.");
  }

  // --- Fungsi untuk Model Usage ---
  Future<Map<String, dynamic>> getModelUsage(AiFlow flow) async {
    final box = await _getUsageBox();
    final modelKey = aiModelDetails[flow]?.id ?? flow.toString();
    final usageData = box.get(modelKey)
        as Map<dynamic, dynamic>?; // Hive menyimpan Map<dynamic, dynamic>

    if (usageData == null) {
      return {
        'count': 0,
        'date':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String()
      }; // Default ke kemarin agar reset terpicu
    }
    return Map<String, dynamic>.from(usageData);
  }

  Future<void> saveModelUsage(AiFlow flow, int count, DateTime date) async {
    final box = await _getUsageBox();
    final modelKey = aiModelDetails[flow]?.id ?? flow.toString();
    await box.put(modelKey, {'count': count, 'date': date.toIso8601String()});
    print(
        "ChatPersistenceService: Saved usage for $modelKey. Count: $count, Date: ${date.toIso8601String()}");
  }

  Future<void> resetAllModelUsageIfNecessary() async {
    final box = await _getUsageBox();
    final now = DateTime.now();
    const resetHour = 5; // Jam 5 pagi

    for (var flow in AiFlow.values) {
      if (flow == AiFlow.none) continue;

      final modelKey = aiModelDetails[flow]?.id ?? flow.toString();
      final usageDataDynamic = box.get(modelKey) as Map<dynamic, dynamic>?;
      DateTime lastUsageDate;
      int currentCount = 0;

      if (usageDataDynamic != null) {
        final usageData = Map<String, dynamic>.from(usageDataDynamic);
        lastUsageDate = DateTime.parse(usageData['date'] as String);
        currentCount = usageData['count'] as int;
      } else {
        // Jika tidak ada data, anggap penggunaan terakhir adalah kemarin agar reset terjadi
        lastUsageDate = now.subtract(const Duration(days: 1));
      }

      // Tentukan titik reset untuk tanggal penggunaan terakhir dan untuk hari ini
      DateTime resetPointForToday =
          DateTime(now.year, now.month, now.day, resetHour);

      bool needsReset = false;

      // Kondisi 1: Penggunaan terakhir adalah hari kemarin (atau lebih lama), dan sekarang sudah lewat jam 5 pagi hari ini.
      if (lastUsageDate.isBefore(now.copyWith(
              hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0)) &&
          now.isAfter(resetPointForToday)) {
        needsReset = true;
      }
      // Kondisi 2: Penggunaan terakhir adalah hari ini, TAPI sebelum jam 5 pagi, dan sekarang sudah jam 5 pagi atau lebih.
      else if (lastUsageDate.day == now.day &&
          lastUsageDate.month == now.month &&
          lastUsageDate.year == now.year &&
          lastUsageDate.isBefore(resetPointForToday) &&
          (now.isAfter(resetPointForToday) ||
              now.isAtSameMomentAs(resetPointForToday))) {
        needsReset = true;
      }

      if (needsReset) {
        print(
            "ChatPersistenceService: Resetting usage for $modelKey. Last used: $lastUsageDate. Now: $now");
        await box.put(modelKey, {'count': 0, 'date': now.toIso8601String()});
      } else if (usageDataDynamic == null) {
        // Jika belum ada data sama sekali, inisialisasi dengan count 0 dan tanggal sekarang
        await box.put(modelKey, {'count': 0, 'date': now.toIso8601String()});
        print("ChatPersistenceService: Initialized usage for $modelKey.");
      }
    }
    print(
        "ChatPersistenceService: Checked and performed model usage reset if necessary.");
  }

  // Tutup box saat tidak dibutuhkan (misal saat app ditutup total)
  Future<void> closeHiveBoxes() async {
    if (Hive.isBoxOpen(_historyBoxName)) {
      await Hive.box(_historyBoxName).close();
      print("ChatPersistenceService: Hive box '$_historyBoxName' closed.");
    }
    if (Hive.isBoxOpen(_usageBoxName)) {
      await Hive.box(_usageBoxName).close();
      print("ChatPersistenceService: Hive box '$_usageBoxName' closed.");
    }
  }
}

// --- Chat History List Widget (untuk di dalam Drawer) ---
class _ChatHistoryListWidget extends StatefulWidget {
  final ChatController chatController;

  const _ChatHistoryListWidget({required this.chatController});

  @override
  State<_ChatHistoryListWidget> createState() => _ChatHistoryListWidgetState();
}

// State untuk _ChatHistoryListWidget
class _ChatHistoryListWidgetState extends State<_ChatHistoryListWidget> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatHistoryItem> _filteredHistory = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Ambil data awal dari controller (sekarang mungkin kosong)
    _filterHistory(); // Filter data awal (mungkin kosong)
    widget.chatController.addListener(_updateList);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.chatController.removeListener(_updateList);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateList() {
    // Dipanggil oleh controller, filter ulang dan update list
    // Note: Mengelola AnimatedList state dengan filter bisa kompleks.
    // Jika ada isu, alternatifnya bisa pakai ListView.builder biasa
    // atau state management yang lebih canggih.
    final oldLength = _filteredHistory.length;
    _filterHistory();
    final newLength = _filteredHistory.length;

    // Heuristik sederhana untuk update AnimatedList (mungkin perlu disempurnakan)
    if (_listKey.currentState != null) {
      // Jika panjang berubah drastis (misal search/clear), rebuild saja
      if ((oldLength - newLength).abs() > 5 ||
          oldLength == 0 ||
          newLength == 0) {
        setState(() {}); // Force rebuild (pakai listview biasa lebih aman)
        // atau logic remove/insert yg lebih kompleks
      } else {
        // Coba update item jika hanya konten berubah
        // Ini butuh logic diffing yg lebih canggih
        setState(() {}); // Sementara rebuild saja
      }
    } else {
      setState(() {}); // Rebuild jika key null
    }
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      setState(() {
        _searchQuery = _searchController.text;
        _filterHistory();
      });
    }
  }

  void _filterHistory() {
    final currentHistory = widget.chatController.chatHistory;
    if (_searchQuery.isEmpty) {
      _filteredHistory = List.from(currentHistory);
    } else {
      final queryLower = _searchQuery.toLowerCase();
      _filteredHistory = currentHistory.where((item) {
        final nameMatch = item.contactName.toLowerCase().contains(queryLower);
        final messageMatch =
            item.lastMessage.toLowerCase().contains(queryLower);
        return nameMatch || messageMatch;
      }).toList();
    }
    if (mounted) setState(() {}); // Update UI setelah filter
  }

  void _deleteChat(String id, int index) {
    if (index >= _filteredHistory.length) return; // Safety check

    final itemToRemove = _filteredHistory[index];
    // Hapus dari state filtered list dulu untuk animasi
    setState(() {
      _filteredHistory.removeAt(index);
    });

    // Animate removal from AnimatedList
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovedItem(itemToRemove, animation),
      duration: const Duration(milliseconds: 400),
    );

    // Hapus dari data source (controller)
    widget.chatController.removeChatHistory(id);

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${itemToRemove.contactName} dihapus.'),
        backgroundColor: Colors.redAccent[100],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRemovedItem(ChatHistoryItem item, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        axisAlignment: -1.0,
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.grey),
          title: Text(item.contactName),
          subtitle: Text(item.lastMessage, maxLines: 1),
          dense: true,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String chatId, String contactName, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Hapus Obrolan?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Text('Yakin mau hapus obrolan "$contactName"?',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.8))),
          actions: <Widget>[
            TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.of(context).pop()),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteChat(chatId, index);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToDetail(ChatHistoryItem item) {
    Navigator.pop(context);
    Navigator.push(
      context,
      createChatDetailRoute(
        // Panggil fungsi route builder
        chatId: item.id,
        contactName: item.contactName,
        isNewChat: false,
        chatController: widget.chatController,
        selectedFlow: item.aiFlow,
        sessionId: item.sessionId, // Pass existing sessionId
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerTheme = Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Theme.of(context).colorScheme.onSurface,
              displayColor: Theme.of(context).colorScheme.onSurface,
            ),
        listTileTheme: ListTileThemeData(
          iconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          textColor: Theme.of(context).colorScheme.onSurface,
          selectedColor: Theme.of(context)
              .colorScheme
              .primary, // Warna jika ada item terpilih
        ));

    final bool isHistoryEmpty = widget.chatController.chatHistory.isEmpty;

    return Theme(
      data: drawerTheme, // Terapkan tema khusus
      child: Column(
        children: [
          // Search Bar di dalam Drawer
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                  color: drawerTheme.colorScheme.onSurface), // Warna teks input
              decoration: InputDecoration(
                hintText: 'Cari obrolan...',
                hintStyle:
                    TextStyle(color: drawerTheme.hintColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search,
                    size: 20, color: drawerTheme.iconTheme.color),
                filled: true,
                fillColor: drawerTheme.colorScheme.surface
                    .withOpacity(0.5), // Sedikit transparan
                isDense: true, // Bikin lebih compact
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Divider
          Divider(
              height: 1,
              thickness: 1,
              color: drawerTheme.dividerColor.withOpacity(0.1)),

          // Animated List
          Expanded(
            child: isHistoryEmpty // Cek dari controller
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("Tidak ada chat history disini.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: drawerTheme.colorScheme.onSurface
                                  .withOpacity(0.5))),
                    ),
                  )
                : (_filteredHistory.isEmpty && _searchQuery.isNotEmpty)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text("Tidak ada hasil untuk '$_searchQuery'.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: drawerTheme.colorScheme.onSurface
                                      .withOpacity(0.5))),
                        ),
                      )
                    : Scrollbar(
                        // Tambah scrollbar
                        controller: _scrollController,
                        thumbVisibility: true, // Selalu tampilkan thumb
                        thickness: 4.0,
                        radius: const Radius.circular(20),
                        child: AnimatedList(
                          key: _listKey,
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                              top: 8.0, bottom: 16.0), // Padding list
                          initialItemCount: _filteredHistory.length,
                          itemBuilder: (context, index, animation) {
                            if (index >= _filteredHistory.length) {
                              return const SizedBox.shrink(); // Safety check
                            }
                            final chat = _filteredHistory[index];

                            // Animasi masuk item (fade in sederhana untuk drawer)
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                  parent: animation, curve: Curves.easeIn),
                              child: ListTile(
                                leading: const Icon(Icons.chat_bubble_outline,
                                    size: 20),
                                title: Text(chat.contactName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text(
                                  chat.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: drawerTheme.colorScheme.onSurface
                                          .withOpacity(0.6)),
                                ),
                                trailing: Icon(Icons.chevron_right,
                                    size: 18,
                                    color: drawerTheme.iconTheme
                                        .color), // Indikator bisa diklik
                                dense: true, // Bikin lebih compact
                                onTap: () => _navigateToDetail(chat),
                                onLongPress: () => _showDeleteConfirmation(
                                    context, chat.id, chat.contactName, index),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          // Divider lagi di bawah (opsional)
          Divider(
              height: 1,
              thickness: 1,
              color: drawerTheme.dividerColor.withOpacity(0.1)),
        ],
      ),
    );
  }
}

// --- Loading Indicator Widget ---
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

// State untuk TypingIndicator
class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1, _dot2, _dot3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(); // Loop animasi

    // Animasi untuk masing-masing dot (fade in/out dengan delay)
    _dot1 = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    _dot2 = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));
    _dot3 = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(Animation<double> animation, BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withOpacity(0.6), // Warna dot
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft, // Align ke kiri seperti pesan diterima
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surface, // Warna background bubble loading
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min, // Ukuran row secukupnya
              children: [
                _buildDot(_dot1, context),
                _buildDot(_dot2, context),
                _buildDot(_dot3, context),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- Entry Point / Welcome Page ---
class ChatWelcomePage extends StatefulWidget {
  const ChatWelcomePage({super.key});

  @override
  State<ChatWelcomePage> createState() => _ChatWelcomePageState();
}

// State untuk ChatWelcomePage
class _ChatWelcomePageState extends State<ChatWelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeHeader, _fadeContent, _fadeInput;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  AiFlow _selectedFlowForNewChat = AiFlow.defaultChat; // Default
  bool _isQwenThinkingModeForNewChat =
      false; // <-- State baru untuk toggle Qwen di Welcome Page

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeHeader = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _fadeContent = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    ));

    _fadeInput = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();

    final chatController = Provider.of<ChatController>(context, listen: false);
    // Panggil loadInitialData di sini jika belum dipanggil di tempat lain (misal di main.dart atau SplashScreen)
    // Untuk memastikan usage data termuat sebelum UI welcome page dibangun.
    // Jika sudah dipanggil, baris ini bisa di-skip.
    // chatController.loadInitialData(); // Uncomment jika perlu dipanggil di sini

    _initializeSelectedFlow(chatController);

    _textController.addListener(() {
      if (mounted) {
        setState(() {
          _isTyping = _textController.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initializeSelectedFlow(ChatController controller) {
    // Coba set ke model pertama yang tersedia (tidak limited)
    var availableFlows = aiModelDetails.keys
        .where((flow) =>
            flow != AiFlow.none && !(controller.isModelLimitReached(flow)))
        .toList();

    if (availableFlows.isNotEmpty) {
      // Prioritaskan model yang bukan default jika tersedia & tidak limit
      var nonDefaultAvailable =
          availableFlows.where((f) => f != AiFlow.defaultChat).toList();
      if (nonDefaultAvailable.isNotEmpty) {
        _selectedFlowForNewChat = nonDefaultAvailable.first;
      } else {
        // Jika hanya defaultChat yang tersedia
        _selectedFlowForNewChat = availableFlows.first;
      }
    } else {
      // Jika semua limited, fallback ke defaultChat (dropdown akan disabled atau menampilkan pesan)
      // atau model pertama dalam list (meskipun limited) agar ada yang terpilih.
      _selectedFlowForNewChat = aiModelDetails.keys.firstWhere(
          (f) => f != AiFlow.none,
          orElse: () => AiFlow.defaultChat);
    }
    if (mounted) setState(() {});
  }

  void _handleSubmitted(String text) {
    final message = text.trim();
    if (message.isEmpty) return;

    final chatController = Provider.of<ChatController>(context, listen: false);

    if (chatController.isModelLimitReached(_selectedFlowForNewChat)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Model ${aiModelDetails[_selectedFlowForNewChat]?.displayName ?? ""} sudah mencapai batas harian. Pilih model lain atau tunggu reset besok jam 5 pagi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newChatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    final newSessionId =
        'session_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString().substring(UniqueKey().toString().indexOf('#') + 1, UniqueKey().toString().length - 2)}';

    _textController.clear();
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
    }

    // **PENTING**: Simpan status thinking mode ke controller SEBELUM navigasi
    if (_selectedFlowForNewChat == AiFlow.qwen3_235b_a22b &&
        (aiModelDetails[AiFlow.qwen3_235b_a22b]?.isHybridThinking ?? false)) {
      chatController.setQwenThinkingMode(
          newChatId, _isQwenThinkingModeForNewChat);
    }

    final args = ChatDetailArguments(
      chatId: newChatId,
      contactName: "Obrolan Baru", // Akan diupdate di ChatDetailPage
      isNewChat: true,
      chatController: chatController,
      selectedFlow: _selectedFlowForNewChat,
      sessionId: newSessionId,
      initialMessage: message,
    );

    Navigator.push(
      context,
      createChatDetailRoute(
        chatId: args.chatId,
        contactName: args.contactName,
        isNewChat: args.isNewChat,
        chatController: args.chatController,
        selectedFlow: args.selectedFlow,
        sessionId: args.sessionId,
        initialMessage: args.initialMessage,
      ),
    ).then((_) {
      // Setelah kembali dari chat detail, refresh state dropdown
      // karena batas model mungkin tercapai di sana.
      if (mounted) {
        _initializeSelectedFlow(chatController); // Re-evaluasi model terpilih
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, chatController, child) {
        final bool allModelEffectivelyLimited =
            chatController.getAreAllModelsLimited(); // Cek semua model
        if (chatController.isModelLimitReached(_selectedFlowForNewChat) &&
            !allModelEffectivelyLimited) {
          Future.microtask(() => _initializeSelectedFlow(chatController));
        }

        final bool shouldShowQwenToggle =
            _selectedFlowForNewChat == AiFlow.qwen3_235b_a22b &&
                (aiModelDetails[AiFlow.qwen3_235b_a22b]?.isHybridThinking ??
                    false) &&
                !chatController.isModelLimitReached(AiFlow.qwen3_235b_a22b);

        return WillPopScope(
          onWillPop: () async {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
              (Route<dynamic> route) => false,
            );
            return false;
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            drawer: Drawer(
              backgroundColor: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 10),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Riwayat Obrolan',
                        style: TextStyle(
                          color: Color(0xFF6A62B7),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _ChatHistoryListWidget(
                          chatController: chatController),
                    ),
                  ],
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Header with Elang AI title and model dropdown
                  FadeTransition(
                    opacity: _fadeHeader,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Menu icon
                          Builder(
                            builder: (context) => IconButton(
                              icon:
                                  const Icon(Icons.menu, color: Colors.black87),
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              tooltip: 'Riwayat Obrolan',
                            ),
                          ),

                          // Center section with title and dropdown
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Elang AI',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Model selection dropdown (display only)
                                allModelEffectivelyLimited
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Text(
                                            'Semua model mencapai batas, tunggu besok jam 5 pagi',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12)),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0),
                                        decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1)),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<AiFlow>(
                                            value: _selectedFlowForNewChat,
                                            icon: const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.black54,
                                                size: 20),
                                            elevation: 8,
                                            style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 14),
                                            dropdownColor: Colors.grey.shade50,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            onChanged: (AiFlow? newValue) {
                                              if (newValue != null) {
                                                if (!chatController
                                                    .isModelLimitReached(
                                                        newValue)) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _selectedFlowForNewChat =
                                                          newValue;
                                                      // Reset toggle Qwen jika model yang dipilih bukan Qwen
                                                      if (_selectedFlowForNewChat !=
                                                          AiFlow
                                                              .qwen3_235b_a22b) {
                                                        _isQwenThinkingModeForNewChat =
                                                            false;
                                                      }
                                                    });
                                                  }
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Model ${aiModelDetails[newValue]?.displayName ?? ""} sudah batas. Pilih yang lain.'),
                                                      backgroundColor:
                                                          Colors.orange,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            items: aiModelDetails.keys
                                                .where((flow) =>
                                                    flow != AiFlow.none)
                                                .map<DropdownMenuItem<AiFlow>>(
                                                    (AiFlow flow) {
                                              final modelDetail =
                                                  aiModelDetails[flow]!;
                                              final isLimited = chatController
                                                  .isModelLimitReached(flow);
                                              final usageCount = chatController
                                                  .getModelUsageCount(flow);
                                              final limit =
                                                  modelDetail.dailyLimit;
                                              String sisaText = (limit > 0 &&
                                                      !isLimited)
                                                  ? ' Sisa: ${limit - usageCount}/$limit'
                                                  : '';
                                              if (flow == AiFlow.defaultChat &&
                                                  !isLimited) {
                                                sisaText =
                                                    ''; // Jangan tampilkan sisa untuk default jika tidak limit
                                              }

                                              return DropdownMenuItem<AiFlow>(
                                                value: flow,
                                                enabled: !isLimited,
                                                child: Opacity(
                                                  opacity:
                                                      isLimited ? 0.6 : 1.0,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        modelDetail.displayName
                                                            .replaceAll(
                                                                " (7 limit)",
                                                                "")
                                                            .replaceAll(
                                                                " (1000 limit)",
                                                                ""), // Nama bersih
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: isLimited
                                                              ? Colors
                                                                  .grey.shade600
                                                              : Colors.black87,
                                                          fontWeight:
                                                              _selectedFlowForNewChat ==
                                                                      flow
                                                                  ? FontWeight
                                                                      .w500
                                                                  : FontWeight
                                                                      .normal,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      if (isLimited)
                                                        Text(
                                                            'Batas tercapai, reset jam 5 pagi',
                                                            style: TextStyle(
                                                                fontSize: 9,
                                                                color: Colors
                                                                    .red
                                                                    .shade400))
                                                      else if (sisaText
                                                          .isNotEmpty)
                                                        Text(sisaText.trim(),
                                                            style: TextStyle(
                                                                fontSize: 9,
                                                                color: Colors
                                                                    .grey
                                                                    .shade600)),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),

                                // --- QWEN THINKING TOGGLE DI WELCOME PAGE ---
                                if (shouldShowQwenToggle) // Tampilkan jika kondisi terpenuhi
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center, // Atau sesuaikan alignment
                                      children: [
                                        Text(
                                          'Mode Berpikir (Qwen):',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Switch(
                                          value: _isQwenThinkingModeForNewChat,
                                          onChanged: (bool value) {
                                            if (mounted) {
                                              setState(() {
                                                _isQwenThinkingModeForNewChat =
                                                    value;
                                              });
                                            }
                                          },
                                          activeColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          inactiveThumbColor:
                                              Colors.grey.shade400,
                                          inactiveTrackColor:
                                              Colors.grey.shade300,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Profile icon with logo and blue border
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue,
                                width: 2.0,
                              ),
                            ),
                            child: ClipOval(
                              child: Container(
                                width: 36,
                                height: 36,
                                child: Image.asset(
                                  'assets/LOGO3.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main content area
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeContent,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              MediaQuery.of(context).size.width > 600 ? 40 : 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Welcome message
                            Text(
                              'Hai, Asisten AI siap membantu!',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width > 600
                                        ? 32
                                        : 24,
                                fontWeight: FontWeight.w300,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Subtitle
                            Text(
                              'Tanyakan apa saja, dari ide kreatif hingga solusi teknis. Saya di sini untuk membantu Anda.',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width > 600
                                        ? 16
                                        : 14,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Input area
                  FadeTransition(
                    opacity: _fadeInput,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 800),
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            MediaQuery.of(context).size.width > 600 ? 40 : 16,
                        vertical: 20,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Attachment button
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: Colors.grey.shade600,
                                size: MediaQuery.of(context).size.width > 600
                                    ? 24
                                    : 22,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Fitur lampiran belum tersedia.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),

                            // Text input
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ketik pesan Anda di sini...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize:
                                        MediaQuery.of(context).size.width > 600
                                            ? 16
                                            : 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 16,
                                  ),
                                ),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_isTyping &&
                                            !allModelEffectivelyLimited) ||
                                        (_isTyping &&
                                            !chatController.isModelLimitReached(
                                                _selectedFlowForNewChat))
                                    ? _handleSubmitted
                                    : null,
                              ),
                            ),

                            // Additional options
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.mic_none,
                                    color: Colors.grey.shade600,
                                    size:
                                        MediaQuery.of(context).size.width > 600
                                            ? 24
                                            : 22,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Fitur input suara belum tersedia.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: (_isTyping &&
                                                !allModelEffectivelyLimited) ||
                                            (_isTyping &&
                                                !chatController
                                                    .isModelLimitReached(
                                                        _selectedFlowForNewChat))
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.arrow_upward,
                                      color: Colors.white,
                                      size: MediaQuery.of(context).size.width >
                                              600
                                          ? 24
                                          : 22,
                                    ),
                                    onPressed: (_isTyping &&
                                                !allModelEffectivelyLimited) ||
                                            (_isTyping &&
                                                !chatController
                                                    .isModelLimitReached(
                                                        _selectedFlowForNewChat))
                                        ? () => _handleSubmitted(
                                            _textController.text)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Chat Detail Page ---
class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String contactName;
  final bool isNewChat;
  final ChatController chatController;
  final AiFlow selectedFlow;
  final String sessionId;
  final String? initialMessage;

  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.contactName,
    this.isNewChat = false,
    required this.chatController,
    this.selectedFlow = AiFlow.defaultChat,
    required this.sessionId,
    this.initialMessage,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

// ChatDetailPage State
class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];

  bool _currentIsNewChat = false;
  String _currentContactName = '';
  bool _isLoadingResponse = false;
  String _currentSessionId = '';
  bool _isQwenThinkingModeUIToggle = false; // State UI untuk toggle Qwen

  @override
  void initState() {
    super.initState();
    _currentIsNewChat = widget.isNewChat;
    _currentContactName = widget.contactName;
    _currentSessionId = widget.sessionId;

    _loadMessages(); // Juga memuat state thinking mode jika chat Qwen sudah ada

    // Inisialisasi UI toggle (meskipun UI toggle-nya akan kita hapus dari halaman ini)
    // dan pastikan state _isQwenThinkingModeUIToggle di sini sinkron dengan controller untuk chat baru.
    if (widget.selectedFlow == AiFlow.qwen3_235b_a22b &&
        (aiModelDetails[AiFlow.qwen3_235b_a22b]?.isHybridThinking ?? false)) {
      if (_currentIsNewChat) {
        // Untuk chat BARU, ambil state dari ChatController yang sudah di-set oleh ChatWelcomePage
        _isQwenThinkingModeUIToggle =
            widget.chatController.isQwenThinkingModeActive(widget.chatId);
      }
      // Untuk chat yang SUDAH ADA, _loadMessages() seharusnya sudah mengatur _isQwenThinkingModeUIToggle
      // dari ChatHistoryItem.isThinkingModeExplicitlyEnabled.
    }

    // Tambahkan listener untuk _textController
    _textController.addListener(_onTextChanged); // <--- BARIS BARU

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!widget.chatController.isModelLimitReached(widget.selectedFlow)) {
          _handleSubmitted(widget.initialMessage!);
        } else {
          _showModelLimitReachedSnackbar(widget.selectedFlow);
        }
      });
    }
  }

  // Method baru untuk dipanggil oleh listener
  void _onTextChanged() {
    if (mounted) {
      // Selalu baik untuk mengecek 'mounted' sebelum setState
      setState(() {
        // Panggilan setState kosong ini sudah cukup untuk memicu rebuild
        // dan mengevaluasi ulang kondisi tombol kirim.
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged); // <--- Hapus listener
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    if (!_currentIsNewChat) {
      final chatData = widget.chatController.getChatById(widget.chatId);
      if (chatData != null) {
        _messages = List.from(chatData.messages);
        _currentSessionId = chatData.sessionId;
        if (chatData.contactName != _currentContactName) {
          if (mounted) {
            setState(() {
              _currentContactName = chatData.contactName;
            });
          }
        }
        // Load persisted thinking mode for Qwen
        if (chatData.aiFlow == AiFlow.qwen3_235b_a22b) {
          _isQwenThinkingModeUIToggle =
              chatData.isThinkingModeExplicitlyEnabled;
          // Sinkronkan juga ke ChatController jika perlu (seharusnya sudah dari loadInitialData)
          // widget.chatController.setQwenThinkingMode(widget.chatId, _isQwenThinkingModeUIToggle);
        }
      } else {
        _messages = [];
      }
    }
  }

  void _addMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      _messages.add(message);
    });
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  void _removeLoadingIndicator() {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.type == MessageType.loading);
    });
  }

  void _updateHistory(
      String userQuestion, String aiResponseContent, DateTime timestamp) {
    String finalContactName = _currentContactName;
    if (_currentIsNewChat &&
        (_currentContactName == "Obrolan Baru" ||
            _currentContactName.isEmpty)) {
      finalContactName = userQuestion.length > 25
          ? '${userQuestion.substring(0, 22)}...'
          : userQuestion;
      if (mounted) {
        setState(() {
          _currentContactName = finalContactName;
        });
      }
    }
    if (_currentIsNewChat) _currentIsNewChat = false;

    final updatedHistoryItem = ChatHistoryItem(
      id: widget.chatId,
      contactName: finalContactName,
      lastMessage: aiResponseContent, // Hanya content untuk preview
      lastMessageTime: timestamp,
      messages: _messages.where((m) => m.type != MessageType.loading).toList(),
      aiFlow: widget.selectedFlow,
      sessionId: _currentSessionId,
      isThinkingModeExplicitlyEnabled:
          (widget.selectedFlow == AiFlow.qwen3_235b_a22b)
              ? _isQwenThinkingModeUIToggle
              : false,
    );
    widget.chatController.addOrUpdateChatHistory(updatedHistoryItem);
  }

  void _handleSubmitted(String text) {
    final question = text.trim();
    if (question.isNotEmpty && !_isLoadingResponse) {
      if (widget.chatController.isModelLimitReached(widget.selectedFlow)) {
        _showModelLimitReachedSnackbar(widget.selectedFlow);
        return;
      }

      _textController.clear();
      String questionToSend = question;
      bool isQwenCommandOnly = false;

      // Khusus Qwen: modifikasi pertanyaan jika thinking mode di-toggle atau command diketik
      if (widget.selectedFlow == AiFlow.qwen3_235b_a22b &&
          aiModelDetails[AiFlow.qwen3_235b_a22b]!.isHybridThinking) {
        if (question.toLowerCase().endsWith(" /think")) {
          questionToSend =
              question.substring(0, question.length - " /think".length).trim();
          if (!_isQwenThinkingModeUIToggle) {
            // Jika belum aktif, aktifkan
            if (mounted) {
              setState(() {
                _isQwenThinkingModeUIToggle = true;
              });
            }
            widget.chatController.setQwenThinkingMode(widget.chatId, true);
          }
          if (questionToSend.isEmpty) isQwenCommandOnly = true;
        } else if (question.toLowerCase().endsWith(" /no_think")) {
          questionToSend = question
              .substring(0, question.length - " /no_think".length)
              .trim();
          if (_isQwenThinkingModeUIToggle) {
            // Jika aktif, non-aktifkan
            if (mounted) {
              setState(() {
                _isQwenThinkingModeUIToggle = false;
              });
            }
            widget.chatController.setQwenThinkingMode(widget.chatId, false);
          }
          if (questionToSend.isEmpty) isQwenCommandOnly = true;
        } else if (_isQwenThinkingModeUIToggle) {
          // Jika toggle UI aktif dan tidak ada command eksplisit, tambahkan /think (jika modelnya hybrid)
          // Cek apakah model yang dipilih memang Qwen yang hybrid
          // Ini adalah asumsi bahwa user ingin thinking jika toggle ON.
          // Alternatifnya, user HARUS ketik /think sendiri. Untuk sekarang, kita buat otomatis.
          // Tapi, karena API OpenRouter tidak punya parameter 'mode', maka /think di prompt adalah cara utama.
          // Jadi, jika toggle ON, dan bukan command, kita tambahkan /think.
          // Namun, agar tidak duplikat jika user sudah mengetik, kita tidak tambahkan di sini.
          // Biarkan 'reasoning' field dari API yang menentukan. `/think` di prompt lebih untuk memaksa modelnya.
          // Untuk Qwen, jika _isQwenThinkingModeUIToggle == true, kita *harap* API memberi reasoning.
          // Jika user mengetik `/think` atau `/no_think`, itu akan jadi bagian dari `questionToSend` jika tidak kosong.
        }
      }

      if (isQwenCommandOnly) {
        // Hanya command Qwen, jangan kirim ke AI, cukup update UI/state
        _addMessage(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: question, // Tampilkan command asli
          isSentByUser: true,
          timestamp: DateTime.now(),
        ));
        // Mungkin tambahkan pesan info "Mode thinking diubah"
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Mode thinking untuk Qwen diubah."),
          duration: Duration(seconds: 1),
        ));
        return;
      }

      _addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: question, // Tampilkan pertanyaan asli user
        isSentByUser: true,
        timestamp: DateTime.now(),
      ));
      _getAiResponse(questionToSend.isEmpty
          ? question
          : questionToSend); // Kirim pertanyaan yang sudah dimodifikasi jika perlu
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 50,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuad,
      );
    }
  }

  void _showModelLimitReachedSnackbar(AiFlow flow) {
    final modelDetail = aiModelDetails[flow];
    Flushbar(
      title: 'Batas Tercapai: ${modelDetail?.displayName ?? "Model Ini"}',
      message:
          'Anda telah menggunakan ${modelDetail?.dailyLimit ?? ""} pertanyaan. Reset besok jam 5 pagi.',
      icon: Icon(Icons.error_outline_rounded,
          size: 28.0, color: Colors.yellow[600]),
      backgroundColor: Colors.redAccent.shade700.withOpacity(0.95),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      borderRadius: BorderRadius.circular(12),
      boxShadows: const [
        BoxShadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 5)
      ],
      flushbarPosition: FlushbarPosition.TOP,

      // Animasi Masuk/Keluar
      animationDuration: const Duration(milliseconds: 600),
      forwardAnimationCurve: Curves.fastOutSlowIn, // Smooth in
      reverseAnimationCurve: Curves.easeOutCubic, // Smooth out

      // Flushbar menggunakan forwardAnimationCurve untuk slide juga
      isDismissible: true,
    ).show(context);
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    Flushbar(
      title: 'Error',
      message: message,
      icon: const Icon(Icons.error_rounded, size: 28.0, color: Colors.white),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 400),
    ).show(context);
  }

  // --- Handle API Call ---
  Future<void> _getAiResponse(String userQuestion) async {
    final currentFlow = widget.selectedFlow;
    final apiUrl = getApiUrlForFlow(currentFlow);
    final modelIdForApi = getModelIdentifier(currentFlow);

    if (widget.chatController.isModelLimitReached(currentFlow)) {
      _showModelLimitReachedSnackbar(currentFlow);
      return; // Hentikan jika sudah limit
    }

    if (apiUrl == null ||
        (currentFlow != AiFlow.defaultChat && modelIdForApi == null)) {
      _showErrorSnackbar("Konfigurasi model tidak valid.");
      return;
    }

    setState(() {
      _isLoadingResponse = true;
    });

    _addMessage(ChatMessage(
        id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
        isSentByUser: false,
        timestamp: DateTime.now(),
        type: MessageType.loading));

    String? aiResponseContentText;
    String? aiThinkingText;

    try {
      http.Response response;

      if (currentFlow == AiFlow.defaultChat) {
        final requestBody = jsonEncode({
          "question": userQuestion,
          "overrideConfig": {
            "sessionId": _currentSessionId, // Use the current session ID
            "chatId": widget.chatId // Use the conversation ID (widget.chatId)
          }
        });

        response = await http
            .post(
              Uri.parse(apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': '*/*',
              },
              body: requestBody,
            )
            .timeout(const Duration(
                seconds: 45)); // Timeout lebih lama untuk non-streaming

        if (response.statusCode == 200) {
          final decodedBody = jsonDecode(response.body);
          aiResponseContentText = decodedBody['text'] as String?;
        } else {
          if (response.statusCode == 401) {
            _showErrorSnackbar("Akses ditolak (401)...");
          } else {
            _showErrorSnackbar(
                "Gagal menghubungi AI (Status: ${response.statusCode}).");
          }
        }
      } else {
        // Panggilan ke OpenRouter (Gemma & Qwen)
        // Kumpulkan history pesan untuk konteks (opsional, tapi direkomendasikan)
        List<Map<String, String>> contextMessages = [];
        final recentMessages = _messages
            .where((m) => m.type == MessageType.text && m.text.isNotEmpty)
            .toList();
        int messageHistoryCount = 5; // Ambil 5 pesan terakhir sebagai konteks

        for (var msg in recentMessages.reversed
            .take(messageHistoryCount)
            .toList()
            .reversed) {
          // Untuk pesan AI, kirim hanya content part jika ada thinking part
          String textForApi = msg.isSentByUser ? msg.text : msg.contentPart;
          // Hindari mengirimkan command /think atau /no_think sebagai history
          if (msg.isSentByUser &&
              (textForApi.toLowerCase().endsWith(" /think") ||
                  textForApi.toLowerCase().endsWith(" /no_think"))) {
            textForApi = textForApi
                .replaceAllMapped(
                    RegExp(r" /think$", caseSensitive: false), (match) => "")
                .replaceAllMapped(
                    RegExp(r" /no_think$", caseSensitive: false), (match) => "")
                .trim();
          }
          if (textForApi.isNotEmpty) {
            contextMessages.add({
              "role": msg.isSentByUser ? "user" : "assistant",
              "content": textForApi
            });
          }
        }

        String finalUserQuestionForApi = userQuestion;
        // Jika Qwen dan thinking mode ON dari UI, dan user tidak ketik command, kita bisa coba tambahkan `/think`
        // Namun, ini lebih baik dihandle dengan parsing 'reasoning' saja jika ada.
        // Pengiriman `/think` lebih untuk user override.

        final messagesPayload = [
          ...contextMessages,
          {"role": "user", "content": finalUserQuestionForApi}
        ];

        final requestBody =
            jsonEncode({"model": modelIdForApi, "messages": messagesPayload});

        response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openRouterAPI',
            'X-Title': 'Elang AI App', // Opsional, sesuaikan
          },
          body: requestBody,
        );

        if (response.statusCode == 200) {
          final decodedBody = jsonDecode(response.body);
          if (decodedBody['choices'] != null &&
              (decodedBody['choices'] as List).isNotEmpty) {
            final messageData = decodedBody['choices'][0]['message'];
            aiResponseContentText = messageData['content'] as String?;
            // Ambil 'reasoning' jika ada, untuk Gemma dan Qwen
            if (messageData['reasoning'] != null &&
                (messageData['reasoning'] as String).trim().isNotEmpty) {
              aiThinkingText = messageData['reasoning'] as String;
            }
          } else if (decodedBody['error'] != null) {
            _showErrorSnackbar(
                "OpenRouter API Error: ${decodedBody['error']['message']}");
          } else {
            _showErrorSnackbar("Respons tidak valid dari OpenRouter.");
          }
        } else {
          /* ... handle error OpenRouter ... */
          String errorDetail = response.body;
          try {
            final decodedError = jsonDecode(response.body);
            if (decodedError['error'] != null &&
                decodedError['error']['message'] != null) {
              errorDetail = decodedError['error']['message'];
            }
          } catch (_) {}
          _showErrorSnackbar(
              "OpenRouter Error (${response.statusCode}): $errorDetail");
        }
      }

      if (aiResponseContentText == null ||
          aiResponseContentText.trim().isEmpty) {
        if (response.statusCode == 200 && (currentFlow != AiFlow.defaultChat)) {
          // OpenRouter mungkin 200 tapi content kosong jika ada filter/refusal
          final decodedBody = jsonDecode(response.body);
          if (decodedBody['choices'] != null &&
              (decodedBody['choices'] as List).isNotEmpty) {
            final choice = decodedBody['choices'][0];
            if (choice['finish_reason'] != 'stop' &&
                choice['finish_reason'] != null) {
              aiResponseContentText =
                  "[Respon dihentikan: ${choice['finish_reason']}]"; // Tampilkan alasan jika bukan 'stop'
            } else if (choice['message']?['refusal'] != null) {
              aiResponseContentText =
                  "[Respon ditolak: ${choice['message']['refusal']}]";
            } else if (aiThinkingText != null && aiThinkingText.isNotEmpty) {
              aiResponseContentText =
                  "[Tidak ada konten utama, hanya proses berpikir yang tersedia]"; // Jika hanya ada thinking
            } else {
              _showErrorSnackbar("AI memberikan respons kosong.");
              aiResponseContentText = null;
            }
          } else {
            _showErrorSnackbar("AI memberikan respons kosong.");
            aiResponseContentText = null;
          }
        } else if (response.statusCode == 200 &&
            currentFlow == AiFlow.defaultChat) {
          _showErrorSnackbar("AI memberikan respons kosong.");
          aiResponseContentText = null;
        }
      }
    } on TimeoutException catch (_) {
      _showErrorSnackbar("Koneksi ke server AI timeout.");
      aiResponseContentText = null;
    } catch (e, s) {
      print("Error _getAiResponse: $e\n$s"); // Debug error
      _showErrorSnackbar("Terjadi kesalahan.");
      aiResponseContentText = null;
    }

    if (!mounted) return;
    _removeLoadingIndicator();

    if (aiResponseContentText != null) {
      // Berhasil dapat response (meskipun mungkin hanya info error/refusal)
      await widget.chatController.incrementModelUsage(
          currentFlow); // Increment HANYA jika ada teks balasan (sukses atau info)

      String finalTextForBubble = aiResponseContentText.trim();
      // Gabungkan thinking dan content untuk disimpan di ChatMessage.text
      if (aiThinkingText != null &&
          aiThinkingText.isNotEmpty &&
          ((currentFlow == AiFlow.qwen3_235b_a22b &&
                  _isQwenThinkingModeUIToggle) || // Tampilkan jika Qwen & mode thinking aktif dari UI
              currentFlow ==
                  AiFlow
                      .gemma3_27b_it || // Selalu tampilkan thinking untuk Gemma jika ada
              (currentFlow == AiFlow.qwen3_235b_a22b &&
                  !(aiModelDetails[AiFlow.qwen3_235b_a22b]!
                      .isHybridThinking)) // Jika Qwen non-hybrid tapi ada reasoning
          )) {
        finalTextForBubble =
            "Thinking:\n$aiThinkingText\n----------------------\n${aiResponseContentText.trim()}";
      }

      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        isSentByUser: false,
        timestamp: DateTime.now(),
        text: finalTextForBubble, // Simpan teks gabungan
      );
      _addMessage(aiMessage);
      _updateHistory(userQuestion, aiResponseContentText.trim(),
          aiMessage.timestamp); // Kirim content asli ke history
    } else {
      // Jika gagal total mendapatkan teks apa pun, jangan increment
      // Pesan error sudah ditampilkan
    }

    setState(() {
      _isLoadingResponse = false;
    });
  }

  // --- Fungsi untuk buka URL di browser eksternal ---
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      // Coba buka di browser eksternal
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('Error launching URL: $e');
      // Tampilkan pesan error ke user jika gagal buka link
      _showErrorSnackbar('Tidak dapat membuka link');
    }
  }

  Widget _buildMessageItem(BuildContext context, int index) {
    if (index < 0 || index >= _messages.length) return const SizedBox.shrink();
    final message = _messages[index];

    if (message.type == MessageType.loading) {
      return const TypingIndicator();
    }

    final bool isSentByUser = message.isSentByUser;
    final alignment =
        isSentByUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isSentByUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surface;
    final textColor = isSentByUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;
    final borderRadius = isSentByUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    Widget messageContentWidget;
    final String? thinkingPart = message.thinkingPart; // Gunakan getter
    final String contentPart = message.contentPart; // Gunakan getter

    // Tentukan apakah akan render contentPart sebagai HTML atau Markdown
    bool useHtmlRenderer = false;
    if (!isSentByUser) {
      // Cek jika contentPart mengandung tag img HTML, maka gunakan Html renderer
      final containsHtmlImg = RegExp(r'<img[^>]*>').hasMatch(contentPart);
      if (containsHtmlImg) {
        useHtmlRenderer = true;
      }
    }

    Widget mainContentDisplay;
    if (useHtmlRenderer) {
      // Use Html widget to render the entire content including images
      mainContentDisplay = Html(
        data: contentPart,
        style: {
          "body": Style(
            color: textColor,
            fontSize: FontSize(15.5),
            lineHeight: const LineHeight(1.3),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          "a": Style(
            color: Colors.lightBlueAccent,
            textDecoration: TextDecoration.underline,
          ),
          "strong": Style(fontWeight: FontWeight.bold),
          "em": Style(fontStyle: FontStyle.italic),
          "img": Style(
            margin: Margins.symmetric(vertical: 8),
          ),
        },
        onLinkTap: (url, attributes, element) {
          if (url != null) {
            _launchUrl(url);
          }
        },
        extensions: [
          TagExtension(
            tagsToExtend: {"img"},
            builder: (extensionContext) {
              final element = extensionContext.element;
              final src = element?.attributes['src'];
              final widthAttr = element?.attributes['width'];

              if (src != null) {
                double? imageWidth;

                if (widthAttr != null && widthAttr.endsWith('%')) {
                  final percentage =
                      double.tryParse(widthAttr.replaceAll('%', ''));
                  if (percentage != null) {
                    imageWidth = MediaQuery.of(context).size.width *
                        (percentage / 100) *
                        0.7;
                  }
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      src,
                      width: imageWidth,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: imageWidth ?? 200,
                          height: 150,
                          color: Colors.grey.withOpacity(0.2),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $src - $error');
                        return Container(
                          width: imageWidth ?? 200,
                          height: 150,
                          color: Colors.grey.withOpacity(0.2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 48, color: textColor.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text('Gagal memuat gambar',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.5),
                                    fontSize: 12,
                                  )),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      );
    } else {
      // If no HTML img tags, use MarkdownBody for better markdown rendering
      mainContentDisplay = MarkdownBody(
        data: contentPart,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: textColor, fontSize: 15.5, height: 1.3),
          strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
          listBullet: TextStyle(color: textColor, fontSize: 15.5, height: 1.3),
          code: TextStyle(
              backgroundColor: Colors.grey.withOpacity(0.2),
              fontFamily: 'monospace',
              color: textColor.withOpacity(0.85)),
          a: const TextStyle(
              color: Colors.lightBlueAccent,
              decoration: TextDecoration.underline,
              decorationColor: Colors.lightBlueAccent),
          h1: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          h2: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          h3: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          blockquote: TextStyle(
            color: textColor.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onTapLink: (text, href, title) {
          if (href != null) {
            _launchUrl(href);
          }
        },
        imageBuilder: (uri, title, alt) {
          return Image.network(
            uri.toString(),
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.broken_image, color: textColor.withOpacity(0.5)),
          );
        },
      );
    }

    // Gabungkan dengan thinking block jika ada dan perlu ditampilkan
    if (thinkingPart != null &&
        thinkingPart.isNotEmpty &&
        !isSentByUser &&
        ((widget.selectedFlow == AiFlow.qwen3_235b_a22b &&
                _isQwenThinkingModeUIToggle) || // Qwen dengan toggle UI aktif
            widget.selectedFlow ==
                AiFlow.gemma3_27b_it || // Gemma selalu tampilkan jika ada
            (widget.selectedFlow == AiFlow.qwen3_235b_a22b &&
                !(aiModelDetails[AiFlow.qwen3_235b_a22b]!
                    .isHybridThinking)) // Qwen non-hybrid
        )) {
      messageContentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThinkingBlockWidget(
              thinkingText: thinkingPart,
              textColor: textColor.withOpacity(0.85),
              launchUrlCallback: _launchUrl),
          Divider(
              height: 12, thickness: 0.5, color: textColor.withOpacity(0.3)),
          mainContentDisplay,
        ],
      );
    } else {
      messageContentWidget = mainContentDisplay;
    }

    return Align(
      alignment: alignment,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 5,
                  offset: Offset(isSentByUser ? -1 : 1, 2))
            ]),
        child: messageContentWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentModelInfo = aiModelDetails[widget.selectedFlow];
    final bool isQwenHybrid = widget.selectedFlow == AiFlow.qwen3_235b_a22b &&
        (currentModelInfo?.isHybridThinking ?? false);
    final bool isCurrentModelLimited =
        widget.chatController.isModelLimitReached(widget.selectedFlow);

    return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: Colors.black87),
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Kembali',
            ),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _currentContactName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    currentModelInfo?.displayName ?? "Unknown Model",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue,
                    width: 2.0,
                  ),
                ),
                child: ClipOval(
                  child: Container(
                    width: 32,
                    height: 32,
                    child: Image.asset(
                      'assets/LOGO3.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              // --- QWEN THINKING TOGGLE UI ---
              if (isQwenHybrid &&
                  !isCurrentModelLimited) // Tampilkan hanya jika Qwen Hybrid dan tidak limit
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: Colors.grey
                      .shade100, // Atau Theme.of(context).colorScheme.surfaceVariant
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end, // Pindahkan ke kanan
                    children: [
                      Text('Mode Berpikir (Qwen):',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isQwenThinkingModeUIToggle,
                        onChanged: (bool value) {
                          if (mounted) {
                            setState(() {
                              _isQwenThinkingModeUIToggle = value;
                            });
                            widget.chatController
                                .setQwenThinkingMode(widget.chatId, value);
                            // Update history item agar persisten saat navigasi
                            final chatItem = widget.chatController
                                .getChatById(widget.chatId);
                            if (chatItem != null) {
                              chatItem.isThinkingModeExplicitlyEnabled = value;
                              widget.chatController
                                  .addOrUpdateChatHistory(chatItem);
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Mode berpikir Qwen ${value ? "diaktifkan" : "dinonaktifkan"}.'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating),
                            );
                          }
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              // --- END QWEN TOGGLE ---

              // Messages area with responsive design
              Expanded(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 800),
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 600
                        ? (MediaQuery.of(context).size.width - 800) / 2
                        : 0,
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal:
                          MediaQuery.of(context).size.width > 600 ? 20 : 10,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: _buildMessageItem,
                    reverse: false,
                  ),
                ),
              ),

              // Input area matching ChatWelcomePage design
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 800),
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 600
                      ? (MediaQuery.of(context).size.width - 800) / 2
                      : 0,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 600 ? 40 : 16,
                  vertical: 16,
                ).copyWith(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Attachment button
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Colors.grey.shade600,
                          size:
                              MediaQuery.of(context).size.width > 600 ? 24 : 22,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur lampiran belum tersedia.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),

                      // Text input
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          enabled:
                              !isCurrentModelLimited && !_isLoadingResponse,
                          onSubmitted:
                              (isCurrentModelLimited || _isLoadingResponse)
                                  ? null
                                  : _handleSubmitted,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: (isCurrentModelLimited
                                ? 'Batas model ini tercapai'
                                : (_isLoadingResponse
                                    ? 'Menunggu balasan...'
                                    : 'Ketik pesan Anda di sini...')),
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: MediaQuery.of(context).size.width > 600
                                  ? 16
                                  : 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 16,
                            ),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.send,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),

                      // Voice input button
                      IconButton(
                        icon: Icon(
                          Icons.mic_none,
                          color: Colors.grey.shade600,
                          size:
                              MediaQuery.of(context).size.width > 600 ? 24 : 22,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Fitur input suara belum tersedia.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),

                      // Send button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: (!isCurrentModelLimited &&
                                  !_isLoadingResponse &&
                                  _textController.text.trim().isNotEmpty)
                              ? Colors.blue.shade600
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width > 600
                                ? 24
                                : 22,
                          ),
                          onPressed: (isCurrentModelLimited ||
                                  _isLoadingResponse ||
                                  _textController.text.trim().isEmpty)
                              ? null
                              : () => _handleSubmitted(_textController.text),
                          tooltip: 'Kirim Pesan',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

// Widget untuk menampilkan blok "Thinking" yang bisa di-collapse/expand
class _ThinkingBlockWidget extends StatefulWidget {
  final String thinkingText;
  final Color textColor;
  final Function(String) launchUrlCallback; // Untuk handle link di thinking

  const _ThinkingBlockWidget({
    required this.thinkingText,
    required this.textColor,
    required this.launchUrlCallback,
  });

  @override
  State<_ThinkingBlockWidget> createState() => _ThinkingBlockWidgetState();
}

// State untuk widget _ThinkingBlockWidget
class _ThinkingBlockWidgetState extends State<_ThinkingBlockWidget> {
  bool _isExpanded = false; // Default tidak expand

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (mounted) {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Proses Berpikir AI:',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: widget.textColor.withOpacity(0.9))),
                Icon(_isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: widget.textColor.withOpacity(0.9), size: 20),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(
                top: 4.0, left: 8.0, right: 4.0, bottom: 4.0),
            child: MarkdownBody(
              data: widget.thinkingText,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                      p: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.textColor,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          height: 1.2),
                      code: TextStyle(
                          backgroundColor: Colors.grey.withOpacity(0.15),
                          fontFamily: 'monospace',
                          color: widget.textColor.withOpacity(0.85),
                          fontSize: 11.5),
                      listBullet: TextStyle(
                          color: widget.textColor, fontSize: 12.5, height: 1.2),
                      a: TextStyle(
                          color: Colors.lightBlueAccent.withOpacity(0.9),
                          decoration: TextDecoration.underline)),
              onTapLink: (text, href, title) {
                if (href != null) widget.launchUrlCallback(href);
              },
            ),
          ),
      ],
    );
  }
}
