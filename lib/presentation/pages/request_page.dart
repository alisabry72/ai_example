import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oil_collection_app/injection_container.dart';

import '../../domain/entities/request.dart';
import '../cubit/request_cubit.dart';
import '../cubit/request_state.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final List<Map<String, String>> _chatMessages = [];
  final String userId = "user123"; // Replace with dynamic user ID logic
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add initial bot message
    _chatMessages.add({
      'sender': 'AI',
      'message': 'مرحبًا! لو عايز تطلب جمع زيت، ابدأ بقول كام لتر عندك.'
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RequestCubit>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('جمع الزيت المستعمل'),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: BlocBuilder<RequestCubit, RequestState>(
                      buildWhen: (previous, current) =>
                          current is RequestUpdated ||
                          current is RequestSubmitted,
                      builder: (context, state) {
                        return Chip(
                          label: Text(
                            _getStepFromState((state is RequestUpdated)
                                ? state.state
                                : 'البداية'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green[900],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            body: BlocConsumer<RequestCubit, RequestState>(
              listener: (context, state) {
                if (state is RequestUpdated) {
                  _updateChat('AI', state.responseMessage ?? '');
                } else if (state is RequestError) {
                  _updateChat('AI', state.message);
                } else if (state is RequestSubmitted) {
                  _updateChat('AI', 'تم تقديم طلبك بنجاح! سنتواصل معك قريبا.');
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          final message = _chatMessages[index];
                          return MessageBubble(
                            message: message['message'] ?? '',
                            isUser: message['sender'] == 'User',
                          );
                        },
                      ),
                    ),
                    if (state is RequestListening)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'جاري الاستماع...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    if (state is RequestProcessing ||
                        state is RequestSubmitting)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textDirection: TextDirection.rtl,
                              decoration: const InputDecoration(
                                hintText: "اكتب رسالتك هنا...",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            color: Colors.green[700],
                            onPressed: () {
                              final userMessage = _controller.text;
                              if (userMessage.isNotEmpty) {
                                _updateChat('User', userMessage);
                                context
                                    .read<RequestCubit>()
                                    .sendMessage(userMessage);
                                _controller.clear();
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              context.watch<RequestCubit>().state
                                      is RequestListening
                                  ? Icons.mic_off
                                  : Icons.mic,
                              color: context.watch<RequestCubit>().state
                                      is RequestListening
                                  ? Colors.red
                                  : Colors.green[700],
                            ),
                            onPressed: () {
                              final cubit = context.read<RequestCubit>();
                              if (cubit.state is RequestListening) {
                                cubit.stopListening();
                              } else {
                                cubit.startListening();
                                _updateChat('AI', 'جاري الاستماع...');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _updateChat(String sender, String message) {
    setState(() {
      _chatMessages.add({'sender': sender, 'message': message});
    });
  }

  void _displaySummary(Request request) {
    String summary = '''
تفاصيل الطلب:
الكمية: ${request.quantity ?? 'غير محدد'}
العنوان: ${request.address ?? 'غير محدد'}
تاريخ الاستلام: ${request.collectionDate ?? 'غير محدد'}
الهدية المختارة: ${request.giftSelection ?? 'غير محدد'}
    ''';
    _updateChat('AI', summary);
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

String _getStepFromState(String state) {
  switch (state.toUpperCase()) {
    case 'AWAITING_QUANTITY':
      return 'تحديد الكمية';
    case 'AWAITING_ADDRESS':
      return 'إدخال العنوان';
    case 'AWAITING_GIFT':
      return 'اختيار الهدية';
    case 'AWAITING_CONFIRMATION':
      return 'تأكيد الطلب';
    case 'STARTED':
    default:
      return 'البداية';
  }
}
