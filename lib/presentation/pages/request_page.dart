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

  final TextEditingController _controller = TextEditingController();

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
            ),
            body: BlocConsumer<RequestCubit, RequestState>(
              listener: (context, state) {
                if (state is RequestUpdated) {
                  _updateChat('AI', state.responseMessage ?? '');
                } else if (state is RequestCompleted) {
                  _displaySummary(state.request);
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
                    if (state is RequestCompleted)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () =>
                              context.read<RequestCubit>().submitRequest(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('تأكيد الطلب'),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: "Enter your message",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              final userMessage = _controller.text;
                              if (userMessage.isNotEmpty) {
                                _updateChat('User', userMessage);
                                context
                                    .read<RequestCubit>()
                                    .sendMessge(userMessage);
                                _controller.clear();
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
الكمية: ${request.quantity}
العنوان: ${request.address}
تاريخ الاستلام: ${request.collectionDate}
الهدية المختارة: ${request.giftSelection}
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
